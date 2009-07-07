# Scrape new-egg printers
namespace :scrape_newegg do
  require 'rubygems'
  require 'nokogiri'

  desc "Get all IDs from Newegg." 
  task :ids => :environment do
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
  task :update => :environment do 
    
    feed_url = "http://www.newegg.com/Product/RSS.aspx?Submit=ENE&N=2000330630&ShowDeactivatedMark=False"
    feed = Nokogiri::XML(open(feed_url))
    
    recent_els = feed.css("item guid")
    recent = []
    
    recent_els.each do |el|
      product_link = el.content
      product_num = product_link.gsub(/.+?Item=/,'').gsub(/&.+/,'').strip
      
      recent << product_num if product_num
    end
    
    puts recent * ", "
    
  end
  
  desc 'Remove duplicates from Printers'
  task :del_duplicates => :environment do
    
    all_dupl = []
    p_make_cols = ['brand']
    p_model_cols = ['model', 'mpn']
    counter = 0
    Printer.all.each do |p|
      dupl = duplicate_entries p_make_cols, p_model_cols, p
      if dupl.length > 1
        puts "#{dupl.length} duplicates for #{p.id}: ids #{dupl * ', '}"   
        all_dupl << dupl.sort unless all_dupl.include? dupl.sort
        counter = counter + 1
      end
    end
    
    puts "All matching sets:" 
    all_dupl.each do |set|
      puts set * ", "
    end
    
    puts "Num sets: #{all_dupl.length}. Num messages: " + counter.to_s
    
  end
