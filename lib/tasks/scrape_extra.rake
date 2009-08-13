# Rakefile and module used to scrape additional data
# such as product images and models from UPC number.

module ScrapeExtra
  
  def file_exists_for itemnum, sz=''
     begin
        image = Magick::ImageList.new(filename_from_itemnum(itemnum,sz))
        image = image.first if image.class == Magick::ImageList
        return false if image.nil?
      rescue
        return false
      else
        return image.rows
      end
      return false
  end
  
  def url_from_item_and_sz itemnum, sz
    return "/images/newegg/#{itemnum}_#{sz}.JPEG"
  end
  
  def filename_from_itemnum itemnum, sz=''
    ext = 'JPEG'
    ext = 'jpg' if sz==''
    return "#{$folder}/images/newegg/#{itemnum}#{sz}.#{ext}"
  end
  
  def resize img
  filename = img.filename.gsub(/\..+$/,'')
    scaled = []
    trimmed = img.trim
    if trimmed.rows != img.rows or trimmed.columns != img.columns
      puts "Start with #{img.rows} by #{img.columns}, end with  #{trimmed.rows} by #{trimmed.columns}" 
    end
    $sizes.each do |size|
      scaled << trimmed.resize_to_fit(size[0],size[1]) #if trimmed.columns >= size[0] or trimmed.rows >= size[1]
    end
    scaled.each_with_index do |pic, index|
      pic.write "#{filename}_#{$size_names[index]}.#{img.format}"
    end  
    return scaled.collect
  end
  
end

