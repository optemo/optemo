# Scrape new-egg printers

module NeweggScraper

  # Creates new offerings for the specified printer
  # and updates the bestoffer on the Printer entry.
  def create_offerings np, p
    ro_atts = RetailerOffering.column_names
    matching_no = NeweggOffering.find_all_by_printer_id(np.id)
    
    @logfile.puts "ERROR: no offerings for Newegg #{np.id}" if (matching_no.nil? or matching_no.empty?)
    
    matching_no.each do |no|
      optemo_special_url = my_special_url( id_to_url(no.item_number) )
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
    
  
  # TODO combine with scrape code?
  def cleanup_everything_for_1 np
  
  properties = {}
  offer_properties = {}
  
  np.attributes.each{ |k,v|
    properties.store( @printer_colnames[k] || k, v )  
    offer_properties.store( @offering_colnames[k] || k, v )
  }
  
  offer_properties = clean_offerprops offer_properties
  properties = cleaprinterprops properties
  
  properties = only_overlapping_atts properties, NeweggPrinter, ['item_number']
  offer_properties = only_overlapping_atts offer_properties, NeweggOffering, ['item_number']
  
  
  
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
  fill_in 'printer_id', newnp.id, offering
  
   if np.item_number == printer_item_number then retailer_id= 4 else retailer_id= 6 end
  
  fill_in 'retailer_id', retailer_id.to_s, offering
  
  fill_in_all properties, newnp
  fill_in_all offer_properties, offering
  end
  
  def clean_offerprops atts
    
    atts['priceint'] = get_price_i(atts['priceint']) if atts['priceint']
    atts['pricestr'] = get_price_s(atts['pricestr']) if atts['pricestr']
    atts['toolow'] = false if atts['toolow'].nil?
    atts['stock'] = true unless atts['priceint'].nil? or atts['stock'] == false
    return atts
  end
  
  def cleaprinterprops atts
      
  
    atts['model'] = atts['model'] || atts['series']
  
    # False by default (if nil)
    atts['colorprinter'] = (atts['colorprinter'] and atts['colorprinter'] == 'Color') 
    # Check if it has color printer properties
    colorprops = ["colorprinter", "ppmcolor", "copyspeedcolor", "copyqualitycolor",\
       "scancolordepth", "colorfax", "colorresolution"]
    colorprops.each do |x|
      atts['colorprinter'] = true unless atts[x].nil?
    end
  
  
    # False by default
    atts['scanner'] = false
    # Check if it has color printer properties
    scanprops = ["scanresolutionenhanced", "scancolordepth", \
      "scanresolutionoptical", "scanelement", "scanresolutionhardware"]
    scanprops.each do |x|
      atts['scanner'] = true unless atts[x].nil?
    end
  
  
   #   # False by default
   #   atts['fax'] = false
   #   # Check if it has color printer properties
   #   faxprops = ["faxfeatures", "faxmemory", "faxtransmissionspeed", "faxresolutions", "colorfax"]
   #   faxprops.each do |x|
   #     atts['fax'] = true unless atts[x].nil?
   #   end
  
    # Try to see if it's a network printer.
    atts['printserver'] = (atts['networkports'].nil? == false)
    
    atts['resolutionmax'] = atts['resolution'].scan(/\d+/).collect{|x| x.to_i}.sort.last if atts['resolution']
  
    # Scrapedat
    atts['scrapedat'] = atts['updated_at']
  
    # Dimensions
    if atts['dimensions']
      dims = atts['dimensions'].scan(/\d+\.?\d*/) 
      @logfile.puts "Dimensions wonky for #{atts['id']}: #{atts['dimensions']}, dims has length #{dims.length}" unless dims.length == 3
      break if dims.length < 3
      # TODO item lwh not what I thought?
      atts['itemlength'] = dims[2].to_f*100
      atts['itemwidth'] = dims[0].to_f*100
      atts['itemheight'] = dims[1].to_f*100
    end
  
    #  Warranty
    atts['warranty'] =  many_fields_to_one(['parts', 'labor'], atts, true)
    
  
    # Platform
    atts['platform'] = many_fields_to_one(['windowscompatible','macintoshcompatible','windowsvista'],atts)
  
    atts['listpriceint'] = get_price_i(atts['listpriceint']) if atts['listpriceint']
    (atts['blackprintquality'] or "").gsub!(/ dpi/,'') 
    (atts['mediasizessupported'] or "").gsub!('~','to')
    (atts['dimensions'] or "").gsub!(/''/, '\"') 
  
    return atts
  end
  
  # --- Method to scrape data for 1 printer, np. ---#
  def scrape_all_data np
      infopage = Nokogiri::HTML(open(id_to_url(np.item_number)))
      scrape_prices infopage, np
      scrape_title infopage, np
      scrape_urls infopage, np
      scrape_specs infopage, np
  end
  
  def scrape_urls infopage, np
    # ---- Manufacturer url ----#
    manuf_url = scrape_att_via_css( infopage, \
          "#pclaManufacture a[title *= 'Manufacturer Product Page']",'href' ) 
    fill_in "manufacturerproducturl", manuf_url, np
    
    #--- Image url ----#
    img_url = scrape_att_via_css(infopage,'#pclaImageArea img[src]','src')
    fill_in("imageurl", img_url, np)
  end
  
  def scrape_title infopage, np
    title_el = get_el infopage.css("#bcapcHeaderArea h1")
    title_text = title_el.text
    fill_in 'recertified', (title_text.include? 'Recertified'), np
    
    fill_in_optional "title", title_el, np
  end
  
  def scrape_prices infopage, np
  
    price_el = get_el(infopage.xpath('//div[@id="pclaPriceArea"]/dl[@class="price"]'))
    
    sale_price_el = get_el price_el.css(".final")
    fill_in_optional 'saleprice', sale_price_el, np
  
    orig_price_el = get_el price_el.css(".original")
    fill_in_optional 'listprice', orig_price_el, np
  
    # Data cleaning: if listprice not shown then it is just the saleprice
    if np.saleprice and not np.listprice
      fill_in 'listprice', np.saleprice, np
    end
    
    # -- Shipping --- #
    shipping_el = get_el price_el.css('.shipping')
    fill_in_optional 'shipping', shipping_el, np
    
    
    # --- Too low? --- #
    low_price_el = get_el price_el.css('.lowestPrice')
    
    if (low_price_el)
      sleep(30)
      lowpricepage = Nokogiri::HTML(open("http://www.newegg.com/Product/MappingPrice.aspx?Item=#{np.item_number}"))
      lowpage_lowprice_el = get_el lowpricepage.css('.final')
      fill_in_optional 'saleprice', lowpage_lowprice_el, np
      fill_in 'toolow', true ,np
    end
  
    # --- Availability --- #
    stock_el = get_el price_el.css('.stockInfo')
    fill_in_optional 'stock', stock_el, np
  end
  
  def scrape_specs infopage, np
    tablehtml = infopage.xpath("//table[@class='specification']/tr")
    spec_table = scrape_table tablehtml, 'td.name', 'td.desc'
    spec_table.each do |name, desc|
        fill_in just_alphanumeric(name), desc, np
    end
  end
  
  # TODO this doesn't do the regex thingie
  def duplicate_entries make_cols, model_cols, entry
    matching = []
    make_cols.each do |mkcol_entry|
       model_cols.each do |mdlcol_entry|
           
         make = entry.[](mkcol_entry)
         model = entry.[](mdlcol_entry)
         
         if( !make.nil? and !model.nil? and make != "" and model != "")
           make_cols.each do |mkcol|
               model_cols.each do |mdlcol|
                   matching = matching | entry.class.find(:all,:conditions => \
                       ["#{mkcol} LIKE (?) AND #{mdlcol} LIKE (?)","%#{make}%", "#{model}"])
               end
           end
         end
       end
    end
    return (matching.collect do |x| x.id end)
  end
  
  def match_newegg_to_printer np
      makes = [nofunnychars (np.brand)].delete_if{ |x| x.nil? or x == ""}
      #series = nofunnychars (np.series)
      modelnames = [nofunnychars (np.model), nofunnychars (np.series)].delete_if{ |x| x.nil? or x == ""}
      
      matching = match_rec_to_printer makes, modelnames
      @logfile.puts "ERROR! Duplicate matches for #{np.id}: #{np.model} #{np.brand}" if matching.length > 1
      
      return matching
  end
  
  
  # TODO combine with other methods, rename, and move to scraping_helper
  def nofunnychars dirty
    return nil if dirty.nil?
    clean = dirty.downcase.gsub(/\(.*\)/,'').tr('-/\\_','').gsub(/\s/,'')
    return clean
  end
  
  def id_to_url pid
    return 'http://www.newegg.com/Product/Product.aspx?Item='+ pid.to_s
  end
    
  def my_special_url url
    special_url = "http://www.jdoqocy.com/click-***REMOVED***-10446076?url="
    special_url += CGI.escape(url)
    return special_url
  end
