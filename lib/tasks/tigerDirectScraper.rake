module TigerDirectScraper
  
  def update_ca p
    matching_ro = RetailerOffering.find(:all, :conditions => \
      "product_id LIKE #{p.id} and product_type LIKE '#{$model.name}' and region LIKE 'CA'").\
    reject{ |x| !x.stock or x.priceint.nil? }
    
    return if matching_ro.empty?

    lowest = matching_ro.sort{ |x,y|
      x.priceint <=> y.priceint
    }.first

    fill_in "price_ca", lowest.priceint, p
    fill_in "price_ca_str", lowest.pricestr, p
    fill_in "instock_ca", true, p
    
  end
  
  def scrape link_list
    @logfile.puts " #{link_list.length} printers not yet scraped."
    
    link_list.each_with_index do |x,i| 
      begin
        scrape_all_from_link x
        puts "#{i+1}th printer scraped!"
      rescue Exception => e
        @logfile.puts "ERROR :#{e.type.to_s}, #{e.message.to_s}"
        puts "#{i+1}th printer had error while scraping"
      end
      sleep(15)
      puts "Waiting waiting..."
      sleep(15)
    end
  end
  
  def find_matching_tiger make, model, mpn
    matches = find_all_matching_tiger make, model, mpn
    return nil if matches.length == 0
    return matches[0]
  end
  
  def find_all_matching_tiger make, model, mpn
    makes = [just_alphanumeric (make)].delete_if{ |x| x.nil? or x == ""}
    modelnames = [just_alphanumeric (model),just_alphanumeric (mpn)].delete_if{ |x| x.nil? or x == ""}
    
    matching = []
    TigerPrinter.all.each do |ptr|
      p_makes = [just_alphanumeric (ptr.brand)].delete_if{ |x| x.nil? or x == ""}
      p_modelnames = [just_alphanumeric(ptr.model),just_alphanumeric(ptr.mpn)].delete_if{ |x| x.nil? or x == ""}

      matching << ptr unless ( (p_makes & makes).empty? or (p_modelnames & modelnames).empty? )
    end
    return matching
  end
  
  def match_tiger_to_printer tp
    makes = [just_alphanumeric (tp.brand)].delete_if{ |x| x.nil? or x == ""}
    modelnames = [just_alphanumeric (tp.model),just_alphanumeric (tp.mpn)].delete_if{ |x| x.nil? or x == ""}
    
    matching = match_rec_to_printer makes, modelnames
    @logfile.puts "ERROR! Duplicate matches for #{tp.id}: #{tp.mpn} #{tp.model} #{tp.brand}" if matching.length > 1
    
    if matching.length > 1
      matching.each do |p|
        @logfile.puts "Printer #{p.id} matches #{tp.id}: #{p.mpn} #{p.model} #{p.brand}"
      end
    end
    
    return matching
  end

  def clean_all atts
    
    atts['brand'] = atts['brand'].gsub(/\(.+\)/,'').strip
    
    # Model:
    
    if atts['model'].nil? or atts['model'] == atts['mpn']
      dirty_model_str = atts['title'].match(/.+\sprinter/i).to_s.gsub(/ - /,'')
      clean_model_str = dirty_model_str.gsub(/(mfp|multi-?funct?ion|duplex|faxcent(er|re)|workcent(re|er)|mono|laser|dig(ital)?|color|(black(\sand\s|\s?\/\s?)white)|network|all(\s?-?\s?)in(\s?-?\s?)one)\s?/i,'')
      clean_model_str.gsub!(/printer\s?/i,'')
      clean_model_str.gsub!(/#{atts['brand']}\s?/i,'')
      @brand_alternatives.each do |alts|
        if alts.include? atts['brand'].downcase
          alts.each do |altbrand|
            clean_model_str.gsub!(/#{altbrand}\s?/i,'')
          end
        end
      end
      $series.each do |ser|
        clean_model_str.gsub!(/#{ser}\s?/i,'')
      end
      clean_model_str.strip!
      atts['model'] = clean_model_str
    end
    
    atts['model'] = atts['mpn'] if atts['model'].nil? or atts['model'] ==''
    
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
    atts['priceint'] = get_price_i( get_f((atts['pricestr'] || '').gsub(/\*/,'')) )
    atts['pricestr'].strip! if atts['pricestr']
    
    # For the PRODUCT
    if atts['region'] == 'CA' then suffix = '_ca' else suffix='' end
    atts["listpricestr#{suffix}"].strip! if atts["listpricestr#{suffix}"]
    atts["listpriceint#{suffix}"] = get_price_i( get_f atts["listpriceint#{suffix}"] )
    # Fill in price, pricestr, bestoffer, instock etc later!
    
    # is it refurbished, etc
    atts['condition'] = 'New'
    atts['condition'] = "Refurbished" if ((atts['upcno']||'').match(/^RB-/) or (atts['model']||'').match(/^RB-/) or (atts['title']||'').match(/refurbished/i) )
    atts['condition'] = "OEM" if (atts['title']||'').match(/oem/i) 
    
    return atts
  end
  
  def optemo_special_url tigerurl, region
    link_prefix = "http://click.linksynergy.com/fs-bin/click?id=lI8cIt0J/v0&subid=&offerid=102327.1&type=10&tmpid=3883&RD_PARM1=" if region == 'US'
    link_prefix = "http://click.linksynergy.com/fs-bin/click?id=lI8cIt0J/v0&subid=&offerid=102328.1&type=10&tmpid=3879&RD_PARM1=" if region == 'CA'
    return (link_prefix+CGI.escape(url_by_region(region, tigerurl))) if link_prefix
    return nil
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
    ccode = 'com' 
    ccode = 'ca' if region=='CA'
    return "http://www.tigerdirect.#{ccode}#{tigerurl}"
  end
  
  def rescrape_price to
    # TODO base_url must be by country
    url = @regional_urls[to.region] + to.tigerurl
    info_page = Nokogiri::HTML(open(url))
    
    props = {}
    
    puts "Re-scraping #{ts.id}"
    props.merge! scrape_prices info_page 
    props.merge! scrape_availty info_page
    
    props.delete_if{ |x,y| !TigerScraped.column_names.include? x}
    
    fill_in_all props, to
    
    return props
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
    props.merge! scrape_availty info_page
    props.merge! scrape_modelinfo info_page
    props['region'] = @region
    
    props.delete_if{ |x,y| not TigerScraped.column_names.include? x}
    
    fill_in_all props, ts
    
    return props
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
  
  def scrape_modelinfo info_page
    returnme = {}
    
    title_el = info_page.css('td.font_size4bold h1')
    returnme['title'] = title_el.text if title_el
    
    itemno_row = info_page.xpath('//tr[td[text()="Item Number:"]]')
    itemno_el = itemno_row.xpath('td[2]')
    returnme['itemnumber'] = itemno_el.text if itemno_el
    
    return returnme
  end
  
  def scrape_availty info_page
    hsh = {}
    avail_row = info_page.xpath('//tr[td[text()="Availability:"]]')
    avail_el = avail_row.xpath('td[2]')
    hsh['availability'] = avail_el.text if avail_el
    
    itmdets = get_el info_page.css('form[name="itmdets"]')
    hsh['itmdets'] = itmdets.text if itmdets
    
    return hsh
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
  
  task :validate => :init do 
    assert_within_range TigerPrinter.all, 'listpriceint', 0, 10_000_00
    assert_within_range TigerPrinter.all, 'itemheight', 0, 100
    assert_within_range TigerPrinter.all, 'itemlength', 0, 70
    assert_within_range TigerPrinter.all, 'itemwidth', 0, 70
  end
  
  desc 'Maps the printers to db -- draft version so far'
  task :sandbox => :init do
    @logfile = File.open("./log/tiger_sandbox.log", 'w+')
    how_many_match = []
    
    TigerPrinter.all.each do |tp|
      matches = find_all_matching_tiger tp.brand, tp.model, tp.mpn
      how_many_match << matches.length
      
      if matches.length > 1
        matches.each do |p|
          @logfile.puts "Matches #{tp.id}: #{p.mpn} #{p.model} #{p.brand}"
        end
      elsif matches.length == 0
        @logfile.puts "No matches for #{tp.id}"
      end
    end
    
    puts how_many_match.uniq
    @logfile.close
  end
  
  task :fill_in_ca_price_and_stock => :init do
    fill_me_in = RetailerOffering.find_all_by_retailer_id(12) | RetailerOffering.find_all_by_retailer_id(14)
    fill_me_in.collect!{|x| Printer.find(x.product_id)}
    
    fill_me_in.each do |p|
      update_ca p
    end
    
    
  end
  
  task :update => :init do
    
    tiger_offerings = RetailerOffering.find_all_by_retailer_id(12) | RetailerOffering.find_all_by_retailer_id(14)
    
    tiger_offerings.each do |ro|
      # Update RetailerOfferings: price, availability
      rescrape_price to
      #  -- scrape website for price & availty for each offering (url?)
      #  -- clean 
      #  -- fill in price + availty
      # Update Printer: bestoffer, price, pricestr, and CA equivalents
    end
  end
    
  task :to_printer => :init do
    @logfile = File.open("./log/tiger_to_printer.log", 'w+')
    num_matching = 0
    TigerPrinter.all.each do |tp|
      matching = match_tiger_to_printer tp
      if matching.length > 0
        @logfile.puts "ERROR  #{tp.id} has multiple matching printers" if matching.length > 1
        p = matching[0]
        @logfile.puts "#{p.id} matches #{tp.id}"
        num_matching += 1
        #fill_in_all_missing tp.attributes, p
      else  
        p = nil # TODO this is temporary
        @logfile.puts "No match for #{tp.id}"
        #p = create_product_from_atts specific_o.attributes
      end
      
      toes = []
      toes = TigerOffering.find_all_by_tiger_printer_id(tp.id) unless p.nil? # TODO
      toes.each do |to|
        retailer = 12 
        retailer = 14 if to.region == 'CA'
        fill_in 'url', optemo_special_url(to.tigerurl, to.region), to
        fill_in 'retailer_id', retailer, to
        # TODO
        fill_in 'toolow', false, to
        o = create_retailer_offering to, p
      
      end
      
    end
    
    puts "#{num_matching} of #{TigerPrinter.count} match a Printer"
    
  end 
    
  desc 'Clean the data: move it from TigerScraped to TigerPrinter.'
  task :clean => :init do
    
    cleanme = TigerScraped.all
    
    cleanme.each do |ts|
      properties = {}
      ts.attributes.delete_if{|x,y| y.nil?}.each{ |k,v| properties.store( @printer_colnames[k] || k, v )  }
      
      clean_all properties
      to = TigerOffering.find_by_tigerurl_and_region(ts.tigerurl, ts.region)
      to = TigerOffering.new if to.nil?
      fill_in_all properties, to
      
      # Check for duplicates:
      tp = find_matching_tiger(properties['brand'], properties['model'], properties['mpn'])
      tp = TigerPrinter.find_or_create_by_tigerurl(ts.tigerurl) if tp.nil?
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
    
    @conditions = ["New", "Refurbished", "OEM"]
    
    @ignore_list = ['tigerurl', 'pricestr', 'price', 'region']
    
    $series = ['Jet', 'imageCLASS', 'Phaser']

    @regional_urls = { 'US' => "http://www.tigerdirect.com/", 'CA' => "http://www.tigerdirect.ca/"}

    @brand_alternatives = [ ['hp', 'hewlett packard', 'hewlett-packard'], ['konica', 'konica-minolta', 'konica minolta'], ['okidata', 'oki data', 'oki'] ]

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
      'originalprice'       =>'listpricestr'  ,      'price'               =>'pricestr'  ,      'faxcapability'       => 'fax' ,      'mfgpartno'           => 'mpn'     ,      'standardpaperoutput' =>'paperoutput'}

  end
  
end