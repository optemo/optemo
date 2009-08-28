# Scrape new-egg printers
# Abbreviations frequently used in var names: 
# ro : retailer offering
# no : newegg offering
# np : newegg printer
# npsd: newegg printer scraped data
# p  : printer
# o  : offering
module NeweggScraper

  def get_recent_els_from_feed feed_url
    feed = Nokogiri::XML(open(feed_url))
    
    recent_els = feed.css("item guid")
    recent = []
    
    # Scrape all product numbers of recently added/updated printers
    recent_els.each do |el|
      product_link = el.content
      product_num = product_link.gsub(/.+?Item=/,'').gsub(/&.+/,'').strip
      # TODO get the date (not too important)
      recent << product_num if product_num
    end
    return recent
  end

  # --- Database insertion/matching --- #
  def new_rec_by_itemnum id, logfile
    x = NeweggPrinterScrapedData.find_or_initialize_by_item_number(id)
    if(x.new_record?)
      NeweggPrinterScrapedData.create(:item_number => id)
    else
      logfile.puts "Item number #{id} was already in the db"
    end
    return x
  end

  def map_to_db np
    puts "Mapping NeweggPrinter #{np.id}..." # TODO
    p = (match_newegg_to_printer np)[0] || (create_product_from_rec np)
    fill_in 'product_id', p.id, np
    fill_in 'product_type', 'Printer', np
    create_offerings np, p
    return p
  end

  def create_offerings np, p
    ro_atts = RetailerOffering.column_names
    matching_no = NeweggOffering.find_all_by_printer_id(np.id)
    
    @logfile.puts "ERROR: no offerings for Newegg #{np.id}" if (matching_no.nil? or matching_no.empty?)
    
    matching_no.each do |no|
      optemo_special_url = my_special_url(no.item_number)
      fill_in 'url', optemo_special_url, no
      fill_in 'product_id', p.id, no
      fill_in 'product_type', 'Printer', no
      if no.offering_id.nil? # If no RetailerOffering is mapped to this NeweggOffering:
        copy_atts = only_overlapping_atts no.attributes, RetailerOffering
        o = RetailerOffering.new(copy_atts)
        o.save
        fill_in 'offering_id', o.id, no
      end
    end
    update_bestoffer p
  end

  def no_and_np_from_atts atts, itemnum
    dirtyprops = {}
    atts.each{|k,v| dirtyprops.store( @printer_colnames[k] || k, v.to_s )  unless v.nil? }
    properties = clean_all dirtyprops
    
    printer_item_number = itemnum.gsub(/R$/,'')
    # Make offering & printer objects   
    if atts['recertified']
      non_recertified = NeweggPrinter.find(:all,:conditions => \
          ["brand LIKE (?) AND model LIKE (?)","%#{atts['brand']}%", "#{atts['model']}"])
      non_recertified.delete_if { |x| x.recertified } 
      printer_item_number = non_recertified[0].item_number unless non_recertified.empty?
    end
    
    offering = NeweggOffering.find_or_create_by_item_number(itemnum)
    newnp = NeweggPrinter.find_or_create_by_item_number(printer_item_number)
    fill_in 'printer_id', newnp.id, offering
    
    if itemnum == printer_item_number then retailer_id= 4 else retailer_id= 6 end
    
    fill_in 'retailer_id', retailer_id.to_s, offering
    
    fill_in_all properties, newnp, ['item_number', 'product_id']
    fill_in_all properties, offering, ['item_number', 'product_id']
    return newnp
  end

  def no_and_np_from_npsd np
    dirtyprops = {}
    np.attributes.each{|k,v| dirtyprops.store( @printer_colnames[k] || k, v.to_s )  unless v.nil? }
    properties = clean_all dirtyprops
    printer_item_number = np.item_number.gsub(/R$/,'')
    # Make offering & printer objects   
    if np.recertified 
      non_recertified = NeweggPrinterScrapedData.find(:all,:conditions => \
          ["brand LIKE (?) AND model LIKE (?)","%#{np.brand}%", "#{np.model || np.series}"])
      non_recertified.delete_if { |x| x.recertified } 
      printer_item_number = non_recertified[0].item_number unless non_recertified.empty?
    end
    
    offering = NeweggOffering.find_or_create_by_item_number(np.item_number)
    newnp = NeweggPrinter.find_or_create_by_item_number(printer_item_number)
    fill_in_all properties, newnp, ['item_number', 'product_id']
    fill_in_all properties, offering, ['item_number', 'product_id']
    
    fill_in 'printer_id', newnp.id, offering
    
    if np.item_number == printer_item_number then retailer_id= 4 else retailer_id= 6 end
    fill_in 'retailer_id', retailer_id.to_s, offering
    
    return newnp
  end
  
  def clean_all atts
    atts['mpn'] = atts['series']
    atts['resolution'] = (atts['blackprintquality'] || '') + (atts['colorprintquality'] || '')
     #Booleans
    atts['colorprinter'] = (atts['colorprinter'] and atts['colorprinter'] == 'Color') 
    colorprops = ["colorprinter", "ppmcolor", "copyspeedcolor", "copyqualitycolor",\
       "scancolordepth", "colorfax", "colorresolution"]
    atts = infer_boolean('colorprinter', colorprops, atts)
  
    scanprops = ["scanresolutionenhanced", "scancolordepth", \
      "scanresolutionoptical", "scanelement", "scanresolutionhardware"]
    atts = infer_boolean('scanner',scanprops,atts,false)
  
    faxprops = ["faxfeatures", "faxmemory", "faxtransmissionspeed", "faxresolutions", "colorfax"]
    atts = infer_boolean('fax',faxprops,atts)
  
    atts['printserver'] = (atts['networkports'].nil? == false)
    
    atts['scrapedat'] = atts['updated_at']
  
    #  Warranty
    atts['warranty'] =  many_fields_to_one(['parts', 'labor'], atts, true)  
  
    # Platform
    atts['platform'] = many_fields_to_one(['windowscompatible','macintoshcompatible','windowsvista'],atts)
  
    (atts['blackprintquality'] or "").gsub!(/ dpi/,'') 
    (atts['mediasizessupported'] or "").gsub!('~','to')
    
    
    cleanatts = generic_printer_cleaning_code atts
    
    # For the offering
    cleanatts['toolow'] = false if cleanatts['toolow'].nil?
    cleanatts['stock'] = true unless cleanatts['priceint'].nil? or cleanatts['stock'] == false
    
    return cleanatts
  end
  
  # --- Scraping ---#
  def scrape_all npid
      infopage = Nokogiri::HTML(open(id_to_details_url(npid)))
      sleep(15)
      atts = scrape_prices infopage, npid
      atts.merge!(scrape_title infopage)
      atts.merge!(scrape_urls infopage)
      atts.merge!(scrape_specs infopage)
      return atts
  end
  
  def scrape_urls infopage
    retme = {}
    manuf_url = scrape_att_via_css( infopage, \
          "#pclaManufacture a[title *= 'Manufacturer Product Page']",'href' ) 
    retme["manufacturerproducturl"] = manuf_url
    img_url = scrape_att_via_css(infopage,'#pclaImageArea img[src]','src')
    retme["imageurl"] = img_url
    return retme
  end
  
  def scrape_title infopage
    retme = {}
    title_el = get_el infopage.css("#bcapcHeaderArea h1")
    title_text = title_el.text if title_el
    if title_text
      retme['recertified'] = (title_text.include? 'Recertified')
      retme["title"] = title_text
    end
    return retme
  end
  
  def scrape_prices infopage, item_number
    retme = {}
  
    price_el = get_el(infopage.xpath('//div[@id="pclaPriceArea"]/dl[@class="price"]'))
    sale_price_el = get_el price_el.css(".final")
    retme['saleprice'] = sale_price_el.text if sale_price_el
    orig_price_el = get_el price_el.css(".original")
    retme['listprice'] = orig_price_el.text if orig_price_el
  
    # -- Shipping --- #
    shipping_el = get_el price_el.css('.shipping')
    retme['shipping']  = shipping_el.text if shipping_el
    
    # --- Too low? --- #
    low_price_el = get_el price_el.css('.lowestPrice')
    
    if (low_price_el)
      sleep(30)
      lowpricepage = Nokogiri::HTML(open("http://www.newegg.com/Product/MappingPrice.aspx?Item=#{item_number}"))
      lowpage_lowprice_el = get_el lowpricepage.css('.final')
      retme['saleprice'] = lowpage_lowprice_el.text if lowpage_lowprice_el
      retme['toolow'] = true
    else
      retme['toolow'] = false
    end
  
    # --- Availability --- #
    stock_el = get_el price_el.css('.stockInfo')
    retme['stock'] = stock_el.text if stock_el
    
    return retme
  end
  
  def scrape_specs infopage
    tablehtml = infopage.xpath("//table[@class='specification']/tr")
    spec_table = scrape_table tablehtml, 'td.name', 'td.desc'
    return spec_table
  end
  
  def match_newegg_to_printer np
      matching = match_printer_to_printer np, Printer
      @logfile.puts "ERROR! Duplicate matches for #{np.id}: #{np.model} #{np.brand}" if matching.length > 1
      return matching
  end
  
  # --- URL generation --- #
  def id_to_details_url pid
    return 'http://www.newegg.com/Product/Product.aspx?Item='+ pid.to_s
  end
    
  def my_special_url itemnum
    url = id_to_details_url itemnum
    special_url = "http://www.jdoqocy.com/click-***REMOVED***-10446076?url="
    special_url += CGI.escape(url)
    return special_url
  end
