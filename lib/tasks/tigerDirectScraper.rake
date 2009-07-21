module TigerDirectScraper
  
  def scrape all_links
    @logfile.puts " #{all_links.length} printers not yet scraped."
    
    all_links.each_with_index do |x,i| 
      begin
        scrape_all_from_link x 
        puts "#{i+1}th printer scraped!"
      rescue Exception => e
        @logfile.puts "ERROR :#{e.type.to_s}, #{e.message.to_s}"
        puts "#{i}th printer had error while scraping"
      end
      sleep(10)
      puts "Waiting waiting..."
      sleep(100)
    end
  end
  
  def match_tiger_to_printer tp
    makes = [nofunnychars (tp.brand)].delete_if{ |x| x.nil? or x == ""}
    modelnames = [nofunnychars (tp.model), nofunnychars (tp.mfgpartno)].delete_if{ |x| x.nil? or x == ""}
    
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
    atts['resolution'] = atts['resolution'].downcase.gsub(/dpi/,'').strip if atts['resolution']
    
    atts['fax'] = get_b(atts['fax'])
    atts['fax'] ||= (atts['speciafeatures'] || "").match(/fax/i)
    atts['fax'] = true if atts['faxcapability'] == "Yes"
    
    atts['scanner'] = !(atts['speciafeatures'] || "").match(/scan/i).nil?
    
    # TODO also check connectivity and optionalconnectivity!
    atts['printserver'] = !(atts['speciafeatures'] || "").match(/network/i).nil?
    
    atts['display'] = (atts['speciafeatures'] || "").split(',').delete_if{|x| x.match(/display/i).nil?}.first
    
    # PRICES
    atts['pricestr'].strip! if atts['pricestr']
    atts['listpricestr'].strip! if atts['listpricestr']
    atts['price'] = get_price_i( get_f(atts['pricestr']) )
    atts['listpriceint'] = get_price_i( get_f atts['listpricestr'] )
    
    atts['model'] = atts['mfgpartno'] if atts['model'].nil?
    
    atts['ppm'] = atts['ppmbw'] if atts['ppm'].nil?
    atts['ppm'] = atts['ppmcolor'] if atts['ppm'].nil?
    
    (atts['dimensions'] || "").split('x').each do |dim| 
      atts['itemlength'] = get_f(dim) if dim.include? 'D'
      atts['itemwidth'] = get_f(dim) if dim.include? 'W'
      atts['itemheight'] = get_f(dim) if dim.include? 'H'
    end
    
    atts['resolutionmax'] = maxres_from_res atts['resolution']
    atts['instock'] = atts['itmdets'].match(/unavail/i).nil?
    atts['availability'] = "No" if atts['instock'] == false
    
    return atts
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
  
  def scrape_all_links 
    pages = []
    
    4.times do |page_num| 
      pages << Nokogiri::HTML(open("scrape_me/tiger/tiger_printers_#{page_num+1}_of_4.html"))
    end
    
    count = 0
  
    all_links = []
    
    pages.each_with_index do |doc, i|
      all_links = (scrape_links doc) | all_links
    end  
    
    puts "Found #{all_links.length} links altogether"
    return all_links
  end
  
  def scrape_all_from_link link    
    url = @base_url + link
    info_page = Nokogiri::HTML(open(url))
    
    props = {}
    ts = TigerScraped.find_or_create_by_tigerurl(link)
  
    puts "Scraping #{ts.id}"
    props.merge! scrape_data info_page
    props.merge! scrape_prices info_page 
    props.merge! scrape_yellow_box info_page
    props.merge! scrape_itmdets info_page
    props.merge! scrape_availty info_page
    
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
  task :all => [:scrape, :clean, :validate]
  
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
    
  desc 'Clean the data: move it from TigerScraped to TigerPrinter.'
  task :clean => :init do
    TigerScraped.all.each do |ts|
      properties = {}
      ts.attributes.delete_if{|x,y| y.nil?}.each{ |k,v| properties.store( @printer_colnames[k] || k, v )  }
      
      clean_all properties
      properties = only_overlapping_atts properties, TigerPrinter, @ignore_list
      
      tp = TigerPrinter.find_or_create_by_tigerurl(ts.tigerurl)
       # TODO should I be deleting tigerurl from props?
      fill_in_all properties, tp
      
      puts "Cleaned #{ts.id}th scraped data, put it into #{tp.id}th printer."
    end
  end
    
  desc 'scrape data for a subset'
  task :scrape_subset => :init do
    @logfile = File.open("./log/tiger_scrape_subset.log", 'w+')
   
    all_links = ['/applications/SearchTools/item-details.asp?EdpNo=4375998&CatId=244']
   
      # Do only the ones that I haven't scraped yet.
      # all_links.delete_if { |x| TigerScraped.exists?(:tigerurl => x) }
   
      @logfile.puts " #{all_links.length} printers not yet scraped."
   
      all_links.each_with_index do |x,i| 
        begin
          scrape_all_from_link x 
          puts "#{i+1}th printer scraped!"
        rescue Exception => e
          @logfile.puts "ERROR :#{e.type.to_s}, #{e.message.to_s}"
          puts "#{i}th printer had error while scraping"
        end
        sleep(10)
        puts "Waiting waiting..."
        sleep(100)
      end
    @logfile.close
   
  end  
    
  desc "Acquire data for all printers"
  task :scrape => :init do
    
    @logfile = File.open("./log/tiger_scraper.log", 'w+')
    
    all_links = scrape_all_links
    
    # Do only the ones that I haven't scraped yet.
    # all_links.delete_if { |x| TigerScraped.exists?(:tigerurl => x) }
    
    scrape all_links
    
    @logfile.close
  end
  
  desc "Blah"
  task :update => :init do
  end
  
  desc "Check for wonky data"
  task :validate => :init do
    assert_no_nils TigerPrinter.all, 'tigerurl'
    assert_no_0_values TigerPrinter.all, 'listprice'
    assert_no_0_values TigerPrinter.all, 'itemheight'
    assert_no_0_values TigerPrinter.all, 'itemwidth'
    assert_no_0_values TigerPrinter.all, 'itemweight'
    assert_no_0_values TigerPrinter.all, 'ppm'
    assert_no_0_values TigerPrinter.all, 'ttp'
    # TODO more
  end
  
  
  desc 'Initialize'
  task :init => :environment do
    require 'rubygems'
    require 'nokogiri'

    require 'scraping_helper'
    include ScrapingHelper

    require 'validation_helper'
    include ValidationHelper

    include TigerDirectScraper
    
    $model = Printer
    
    @base_url = "http://www.tigerdirect.com/"
    @ignore_list = ['tigerurl']

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
      'shippingweight'      => 'packageweight',  'originalprice'=>'listpricestr'  ,'price'=>'pricestr'  ,  'faxcapability'       => 'fax'       ,'mfgpartno'           => 'model'     ,  'standardpaperoutput' =>'paperoutput'}


  end
  
end