end
namespace :scrape_newegg do
  
  desc 'Initialize'
  task :init => :environment do
    require 'rubygems'
    require 'nokogiri'

    require 'database_helper'
    include DatabaseHelper

    require 'scraping_helper'
    include ScrapingHelper

    require 'validation_helper'
    include ValidationHelper

    include NeweggScraper
    
    $model = Printer
    
    @offering_colnames  = { 'saleprice' => 'priceint',  'updated_at' =>  'priceUpdate' }

    # TODO make ignore lists and include these in the hash.
    # TODO rename the hash to something nice.
    #'sale_price'             => 'salepriceint', \ # Fill in otherwise
    # 'list_price'             => 'listpriceint', \ # fill in otherwise
    #  'brand'                  => 'manufacturer', \ # Don't fill in manufacturer
    #'outputtype'             => 'colorprinter', \
    #'duplexprinting'         => 'duplex', \    # fill in otherwise


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
    
  desc 'Everything that can be done so far'
  task :all => [:ids, :data, :clean_up, :validate]

  # TO METHOD!!
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
        x = NeweggPrinterScrapedData.find_or_initialize_by_item_number(id)
        if(x.new_record?)
          NeweggPrinterScrapedData.create(:item_number => id)
        else
          @logfile.puts "Repeated item number #{id}"
          count = count + 1
        end
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
    
    feed_url = "http://www.newegg.com/Product/RSS.aspx?Submit=ENE&N=2000330630&ShowDeactivatedMark=False"
    feed = Nokogiri::XML(open(feed_url))
    
    recent_els = feed.css("item guid")
    recent = []
    
    # Scrape all product numbers of recently added/updated printers
    recent_els.each do |el|
      product_link = el.content
      product_num = product_link.gsub(/.+?Item=/,'').gsub(/&.+/,'').strip
      # TODO get the date
      recent << product_num if product_num
      
    end
    
    # Find the printers assoc. with these product numbers
    recent_np = recent.collect do |x| NeweggPrinterScrapedData.find_by_item_number(x) end
    
    recent_np.each_with_index do |np, i|
        puts "Scraping Newegg #{np.item_number} (id #{np.id})"
        scrape_all_data np
        # TODO clean it.
        puts "Progress: done #{i} of #{recent_np.length} printers..."
        sleep(30)
    end
        
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
  
  desc 'Repeats data cleaning for a particular prnter'
  task :clean_subset => :init do
      @logfile = File.open("./log/newegg_scraper_redo_clean.log", 'w+')

      redo_these = [758].collect do |x| 
        NeweggPrinterScrapedData.find_by_id( x )
      end

      redo_these.each_with_index do |np, i|
          cleanup_everything_for_1 np
      end

      @logfile.close
  end
  
  desc 'Repeats data scraping for a particular printer'
  task :data_subset => :init do
    @logfile = File.open("./log/newegg_redo_data.log", 'w+')
    
    # 6 is deactivated
    # 226 has free shipping
    # 44 has free shipping
    # 22 has a price too low to be displayed
    # 412 is recertified
    
   # redo_list = [380, 6, 412, 44, 20, 226, 2, 446].collect do |x| 
   redo_list = [32].collect do |x|
      NeweggPrinterScrapedData.find_by_item_number(NeweggPrinter.find(x).item_number) 
    end
    
    redo_list.each_with_index do |np, i|
      scrape_all_data np
      puts "Re-scraped data for NeweggPrinter #{np.id}"
      sleep(30)
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
        cleanup_everything_for_1 np
    end
    
    @logfile.close
  end

  desc "Scrape model name from ids"
  task :data => :init do
    @logfile = File.open("./log/newegg_scraper.log", 'w+')
    
    NeweggPrinterScrapedData.all.each_with_index do |np, i|
      begin
      scrape_all_data np
      rescue Exception => e
        @logfile.puts 'ERROR: ' + e.message.to_s + e.type.to_s
        puts "Error on #{i}th printer"
        sleep(20*60) # sleep for 20 min 
      end
      puts "Progress: done #{i} of #{NeweggPrinterScrapedData.count} printers..."
      @logfile.puts "Progress: done #{i} of #{NeweggPrinterScrapedData.count} printers..."
      sleep(30)
    end
    
    @logfile.close
    
  end
  
  desc "Match printers from Newegg to existing Amazon records"
  task :map_to_db => :init do
    
    @logfile = File.open("./log/newegg_mapper.log", 'w+')
    
    NeweggPrinter.all.each do |np|
      puts "Mapping NeweggPrinter #{np.id}..." # TODO
      p = (match_newegg_to_printer np)[0] || (create_printer np)
      fill_in 'product_id', p.id, np
      fill_in 'product_type', 'Printer', np
      create_offerings np, p
    end
    
    @logfile.close   
  end
end