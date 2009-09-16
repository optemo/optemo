module TigerDirectScraper
  
  # -- Link scraping stuff -- #
  def get_links_by_region region
    link_lists = get_linklist_urls region
    links = []
    link_lists.each do |ll_url|
      page = Nokogiri::HTML(open(ll_url))
      links = (scrape_links page) | links
    end
    return links
  end
  
  def get_linklist_url region, page
    base_url = get_base_url region
    return "#{base_url}/applications/category/category_slc.asp?page=#{page}&Nav=%7Cc:244%7C&Sort=0&Recs=30"
  end
  
  def get_linklist_urls region
    base_url = get_base_url region
    firstpage_url = get_linklist_url region, 1
    firstpage = Nokogiri::HTML(open(firstpage_url))
    sleep(15)
    last_pic_src = "#{base_url.sub(/tiger/, 'images.tiger').sub(/www./,'')}/search/navbar_last.gif"
    # firstpage.xpath('//a[img[@src="http://images.tigerdirect.ca/search/navbar_last.gif"]]').collect{|x| x.[]('href')}.uniq
    last_url = firstpage.xpath("//a[img[@src='#{last_pic_src}']]").collect{|x| x.[]('href')}.last
    last_num = (last_url || '').match(/\?page=\d+\&/).to_s.match(/\d+/).to_s.to_i
    urls = []
    last_num.times do |pg|
      urls << get_linklist_url( region, pg+1)
    end
    return urls
  end
  
  # -- Various (mostly URL) helper methods -- # 
  
  def get_base_url region
    retailer = $retailers.reject{|x| x.region.match(/#{region}/i).nil?}.first
    return nil if retailer.nil?
    return retailer.url
  end
  
  def get_scraped_tiger_printers
    return sp_by_retailers([12,14])
  end
  
  def record_data_from_link link, retailer
    begin
      atts = scrape_all_from_link link, retailer
    rescue Exception => e
      report_error "Problem scraping data"
      report_error "#{e.type.to_s}, #{e.message.to_s}"
    else
      clean_atts = clean_tiger(atts)
      sp = find_or_create_scraped_printer(clean_atts)
      
      ros = find_ros_from_sp sp
      ro = ros.first
      ro = create_product_from_atts clean_atts, RetailerOffering if ro.nil?
      fill_in_all clean_atts, ro
      timestamp_offering ro
      
      announce "Made RO #{ro.id} and SP #{sp.id}"
      
      report_error "Multiple ROs for SP #{sp.id}: #{ros * ', '}" if ros.count > 1
      report_error "Can't create Retailer Offering" if ro.nil?
      
      link_ro_and_sp(ro,sp) if ro
    end
  end
    
  def optemo_special_url tigerurl, region
    link_prefix = "http://click.linksynergy.com/fs-bin/click?id=lI8cIt0J/v0&subid=&offerid=102327.1&type=10&tmpid=3883&RD_PARM1=" if region == 'US'
    link_prefix = "http://click.linksynergy.com/fs-bin/click?id=lI8cIt0J/v0&subid=&offerid=102328.1&type=10&tmpid=3879&RD_PARM1=" if region == 'CA'
    return (link_prefix+CGI.escape(url_by_region(region, tigerurl))) if link_prefix
    return nil
  end
  
  def url_by_region region, tigerurl=''
     base_url = get_base_url region
     return "#{base_url}/#{tigerurl}"
  end
  
  
  # -- Accessing the data on the website -- #
  
  def scrape_last_page url
    info_page = Nokogiri::HTML(open(url))
    snore(20)
    pg_numbers = info_page.css()
    return lastpg
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

  def scrape_links doc
   link_els = doc.css('table.maintbl form[name="frmCompare"] a[title="Click for more information"]')
   links = []
   link_els.each do |link|
     links << link.attribute('href').to_s
   end
   links.uniq!
   return links
  end

  def scrape_all_from_link link, retailer    
    url = url_by_region retailer.region, link
    props = {}
    begin
      info_page = Nokogiri::HTML(open(url))
      snore(20)
      log "Scraping #{link}"
    rescue
      report_error "Couldn't open page: #{url}. Scraping failed."
    else
      props.merge! scrape_data info_page
      props.merge! scrape_prices info_page 
      props.merge! scrape_yellow_box info_page
      props.merge! scrape_availty info_page
      props.merge! scrape_modelinfo info_page
      props['region'] = retailer.region
      props['local_id']= link
      props['retailer_id'] = retailer.id
    end
    return props
  end

  # -- Cleaning data -- #
  def clean_tiger atts
    atts['display'] = (atts['specialfeatures'] || "").split(',').delete_if{|x| x.match(/display/i).nil?}.first
    atts['scanner'] = true if (atts['specialfeatures'] || "").match(/scan/i)
    atts['printserver'] = true if (atts['specialfeatures'] || "").match(/network/i)
    atts['fax'] = true if (atts['specialfeatures'] || "").match(/fax/i)
    atts['stock'] = atts['itmdets'].match(/unavail/i).nil?

    atts['condition'] = 'New'
    atts['condition'] = "Refurbished" if ((atts['upcno']||'').match(/^RB-/) or (atts['model']||'').match(/^RB-/) or (atts['title']||'').match(/refurbished/i) )
    atts['condition'] = "OEM" if (atts['title']||'').match(/oem/i) 

    atts['product_type'] = $model.name

    atts = clean_property_names atts
    clean_atts = generic_printer_cleaning_code(atts)

    
    atts['resolutionmax'] = get_max_f atts['resolution'] if atts['resolutionmax'].nil? and atts['resolution']

    temp = clean_brand(clean_atts['brand'], $printer_brands)
    clean_atts['brand'] = temp if temp
    clean_atts['model'] = clean_printer_model(clean_atts['model'], clean_atts['brand'])
    return clean_atts
  end

  # -- Matching data --#
  # TODO
  
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
    matching = match_printer_to_printer tp, $model, $printer_series
    
    if matching.length > 1
      report_error "Duplicate matches for #{tp.id}: #{tp.mpn} #{tp.model} #{tp.brand}" 
      matching.each do |p|
        log "Printer #{p.id} matches #{tp.id}: #{p.mpn} #{p.model} #{p.brand}"
      end
    end
    
    return matching
  end
 
  def rescrape_price ro
    url = url_by_region ro.region, ro.local_id
    props = {}
    
    begin
      info_page = Nokogiri::HTML(open(url))
      snore(20)
      log "Re-scraping RetailerOffering # #{ro.id}"
    rescue
      report_error "Couldn't open page: #{url}. Rescraping price failed."
    else
      props.merge! scrape_prices info_page 
      props.merge! scrape_availty info_page
    end
    return props
  end
  
  
end

namespace :scrape_tiger do
  
  desc 'Run some simple tests to check that the data isn\'t wonky'
  task :validate => :init do 
    include ValidationHelper
    
    @logfile = File.open("./log/tiger_validation.log", 'w+')
    
    scraped_tiger_printers = get_scraped_tiger_printers
    
    announce "Testing #{scraped_tiger_printers.count} ScrapedPrinters for validity..."
    
    reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
       'paperinput','scanner', 'printserver', 'brand', 'model']
    reqd_fields.each do |rf|
      assert_no_nils scraped_tiger_printers, rf
    end   
    
    assert_no_repeats scraped_tiger_printers, 'local_id'
    
    assert_within_range scraped_tiger_printers, 'itemheight', 100, 10000
    assert_within_range scraped_tiger_printers, 'itemlength', 100, 7000
    assert_within_range scraped_tiger_printers, 'itemwidth', 100, 7000
    assert_within_range scraped_tiger_printers, 'ppm', 2, 50
    assert_within_range scraped_tiger_printers, 'paperinput', 20,2000
    assert_within_range scraped_tiger_printers, 'ttp', 7,40
    assert_within_range scraped_tiger_printers, 'resolutionmax', 600, 4800
    
    tiger_offerings = RetailerOffering.find_all_by_retailer_id(12) | \
      RetailerOffering.find_all_by_retailer_id(14)
    
    announce "Testing #{tiger_offerings.count} RetailerOfferings for validity..."
    
    reqd_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
      'local_id', "product_type", "region", "retailer_id"]
    reqd_fields.each do |rf|
      assert_no_nils tiger_offerings, rf
    end
    
    assert_no_repeats tiger_offerings, 'local_id'
    assert_within_range tiger_offerings, 'priceint', 100, 10_000_00  
    
    @logfile.close
  end
    
  desc 'Update prices & availability for existing TigerPrinters'
  task :update_prices => :init do
    @logfile = File.open("./log/tiger_update.log", 'w+')
    log "Started updating at : #{Time.now}."
        
    tiger_offerings = RetailerOffering.find_all_by_retailer_id(12) | RetailerOffering.find_all_by_retailer_id(14)
    
    tiger_offerings.each do |ro|
      params = rescrape_price ro
      params = clean_tiger params
      fill_in_all params, ro
      update_offering params, ro
    end
    
    log "Updated #{tiger_offerings.count} TigerDirect printer offerings."
    log "Finished updating at : #{Time.now}"
    @logfile.close
  end
      
  desc "Acquire data for all printers"
  task :scrape => :init do
    @logfile = File.open("./log/tiger_scraper.log", 'w+')
    
    $retailers.each do |retailer|
      @region   = retailer.region
      @base_url = get_base_url @region
      # Links are the identifier for printers on the TigerDirect website.
      links = get_links_by_region @region
      log "#{links.length} #{$model.name}s to be scraped from #{retailer.name}."
      links.each_with_index do |x,i| 
        announce "Scraping #{i+1}th #{$model.name} ..."
        record_data_from_link x, retailer
        announce "#{i+1}th #{$model.name} scraped!"
      end
      log "Scraped #{links.length} #{retailer.name} #{$model.name}s."
    end
    @logfile.close
  end
  
  desc 'Initialize'
  task :init => :environment do
    require 'rubygems'
    require 'nokogiri'
    require 'helper_libs'
    require 'open-uri'
    include DataLib

    include TigerDirectScraper
    
    $model = Printer
    $scrapedmodel = ScrapedPrinter
    
    @ignore_list = ['local_id', 'pricestr', 'price', 'region']
    $retailers = [Retailer.find(12), Retailer.find(14)]
  end
end