#  
#  desc 'Find duplicates'
#  task :duplicates => :environment do
#    
#    puts "Checking NEWEGGPRINTERS for duplicates"
#    
#    np_make_cols = ['brand']
#    np_model_cols = ['model']
#    
#    NeweggPrinter.all.each do |np|
#      dupl = duplicate_entries np_make_cols, np_model_cols, np
#      puts "#{dupl.length} duplicates for #{np.id}: ids #{dupl * ', '}"  if dupl.length > 0 
#    end
#    
#    puts "Checking PRINTERS for duplicates"
#    
#    p_make_cols = ['brand']
#    p_model_cols = ['model', 'mpn']
#    counter = 0
#    Printer.all.each do |p|
#      dupl = duplicate_entries p_make_cols, p_model_cols, p
#      puts "#{dupl.length} duplicates for #{p.id}: ids #{dupl * ', '}"  if dupl.length > 0 
#      counter++ if dupl.length > 0 
#    end
#    
#    puts "#{counter} "
#  end
#  
#  desc "Clean up Newegg data and move it to different tables"
#  task :clean_up => :environment do
#      
#    @logger = File.open("./log/newegg_scraper_cleanup.log", 'w+')
#    setup_att_names_mapping
#    
#    NeweggPrinterScrapedData.all.each_with_index do |np, i|
#        
#        real_item_number = np.item_number.gsub(/R$/,'')
#    
#        offering = NeweggOffering.find_or_create_by_item_number(np.item_number)
#        
#        # All offering stuff
#        if np.saleprice  
#          fill_in 'priceint', get_price_i(np.saleprice).to_s, offering 
#          fill_in 'pricestr', get_price_s(np.saleprice), offering       
#          fill_in 'toolow', np.toolow, offering if np.toolow
#          fill_in 'priceUpdate', np.updated_at, offering 
#        end
#        
#        if real_item_number == np.item_number then retailer_id= 4 else retailer_id= 6 end
#        fill_in 'retailer_id', retailer_id.to_s, offering
#        
#        newnp = NeweggPrinter.find_or_create_by_item_number(real_item_number)
#        
#        # Warranty from Parts & labor.
#        multiple_fields_to_one(['parts', 'labor'], 'warranty', np, newnp, true)
#        
#        # Colorprinter
#        if np.outputtype == 'Monochrome' 
#          fill_in 'colorprinter', false, newnp
#        elsif np.outputtype == 'Color'
#          fill_in 'colorprinter', true, newnp
#        end
#        
#        # Duplex
#        # Do I need this? FIND OUT
#        if np.duplexprinting == true
#          fill_in 'duplex', "Yes", newnp
#        elsif !np.duplexprinting.nil?
#          fill_in 'duplex', "No", newnp
#        end
#        
#        # Platform
#        multiple_fields_to_one(['windowscompatible','macintoshcompatible','windowsvista'], \
#                                'platform', np, newnp)
#        
#        # Scrapedat
#        fill_in 'scrapedat', np.updated_at, newnp # TODO this is not right... or is it?
#        
#        # Dimensions
#        if np.dimensions
#          dims = np.dimensions.scan(/\d+\.?\d*/) 
#          @logger.puts "Dimensions wonky for #{np.id}: #{np.dimensions}, dims has length #{dims.length}" unless dims.length == 3
#          break if dims.length < 3
#          # TODO item lwh not what I thought?
#          fill_in 'itemlength', dims[2].to_f*100, newnp
#          fill_in 'itemwidth', dims[0].to_f*100, newnp
#          fill_in 'itemheight', dims[1].to_f*100, newnp
#        end
#        
#        # Ignore these:
#        ignore_list = ['id' , 'item_number' ,'created_at' , 'updated_at']
#        
#        # The rest are just plain copy-paste
#        np.attributes.each do |att, val|
#          
#          amazon_att = @attribute_names_mapping[att] || att
#          
#          if val and newnp.has_attribute? amazon_att and !ignore_list.include? att 
#            np_val = val
#            
#            np_val.gsub!(/ dpi/,'') if att == 'blackprintquality'
#            np_val.gsub!('~','to') if att == 'mediasizessupported'
#            np_val.gsub!(/''/, '\"') if att == 'dimensions'
#            np_val = get_f(np.processormhz) if att == 'processormhz'
#            
#            fill_in amazon_att, np_val, newnp
#          end
#           
#        end
#    end
#    
#    @logger.close
#  end
#
#  desc "Scrape model name from ids"
#  task :data => :environment do
#    @logfile = File.open("./log/newegg_scraper.log", 'w+')
#    
#    NeweggPrinterScrapedData.all.each_with_index do |np, i|
#      
#    # ---- From HERE ..
#      url = id_to_url(np.item_number) 
#      infopage = Nokogiri::HTML(open(url))
#      
#      #Scrape : price and img url
#      price_el = infopage.xpath('//div[@id="pclaPriceArea"]/dl[@class="price"]')
#      
#      orig_price_el = price_el.css(".original").first
#      fill_in_optional 'listprice', orig_price_el, np
#      
#      sale_price_el = price_el.css(".final").first
#      fill_in_optional 'saleprice', sale_price_el, np
#
#      # too low
#      low_price_el = price_el.css('.lowestPrice').first
#      
#      if (low_price_el)
#        lowpricepage = Nokogiri::HTML(open("http://www.newegg.com/Product/MappingPrice.aspx?Item=#{np.item_number}"))
#        lowpage_lowprice_el = lowpricepage.css('.final').first
#        fill_in_optional 'saleprice', lowpage_lowprice_el, np
#        fill_in 'toolow', true ,np
#      end
#      
#      # TODO what if it's 'deactivated'?
#      
#      # Image url
#      img_url = nil
#      
#      begin
#        image_el = infopage.css('#pclaImageArea img[src]')
#        image_el = image_el.first || image_el
#        img_url = image_el.attribute('src')
#      rescue
#        img_url = image_el.first.attribute('src')
#      end
#      
#      fill_in("imageurl", img_url, np)
#      
#      # STUFF TO SCRAPE
#      specs = infopage.xpath("//table[@class='specification']/tr")
#      
#      specs.each do |row|
#        if(row.css("td.name").length >0)
#          name = row.css("td.name").first.content.to_s
#          desc = row.css("td.desc").first.content.to_s
#          
#          puts "#{to_attribute(name)} : #{desc}"
#          fill_in to_attribute(name), desc, np
#        end
#      end
#    # -- to HERE: put in separate method.  
#      puts "Progress: done #{i} of #{NeweggPrinterScrapedData.count} printers..."
#      sleep(30)
#    end
#    
#    @logfile.close
#    
#  end
#  
#  desc "Match printers from Newegg to existing Amazon records"
#  task :map_to_db => :environment do
#    
#    @logfile = File.open("./log/newegg_mapper.log", 'w+')
#    @mismatch = 0
#    @mismatch_printeronly = 0
#    @match = 0
#    setup_att_names_mapping
#    
#    NeweggPrinter.all.each do |np|
#    
#      make = (np.brand || "").downcase
#      ap_list = match_printer( make, np.model, np.series)
#      
#      if(make.include? 'oki')
#        ap_list = ap_list | match_printer( make, 'oki', np.series)
#      elsif(make.include?( 'hp') or make.include?( 'hewlett'))
#        ap_list = ap_list | match_alt_names(['hp','hewlett'],np.model, np.series)
#      end
#    
#      @match = @match + ap_list.length
#      if ap_list.length > 1
#        ids = []
#        ap_list.each do |found_ap| ids << found_ap.id end
#        @logfile.puts "#{ap_list.length} matches (#{ids * ','}) for Newegg #{np.id} (#{np.model} #{np.brand})" 
#      end
#      @logfile.puts "No match for Newegg #{np.id}: #{np.model} #{np.brand}" if ap_list.length == 0
#     
#      ap_list.each do |ap|
#        prev_mismatch = @mismatch
#        np.attribute_names.each do |att|
#          # Nothing so far
#        end
#        @mismatch_printeronly = @mismatch_printeronly + 1 if prev_mismatch != @mismatch        
#      end
#    end
#   
#    puts "Done comparison. #{@mismatch} discrepancies found in #{@mismatch_printeronly} printers." 
#    puts "#{@match} printers were found with matching model & make."
#    puts "Log file at #{@logfile.path}"
#    @logfile.close 
#    
#  end
#  
#  
#  # --- Database interacting helper methods --- #
#  
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
    #matching.delete_if { |x| x.id == entry.id }
    matching_ids = []
    matching.each do |x| matching_ids << x.id end
    return matching_ids
  end