namespace :scrape_extra do
  
  desc 'add data from amazon'
  task :moredata_amazon => :init do
    
    require 'webrat'
    require 'mechanize' # Needed to make Webrat work
    
    require 'rubygems'
    require 'nokogiri'

    require 'conversion_helper'
    include ConversionHelper

    require 'database_helper'
    include DatabaseHelper
    
    require 'validation_helper'
    include ValidationHelper
    
    $model = Printer
    
    Webrat.configure do |conf| 
     conf.mode = :mechanize  # Can't be rails or Webrat won't work 
    end

    WWW::Mechanize.html_parser = Nokogiri::HTML
    
    interesting_fields = ['ppm', 'resolution', 'resolutionmax', 'paperinput','scanner', 'printserver'].inject({}){|r, x| r.merge({x,[]})}
    ok_fields = ['ppm', 'paperinput']
    
    validids = Printer.valid.collect{|x| x.id}
    validanyway = 0
    
    watever = false
    
    sesh = Webrat.session_class.new
    problems = 0
    
    amazonprinterids = (AmazonPrinter.all - AmazonPrinter.find_all_by_asin(nil)).reject{|x| 
      x.product_id.nil? or validids.include?(x.product_id) }.collect{|x| x.id}
    
    amazonprinterids.each do |apid|
      ap = AmazonPrinter.find(apid)
      p = Printer.find(ap.product_id)
      
      puts 'ASIN='+ap.asin 
      begin
        sesh.visit('http://www.amazon.com/o/asin/' + ap.asin)
        sesh.click_link('See more technical details')
      rescue
        puts "Uh oh"
        problems += 1 
      else
        doc = Nokogiri::HTML(sesh.response.body)
        array = doc.css('.content ul li')
        features = {}
        array.each {|i|
          t = i.content.split(': ')
          features[t[0].downcase.tr(' -\(\)_','')]=t[1]
        }
        
        # TODO use inject()?
        mapped_specs = {}
        features.each{|x,y| get_property_names(x).each do |prop| 
          mapped_specs[prop] = (mapped_specs[prop] || '') + "#{ScrapingHelper.sep}#{y}" unless y.nil?
          end
        }
        clean_specs = generic_printer_cleaning_code mapped_specs
        
        puts "#{p.id} rescraped"
        
        
        debugger if clean_specs['paperinput'].nil?
        
        validanyway += 1 if (validids.include?p.id)
        puts "Yay! I'm useful!" unless (validids.include?p.id)
        ok_fields.each do |field|
          fill_in_missing field, clean_specs[field], p
        end
        interesting_fields.keys.each do |f|
          interesting_fields[f] << clean_specs[f]
        end
        
        sleep(15) if watever
      end  
    end
      puts "Done with #{problems} problems"
      debugger
      puts " --- "
    
  end
  
  desc 'Add data from elsewhere'
  task :moredata  => :init do
    
    require 'rubygems'
    require 'nokogiri'

    require 'conversion_helper'
    include ConversionHelper

    require 'database_helper'
    include DatabaseHelper
    
    require 'validation_helper'
    include ValidationHelper
    
    $model = Printer
    
    ok_fields = ['ppm', 'resolution', 'resolutionmax', 'paperinput','scanner', 'printserver']
    
    # Lexmark:
    links = []
    3.times do |pg_index|    
      page = Nokogiri::HTML(open("scrape_me/manfpages/lexmark_#{pg_index+1}.html"))
      links += page.css('div#content a').collect{|x| x.[]('href')}.uniq
    end
    puts "#{links.count} printers found in Lexmark"
    
    just_continue = false
    validids = Printer.valid.collect{|x| x.id}
    validanyway = 0
    fieldname = 'dimensions'
    debugme = []
    repeats = []
    nomatch = 0
    links.each_with_index do |link, index|
      page = Nokogiri::HTML(open(link))
      specs = scrape_table(page.css('div.specs tr'), 'td.spectitle', 'td.specinfo')
      
      # TODO use inject()?
      mapped_specs = {}
      mapped_specs_readable = {}
      specs.each{|x,y| get_property_names(x).each do |prop| 
        mapped_specs_readable[prop] = (mapped_specs_readable[prop] || '') + " #{x}:#{y}" unless y.nil?
        mapped_specs[prop] = (mapped_specs[prop] || '') + "#{ScrapingHelper.sep}#{y}" unless y.nil?
        end
      }
      mapped_specs['brand'] = 'Lexmark'
      mapped_specs['model'] = get_el(page.css('div#prodInfo h1')).content if get_el(page.css('div#prodInfo h1'))
      clean_specs = generic_printer_cleaning_code mapped_specs
      
      #debugger
      
      # TODO more effective find?
      ps = match_rec_to_printer [clean_specs['brand']], [clean_specs['model']], $model,[]
      if ps.length == 1
        validanyway += 1 if (validids.include?ps.first.id)
        puts "Yay! I'm useful!" unless (validids.include?ps.first.id)
        ok_fields.each do |field|
          fill_in_missing field, clean_specs[field], ps.first
        end
      elsif ps.length == 0
        nomatch += 1 
      else
        repeats << ps.collect{|x| x.id}
      end
      debugme << clean_specs[fieldname]
      
      puts " Done #{index+1}th printer and waiting. "
      sleep(15)
      
    end
    
    puts "#{debugme.uniq.count} unique values in #{fieldname}"
    puts "#{debugme.reject{|x| !x.nil?}.count} nils in #{fieldname}"
    puts "Values in #{fieldname}:"
    puts debugme.uniq.reject{|x| x.nil?}.sort * ', '
    puts "#{nomatch} not matched "
    puts "#{validanyway} valid anyway "
    puts " Repeats listed below: "
    repeats.each{|x| 
      puts x * ','
    }
    puts " --- "
    
  end
  
  desc 'yoopsie UPC lookup'
  task :yoopsie => :init do 
    require 'webrat'
    require 'nokogiri'
    
    Webrat.configure do |conf| 
     conf.mode = :mechanize  # Can't be rails or Webrat won't work 
    end

    WWW::Mechanize.html_parser = Nokogiri::HTML
    
    @sesh = Webrat.session_class.new
    countrycode = 'US'
    
    AmazonPrinter.all.each do |ap|
      asin = ap.asin
      @sesh.visit "http://yoopsie.com/query.php?query=#{asin}&locale=#{countrycode}&index=All"
      doc = @sesh.response.parser
      equiv_id_list = doc.css('span.upc')
      upc = nil
      equiv_id_list.each do |eid|
        removeme = /upc\s?:/i
        upc_hdr = eid.text.match(removeme )
        if upc_hdr
          upc = eid.text.gsub(removeme , '')
        end
      end
      #title = doc.css('h3 a')
      
      puts "#{ap.id} | #{ap.asin} | #{upc}" if upc
      puts "No matching upc" if upc.nil?
      
      sleep(20)
    end
  end
  
  desc 'resize it'
  task :resize_all => :pic_init do

    failed = []
    NeweggPrinter.all.collect{|x| x.item_number}.each do |itemnum|
      begin
        image = Magick::ImageList.new(filename_from_itemnum itemnum)
        image = image.first if image.class == Magick::ImageList
        #unless file_exists_for( itemnum,'s')
          filenames = resize image
          failed << itemnum if filenames.length == 0
        #end
      rescue
        image = nil
        failed << itemnum
      end
    end
    
    puts " The following images weren't resized: "
    puts failed * "\n"
  end
  
  desc 'sandbox'
  task :reduced_pic_stats => :pic_init do
    
   NeweggPrinter.all.collect{|x| x.item_number}.each do |itemnum|
    #['N82E16828112055'].each do |itemnum|
      $size_names.each do |sz|
        curr_filename = filename_from_itemnum(itemnum, "_#{sz}")
        begin
          image = Magick::ImageList.new(curr_filename)
          image = image.first if image.class == Magick::ImageList
        rescue
          image = nil
        end
      
        if image
          dim = "#{sz}: #{image.rows} by #{image.columns}"
          printer = Printer.find(NeweggPrinter.find_by_item_number(itemnum).product_id)
         # if(printer.[]("image#{sz}url").nil?)
            url = url_from_item_and_sz(itemnum, sz)  
            fill_in "image#{sz}url", url, printer
            fill_in "image#{sz}height", image.rows, printer
            fill_in "image#{sz}width", image.columns, printer
          #end
        end
      end
    end
  end
  
  desc 'Fills in '
  task :fill_in_pic_stats => :pic_init do
    no_img_sizes = []
    $size_names.each do |sz|
      no_img_sizes = no_img_sizes | Printer.find( :all, \
        :conditions => ["(image#{sz}height IS NULL OR image#{sz}width IS NULL) AND image#{sz}url IS NOT NULL"])
    end  
    
    no_img_sizes.each do |printer|
      image = nil
      $size_names.each do |sz|        
        begin
          unless printer.[]( "image#{sz}url" ).nil?
            image = Magick::ImageList.new(printer.[]( "image#{sz}url" ))
            image = image.first if image.class == Magick::ImageList
          end
        rescue
          image = nil
        end
        if image
          fill_in "image#{sz}height", image.rows, printer if image.rows
          fill_in "image#{sz}width", image.columns, printer if image.columns
        end
      end
    end
    
  end
  
  desc 'sandbox'
  task :pic_stats => :pic_init do
    
    resolutions = {}
    dimensions = {}
    NeweggPrinter.all.collect{|x| x.imageurl}.each do |filename|
      begin
        image = Magick::ImageList.new(@folder+filename)
        image = image.first if image.class == Magick::ImageList
      rescue
        image = nil
      end
      if image
        res = "#{image.x_resolution} by #{image.y_resolution} "
        dim = "#{image.rows} by #{image.columns}"
        
        if resolutions[res].nil?
          resolutions[res] = 1
        else 
          resolutions[res] += 1
        end
        if dimensions[dim].nil?
          dimensions[dim] = 1
        else 
          dimensions[dim] += 1
        end
        
      end
    end
    
    resolutions.each do |r,n|
      puts "#{r} : #{n} times"
    end
    puts "Dimensions"
    
    dimensions.each do |x,n|
      puts "#{x} : #{n} times"
    end
  end
  
  desc 'Get a pic for every printer'
  task :download_pix => :pic_init do
    
    failed = []
    
    NeweggPrinter.all.each do |x|
      unless x.imageurl.nil? or x.imageurl.empty? or file_exists_for(x.item_number)
        
        oldurl = "http://c1.neweggimages.com/NeweggImage/productimage/" + x.imageurl.split('/').pop
        newurl = download_img oldurl, 'images/newegg', "#{x.item_number}.jpg"
        if(newurl.nil?) # TODO hacky
          oldurl = "http://images17.newegg.com/is/image/newegg/" + x.imageurl.split('/').pop
          newurl = download_img oldurl, 'images/newegg', "#{x.item_number}.jpg"
        end
        
        if(newurl.nil?)
          failed << x.item_number 
        end
        
        puts " Waiting waiting. Downloaded #{oldurl} into #{newurl}."
        sleep(30)
      end
    end
    puts " FAILED DOWNLOADS" if failed.length > 0
    puts failed * "\n"
  end
  
  desc 'pic-init'
  task :pic_init => :init do
  
    require 'RMagick'
    include ScrapeExtra
  
  end
  
  desc 'init'
  task :init => :environment do
    require 'scraping_helper'
    include ScrapingHelper
    
    $folder= 'public'
    $size_names = ['s','m','l']
    $sizes = [[70,50],[140,100],[400,300]]
  end
  
end 