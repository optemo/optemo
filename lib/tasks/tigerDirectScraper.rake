module TigerDirectScraper
  
  def scrape link_list
    @logfile.puts " #{link_list.length} printers not yet scraped."
    
    link_list.each_with_index do |x,i| 
      begin
        scrape_all_from_link x
        puts "#{i+1}th printer scraped!"
      rescue Exception => e
        @logfile.puts "ERROR :#{e.type.to_s}, #{e.message.to_s}"
        puts "#{i}th printer had error while scraping"
      end
      sleep(15)
      puts "Waiting waiting..."
      sleep(15)
    end
  end
  
  def match_tiger_to_printer tp
    makes = [just_alphanumeric (tp.brand)].delete_if{ |x| x.nil? or x == ""}
    modelnames = [just_alphanumeric (tp.model),just_alphanumeric (tp.mfgpartno)].delete_if{ |x| x.nil? or x == ""}
    
    matching = match_rec_to_printer makes, modelnames
    @logfile.puts "ERROR! Duplicate matches for #{tp.id}: #{tp.mfgpartno} #{tp.model} #{tp.brand}" if matching.length > 1
    
    if matching.length > 1
      matching.each do |p|
        @logfile.puts "Matches #{tp.id}: #{p.mpn} #{p.model} #{p.brand}"
      end
    end
    
    return matching
  end

  def clean_all atts
    # Brand is clean by default
    # Model:
    atts['model'] = atts['mfgpartno'] if atts['model'].nil?
    
    # Resolutionmax
    atts['resolution'] = atts['resolution'].downcase.gsub(/dpi/,'').strip if atts['resolution']
    atts['resolutionmax'] = maxres_from_res atts['resolution']
    
    # PPM
    atts['ppm'] = atts['ppmbw'] if atts['ppm'].nil?
    atts['ppm'] = atts['ppmcolor'] if atts['ppm'].nil?
    
    # Paperinput should be clean by default
        
    # Item height, width, depth
    (atts['dimensions'] || "").split('x').each do |dim| 
      atts['itemlength'] = get_f(dim) if dim.include? 'D'
      atts['itemwidth'] = get_f(dim) if dim.include? 'W'
      atts['itemheight'] = get_f(dim) if dim.include? 'H'
    end
    
    # Scanner and printserver
    atts['scanner'] = !(atts['speciafeatures'] || "").match(/scan/i).nil?
    atts['printserver'] = !(atts['speciafeatures'] || "").match(/network/i).nil?
    # TODO also check connectivity and optionalconnectivity!
    
    
    # Optionals
    atts['display'] = (atts['speciafeatures'] || "").split(',').delete_if{|x| x.match(/display/i).nil?}.first
    
    atts['fax'] = get_b(atts['fax'])
    atts['fax'] ||= (atts['speciafeatures'] || "").match(/fax/i)
    atts['fax'] = true if atts['faxcapability'] == "Yes"
    
    # For the OFFERING
    atts['stock'] = atts['itmdets'].match(/unavail/i).nil?
    atts['priceint'] = get_price_i( get_f(atts['pricestr']) )
    atts['pricestr'].strip! if atts['pricestr']
    
    # For the PRODUCT
    if atts['region'] == 'CA' then suffix = '_ca' else suffix='' end
    atts["listpricestr#{suffix}"].strip! if atts["listpricestr#{suffix}"]
    atts["listpriceint#{suffix}"] = get_price_i( get_f atts["listpriceint#{suffix}"] )
    # Fill in price, pricestr, bestoffer, instock etc later!
    
    return atts
  end
  
  def optemo_special_url tigerurl, region
   # TODO
  end
  
  def scrape_links doc
   link_els = doc.css('table.maintbl form[name="frmCompare"] a[title="Click for more information"]')
   links = []
   link_els.each do |link|
     links << link.attribute('href').to_s
   end
   links.uniq!
   return links
  end
  
  def url_by_region region, tigerurl=''
    ccode = '.com' 
    ccode = '.ca' if region=='CA'
    return "http://www.tigerdirect.#{ccode}#{tigerurl}"
  end
  
  def scrape_all_from_link link    
    url = @base_url + link
    info_page = Nokogiri::HTML(open(url))
    
    props = {}
    ts = TigerScraped.find_or_create_by_tigerurl_and_region(link,@region)
  
    puts "Scraping #{ts.id}"
    props.merge! scrape_data info_page
    props.merge! scrape_prices info_page 
    props.merge! scrape_yellow_box info_page
    props.merge! scrape_itmdets info_page
    props.merge! scrape_availty info_page
    
    props['region'] = @region
    
    props.delete_if{ |x,y| not TigerScraped.column_names.include? x}
    
    fill_in_all props, ts
    
    return props
  end
  
  def scrape_itmdets info_page
    
    itmdets = get_el info_page.css('form[name="itmdets"]')
    return {'itmdets', itmdets.text} if itmdets
    return {}
  end
  
  def scrape_yellow_box info_page
    yellow_boxes = info_page.css('[bgcolor="#ffff99"] font')
    hsh = {}
    yellow_boxes.each do |box|  
      box.to_s.gsub(/[\t\r]+/,'').split("<br>").each do |x| 
        if x.split(/<\/?b>/).length == 2
          temparray = x.split(/<\/?b>/)
        elsif x.split(/\(/).length == 2
          temparray = x.split(/\(/)
        end
        if temparray
          key = just_alphanumeric( temparray[0].gsub(/<.*>/,'') )
          val = temparray[1].gsub(/<.*>/,'').gsub(/\n/,'').strip
          hsh.merge!( key => val )
        end
      end
    end
    return hsh
  end
  
  def scrape_availty info_page
    avail_row = info_page.xpath('//tr[td[text()="Availability:"]]')
    avail_el = avail_row.xpath('td[2]')
    return {'availability' => avail_el.text} if avail_el
    return {}
  end
  
  def scrape_prices info_page
    prices_table = info_page.css('table#myPrice tr')
    prices = scrape_table prices_table, "td", "td"
    return prices
  end
  
  def scrape_data info_page
    puts "#{info_page.css('table.viss').length} tables found "
    spec_table = info_page.css('table.viss tr')
    specs = scrape_table spec_table, 'td.techspec', 'td.techvalue'
    return specs
  end

end

namespace :scrape_tiger do
  
  desc 'everything in a sequence'
  task :all => [:scrape, :clean]
  
  desc 'Maps the printers to db -- draft version so far'
  task :map_to_db => :init do
    @logfile = File.open("./log/tiger_sandbox.log", 'w+')
    how_many_match = []
    
    TigerPrinter.all.each do |tp|
      matches = match_tiger_to_printer tp
      how_many_match << matches.length
    end
    
    puts how_many_match * ', '
    @logfile.close
  end
  
  task :update => :init do
    
    tiger_offerings = RetailerOffering.find_all_by_retailer_id(12) | RetailerOffering.find_all_by_retailer_id(14)
    
    tiger_offerings.each do |ro|
      # Update RetailerOfferings: price, availability
      #  -- scrape website for price & availty for each offering (url?)
      #  -- clean 
      #  -- fill in price + availty
      # Update Printer: bestoffer, price, pricestr, and CA equivalents
    end
  end
    
  task :toprinter => :init do
    # TODO
    
    TigerPrinter.all.each do |tp|
      matching = match_tiger_to_printer tp
      if matching.length == 1
        p = matching[0]
        puts "#{p.id} matches #{tp.id}"
        # fill_in_all_missing tp.attributes, p
      elsif matching.length > 1 
        # TODO ERROR!! should not happen
        puts "Uh oh"
      else
        #New printer
        p = nil
        puts "No match for #{tp.id}"
        # fill in all specs
      end
      
      toes = []
      toes = TigerOffering.find_all_by_tiger_printer_id(tp.id) unless p.nil?
      #toes.each do |to|
      #  retailer = 12 
      #  retailer = 14 if to.region == 'ca'
      #  #RetailerOffering.find_or_create_by_productid_and_retailer
      #  # 2. Create offerings
      #    fill_in 'url', optemo_special_url(to.tigerurl, to.region), to
      #    fill_in 'product_id', p.id, to
      #    fill_in 'product_type', $model.to_s, to
      #    if no.offering_id.nil? # If no RetailerOffering is mapped to this NeweggOffering:
      #      copy_atts = only_overlapping_atts no.attributes, RetailerOffering
      #      o = RetailerOffering.new(copy_atts)
      #      o.save
      #      fill_in 'offering_id', o.id, no
      #    end
        #  -- Link them to the printer entry
        #  -- fill in product type (Printer)
        # 3. Update bestoffer and bestoffer_ca
        # TODO move existing code to helper
      #end
    end
    
    
  end 
    
  desc 'Clean the data: move it from TigerScraped to TigerPrinter.'
  task :clean => :init do
    
    cleanme = TigerScraped.find_all_by_region('CA')
    
    cleanme.each do |ts|
      properties = {}
      ts.attributes.delete_if{|x,y| y.nil?}.each{ |k,v| properties.store( @printer_colnames[k] || k, v )  }
      
      clean_all properties
      to = TigerOffering.find_by_tigerurl_and_region(ts.tigerurl, ts.region)
      to = TigerOffering.new if to.nil?
      fill_in_all properties, to
      
      # TODO Check for duplicates?
      tp = TigerPrinter.find_or_create_by_tigerurl(ts.tigerurl)
      fill_in_all properties, tp, @ignore_list
      fill_in 'tiger_printer_id', tp.id, to
      
      puts "Cleaned #{ts.id}th scraped data, put it into #{tp.id}th printer."
    end
  end
    
    
  desc "Acquire data for all printers"
  task :scrape => :init do
    
    @logfile = File.open("./log/tiger_scraper.log", 'w+')
    
    @region   = 'US'
    @base_url = "http://www.tigerdirect.com/"
    us_links = []
    
    # Scrape US site
    4.times do |page_num| 
      page = Nokogiri::HTML(open("scrape_me/tiger/tiger_printers_#{page_num+1}_of_4.html"))
      us_links = (scrape_links page) | us_links
    end
    
    scrape us_links
    
    @region   = 'CA'
    @base_url = "http://www.tigerdirect.ca/"
    ca_links = []
    
    # Scrape Canadian site
    6.times do |page_num| 
      page =  Nokogiri::HTML(open("scrape_me/tiger/canada_#{page_num+1}.html"))
      ca_links = (scrape_links page) | ca_links
    end
    
    scrape ca_links
    
    @logfile.puts "Scraped #{us_links.length} US printers and #{ca_links.length} CA printers."
    @logfile.close
  end
  
  desc 'Initialize'
  task :init => :environment do
    require 'rubygems'
    require 'nokogiri'

    require 'scraping_helper'
    include ScrapingHelper

    require 'database_helper'
    include DatabaseHelper
    
    require 'validation_helper'
    include ValidationHelper

    include TigerDirectScraper
    
    $model = Printer
    
    @ignore_list = ['tigerurl', 'pricestr', 'price', 'region']

    @printer_colnames = { \
      'dimensions'          =>'dimensions'  ,\
      'duplexprinting'      => 'duplex'     ,\
      'firstpageoutputtime' => 'ttp'        ,\
      'maximumdutycycle'    => 'dutycycle'  ,\
      'papersizessupported' => 'papersize'  ,\
      'printspeed'          =>'ppm'         ,\
      'printspeedbw'        => 'ppmbw'      ,\
      'printspeedcolor'     => 'ppmcolor'   , \
      'standardpaperinput'  =>'paperinput'  ,\
      'manufacturedby'      => 'brand'      ,\
      'shippingweight'      => 'packageweight', \
      'originalprice'       =>'listpricestr'  ,      'price'               =>'pricestr'  ,      'faxcapability'       => 'fax' ,      'mfgpartno'           => 'model'     ,      'standardpaperoutput' =>'paperoutput'}

  end
  
end