#  
#  def match_printer make, model, series
#    
#    modelcols = [ 'model', 'mpn']
#    brandcols = [ 'manufacturer', 'brand']
#    modelnames = []
#    modelnames << model unless model.nil? or model ==""
#    modelnames << series unless series.nil? or series ==""
#    matching = []
#    
#    
#    modelnames.each do |mname|
#      modelcols.each do |mcol|
#        brandcols.each do |bcol|
#          matching = matching | Printer.find(:all,:conditions => ["#{bcol} LIKE (?) AND #{mcol} LIKE (?)", "%#{make}%", "#{mname}"])
#        end
#      end
#    end
#    return matching
#  end
#  
#  # Matches col names of scraped specs to real col names.
#  def setup_att_names_mapping
#    
#       #'sale_price'             => 'salepriceint', \ # Fill in otherwise
#       # 'list_price'             => 'listpriceint', \ # fill in otherwise
#      #  'brand'                  => 'manufacturer', \ # Don't fill in manufacturer
#        #'outputtype'             => 'colorprinter', \
#    #'duplexprinting'         => 'duplex', \    # fill in otherwise
#    
#                                # Newegg                     Amazon
#    @attribute_names_mapping = { 'connectivitytechnology' => 'connectivity', \
#                                'blackprintspeed'        => 'ppm', \
#                                'timetofirstpageseconds' => 'ttp', \
#                                'inputcapacitystd'       => 'paperinput', \
#                                'outputcapacitystd'      => 'paperoutput', \
#                                'maxdutycycle'           => 'dutycycle', \
#                                'inputcapacitystd'       => 'paperinput', \
#                                'outputcapacitystd'      => 'paperoutput', \
#                                'blackprintquality'      => 'resolution', \
#                                'printlanguagesstd'      => 'language', \
#                                'microprocessortype'     => 'cputype', \
#                                'processormhz'           => 'cpuspeed', \
#                                'other'                  => 'special', \
#                                'memorystd'             => 'systemmemory', \
#                                'mediasizessupported'   => 'papersize',\
#                                'memorymax' => 'systemmemorymax',\
#                                'inputcapacitymax' => 'paperinputmax',\
#                                'outputcapacitymax'=> 'paperoutputmax' }
#    # Last 3 unique
#  end
#  
#  def fill_in_optional name, el, record
#    fill_in( name , el.text, record )if el
#  end
#  
#  def fill_in name, desc, record
#        
#    unless record.has_attribute? name
#      @logfile.puts "#{name} missing from attribute list"
#      return
#    end
#    
#    return if desc.nil?
#    
#    # Should I overwrite? Should I log this?
#    #return if record.attribute_present? name
#    
#    case (record.class.columns_hash[name].type)
#      when :integer
#        val = get_i(desc.to_s)
#      when :float
#        val = get_f(desc.to_s)
#      else
#        val = desc
#    end  
#    
#    record.update_attribute(name, val)
#    
#  end
#  
#  # Converts col name to an attribute by taking out funny chars.
#  def to_attribute label
#    return label.downcase.gsub(/ /,'').gsub(/[^a-zA-Z 0-9]/, "")
#  end
#  
#  # --- Data cleaning helper methods --- #
#  
#  def remove_funny_chars str
#    clean = str.gsub(/Â/,'')
#    return clean
#  end
#  
#  def get_price_i price_f
#    return (price_f * 100).round
#  end
#  
#  def get_price_s price_f
#    return (format "$%.2f", price_f)
#  end
#  
#  def get_i str
#    return str.strip.match('\d+').to_s.to_i
#  end
#  
#  def get_f str
#    return str.strip.match('\d+\.?\d+').to_s.to_f
#  end
#  
#  def id_to_url pid
#    return 'http://www.newegg.com/Product/Product.aspx?Item='+ pid.to_s
#  end
#  
end