end
namespace :scrape_newegg do
  
  desc 'Everything that can be done so far'
  task :all => [:ids, :data, :clean, :validate]

  desc 'Initialize'
  task :init => :environment do
    require 'rubygems'
    require 'nokogiri'

    require 'helper_libs'
    include DataLib
    
    require 'open-uri'

    include NeweggScraper
    
    $model = Printer
    
    @offering_colnames  = { 'saleprice' => 'priceint',  'updated_at' =>  'priceUpdate' }

                               # NeweggPrinter column names  =>    Printer column names
    @printer_colnames         = { 'connectivitytechnology' => 'connectivity', \
                                  'blackprintspeed'        => 'ppm', \
                                  'timetofirstpageseconds' => 'ttp', \
                                  'inputcapacitystd'       => 'paperinput', \
                                  'outputcapacitystd'      => 'paperoutput', \
                                  'maxdutycycle'           => 'dutycycle', \
                                  'inputcapacitystd'       => 'paperinput', \
                                  'outputcapacitystd'      => 'paperoutput', \
                                  'blackprintquality'      => 'resolution', \
                                  'printlanguagesstd'      => 'language', \
                                  'microprocessortype'     => 'cputype', \
                                  'processormhz'           => 'cpuspeed', \
                                  'other'                  => 'special', \
                                  'memorystd'             => 'systemmemory', \
                                  'mediasizessupported'   => 'papersize',\
                                  'memorymax' => 'systemmemorymax',\
                                  'inputcapacitymax' => 'paperinputmax',\
                                  'outputcapacitymax'=> 'paperoutputmax' }
    
  end
    
  desc "Get all IDs from Newegg." 
  task :ids => :init do
    @logfile = File.open("./log/newegg_scrape_ids.log", 'w+')
    pages = []
    
    3.times do |page_num| 
      pages << Nokogiri::HTML(open("scrape_me/newegg/newegg_products_page#{page_num+1}of3.html"))
    end
    
    count = 0
    
    pages.each_with_index do |doc, i|
      resultset = doc.xpath('//div[@id="bcaBreadcrumbTop"]/dl/dd').last.content.to_s
      @logfile.puts "Scraping Page \##{i+1}: #{resultset}" 
      
      printer_id_els = doc.xpath('//td[@class="midCol"]/h3/a/@href')
      
      printer_id_els.each_with_index do |el, i|
        id = ''
        id = el.to_s.gsub('http://www.newegg.com/Product/Product.aspx?Item='){''}
        @logfile.puts "blank at #{i}" if (id == '')
        x = new_rec_by_itemnum(id,@logfile)
      end
    end  
    puts "We now have #{NeweggPrinterScrapedData.count} newegg printer ids." \
         +" #{count} of the scraped ids were repeats." \
         + "Log file at #{@logfile.path}"
     
    @logfile.close
  end
 
  desc "Get the latest updates to the Newegg list"
  task :update => :init do 
    @logfile = File.open("./log/newegg_update.log", 'w+')
    totally_new = 0 
    feed_url = "http://www.newegg.com/Product/RSS.aspx?Submit=ENE&N=2000330630&ShowDeactivatedMark=True"
    recent = get_recent_els_from_feed feed_url
    
    recent.each do |inum|
     
      no = NeweggOffering.find_by_item_number(inum)
      begin
        np = NeweggPrinter.find(no.printer_id) if no and no.printer_id
        p = Printer.find(no.product_id) if no and no.product_id
      rescue
        # do nothing
      end
            
      if p.nil? # New printers only: scrape & clean specs
        totally_new += 1
        atts = scrape_all inum
        np = no_and_np_from_atts atts, inum
        p = map_to_db np
        no = NeweggOffering.find_by_item_number(inum) if no.nil? 
      end
      
      o = RetailerOffering.find(no.offering_id) if no and no.offering_id
      debugger if o.nil?
      
      # Update prices
      begin  
        infopage = Nokogiri::HTML(open(id_to_details_url(inum)))
        sleep(15)
      rescue
        puts "Cant scrape #{inum}: #{id_to_details_url(inum)} doesnt' open"
      else
        params = scrape_prices infopage, inum
        params = clean_prices params
        update_offering params, o
        puts " Re-scraped prices for #{inum} ."
      end
      update_bestoffer p
    end
    puts "#{recent.count} in total"
    puts "#{totally_new} completely new"
    @logfile.close
  end
  
  desc 'Check for no unhealthy duplicates'
  task :validate => :init do
    @logfile = File.open("./log/newegg_validation.log", 'w+')
    
    # 1. NeweggPrinters has no null models or brands
    @logfile.puts "Checking Newegg for null model and/or brand"
    nil_brands = NeweggPrinter.find_all_by_brand(nil)
    nil_models = NeweggPrinter.find_all_by_model(nil)
    
    @logfile.puts "NeweggPrinter has #{nil_brands.length} entries with a nil brand: #{nil_brands.collect{|x|x.id.to_s + ', '}}."
    @logfile.puts "NeweggPrinter has #{nil_models.length} entries with a nil model: #{nil_models.collect{|x|x.id.to_s + ', '}}."
    
    # 2. NeweggPrinters has no duplicates
    @logfile.puts "Checking Newegg for duplicates"
    
    np_make_cols = ['brand']
    np_model_cols = ['model']
    NeweggPrinter.all.each do |np|
      dupl = duplicate_entries np_make_cols, np_model_cols, np
      puts "#{dupl.length} duplicates for #{np.id}: ids #{dupl * ', '}"  if dupl.length > 1 
    end
    # 3. Printers has no duplicates
    @logfile.puts "Checking Printers for duplicates"
    
    p_make_cols = ['brand']
    p_model_cols = ['model', 'mpn']
    counter = 0
    Printer.all.each do |p|
      dupl = duplicate_entries p_make_cols, p_model_cols, p
      puts "#{dupl.length-1} duplicates for #{p.id}: ids #{dupl * ', '}"  if dupl.length > 1 
      counter += 1 if dupl.length > 1 
    end
    
    
    # 4. No double matches for NeweggPrinter <--> Printer
    # and at least 1 match
    
    @logfile.puts "Checking for no double matches"
    double_match = false
    normal_match = false
    NeweggPrinter.all.each do |np|
    
      ap_list = match_newegg_to_printer np
      
      if ap_list.length > 1
        double_match = true
        ids = []
        ap_list.each do |found_ap| ids << found_ap.id end
        @logfile.puts "#{ap_list.length} matches (#{ids * ','}) for Newegg #{np.id} (#{np.model} #{np.brand})"
      elsif ap_list.length == 1
        normal_match = true
      end

      
    end
    puts "Some double matches exist for NeweggPrinter <--> Printer. See log." if double_match
    puts "No 1-to-1 matches exist for NeweggPrinter <--> Printer. See log." unless normal_match
    
    # 5. Some more checks    
    assert_no_repeats NeweggOffering.all, 'printer_id'
    assert_no_repeats NeweggOffering.all, 'item_number'
    assert_no_repeats NeweggPrinter.all, 'item_number'
    
    assert_no_nils_or_0s_in_att NeweggPrinter.all, 'listpriceint'
    assert_no_nils_or_0s_in_att Printer.all, 'listpriceint'
    assert_no_nils_or_0s_in_att NeweggOffering.all, 'priceint'
    assert_no_nils_or_0s_in_att NeweggPrinterScrapedData.all, 'listprice'
    assert_no_nils_or_0s_in_att NeweggPrinterScrapedData.all, 'saleprice'
    
    
    ['ppm', 'itemwidth', 'paperinput', 'resolutionmax', 'listpriceint', 'scanner', 'printserver'].each do |field| 
      assert_no_nils NeweggPrinter.all.delete_if{|x| x.listpriceint.nil?}, field
    end
    
    @logfile.close
    
  end
  
  desc 'Remove duplicates from Printers. Currently for Amazon printers only.'
  task :del_duplicates => :init do
    
    # Find all sets of IDs which describe the same printer
    all_dupl = []
    p_make_cols = ['brand']
    p_model_cols = ['model', 'mpn']
    counter = 0
    Printer.all.each do |p|
      dupl = duplicate_entries p_make_cols, p_model_cols, p
      if dupl.length > 1
        #puts "#{dupl.length} duplicates for #{p.id}: ids #{dupl * ', '}"   
        all_dupl << dupl.sort unless all_dupl.include? dupl.sort
        #counter += 1
      end
    end
    
    # Deal with duplicates
    all_dupl.each do |set|
      smallest = set[0]
      set.each do |x|
         # Find Amazon printer linked to duplicate
         ap = AmazonPrinter.find_by_product_id x
         if( !ap)
           puts "WARNING AmazonPrinter #{x} doesn't exist"
         elsif ( ap.product_id != smallest)
           # Re-link Amazon printer
           puts "will Change #{ap.id}'s product id from #{ap.product_id} to #{smallest}"
           ap.update_attribute('product_id', smallest)
           # Delete duplicate Printer
           puts "will Delete printer with id = #{x}."
           Printer.find(x).delete
         end
      end
      
    end
    
    puts "Num sets: #{all_dupl.length}. Num messages: #{counter}"
    
  end
   
  desc 'Find duplicates'
  task :duplicates => :init do
    
    puts "Checking NEWEGGPRINTERS for duplicates"
    
    np_make_cols = ['brand']
    np_model_cols = ['model']
    
    NeweggPrinter.all.each do |np|
      dupl = duplicate_entries np_make_cols, np_model_cols, np
      puts "#{dupl.length} duplicates for #{np.id}: ids #{dupl * ', '}"  if dupl.length > 1 
    end
    
    puts "Checking PRINTERS for duplicates"
    
    p_make_cols = ['brand']
    p_model_cols = ['model', 'mpn']
    counter = 0
    Printer.all.each do |p|
      dupl = duplicate_entries p_make_cols, p_model_cols, p
      puts "#{dupl.length-1} duplicates for #{p.id}: ids #{dupl * ', '}"  if dupl.length > 1 
      counter += 1 if dupl.length > 1 
    end
    
    puts "#{counter} duplicates detected.. may contain repeats"
  end
  
  desc "Clean up Newegg data and move it to different tables"
  task :clean => :init do
    @logfile = File.open("./log/newegg_scraper_cleanup.log", 'w+')
    
    NeweggPrinterScrapedData.all.each_with_index do |np, i|
        newnp = no_and_np_from_npsd np
        map_to_db newnp
    end
    
    @logfile.close
  end

  desc "Scrape model name from ids"
  task :data => :init do
    @logfile = File.open("./log/newegg_scraper.log", 'w+')
    
    NeweggPrinterScrapedData.all.each_with_index do |np, i|
      begin
        atts = scrape_all np.item_number
        fill_in_all atts, np, ['product_id']
      rescue Exception => e
        @logfile.puts 'ERROR: ' + e.message.to_s + e.type.to_s
        puts "Error on #{i}th printer"
        sleep(20*60) # sleep for 20 min 
      end
      puts "Progress: done #{i} of #{NeweggPrinterScrapedData.count} printers..."
      @logfile.puts "Progress: done #{i} of #{NeweggPrinterScrapedData.count} printers..."
    end
    
    @logfile.close
  end
  
end