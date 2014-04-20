module Inkgrabber
  
  def inkgrabber_clean dirty_atts
    clean_atts = cartridge_cleaning_code dirty_atts, 'Ink Grabber', false
    clean_atts['mpn'] = clean_atts['item_number'] if clean_atts['real'] == false  
    clean_atts['yield'] = parse_yield(clean_atts['title']) if clean_atts['yield'].nil?
    clean_atts['toolow'] = false
    clean_atts['retailer_id'] = 18 
    clean_atts['instock'] = clean_atts['stock'] = case dirty_atts['availability'] 
      when "/stock.gif"
        true
      when "/oostock.gif"      
        false
      end
    clean_atts['availability'] = nil
    
    return clean_atts
  end
  
  def special_url url
   special_url = "http://www.jdoqocy.com/click-3328141-10429337?url="
   special_url += CGI.escape(url)
   return special_url
  end
  
  def parse_yield str
    return nil if str.nil?
    yld = get_f_with_units( str,  /\s?(sheet|page)(s)?/i )
    yld = get_f_with_units(str,  /\s?y(ie)?ld/i) if yld.nil?
    yld = get_f_with_units_in_front(str,  /y(ie)?ld\s*-*/i) if yld.nil?
    return yld
  end
  
  def decently_clean_atts? clean_atts
    model_ok = [clean_atts['model'], clean_atts['mpn']].reject{|x| 
      x.nil?}.collect{|x| likely_cartridge_model_name(x)}.sort.last >= 2
    return (!clean_atts['brand'].nil? and model_ok and clean_atts['toner'] != false)
  end
  
end
namespace :scrape_grabber do

  desc 'Scrape, clean, and put in db'
  task :all => [:scrape, :to_cartridge, :update_bestoffers]
  
  desc 'Scrape data'
  task :scrape => [:sandbox1, :sandbox2]

  task :update_bestoffers => :init do
    relevant_cart_ids = GrabberOffering.all.collect{|goff| goff.product_id}.uniq
    relevant_cart_ids.each do |cart_id|
      cart = Cartridge.find(cart_id)
      update_bestoffer_regional(cart, 'US') # This function does not exist.
    end
  end

  # This whole function needs rewriting, it's probably not a priority.
  task :to_cartridge => :init do
    GrabberCartridge.all.each do |gc|
      clean_atts = inkgrabber_clean gc.attributes
      if decently_clean_atts?(clean_atts)
        matching_cartridges = find_matching_product [clean_atts['brand']], [clean_atts['model'], clean_atts['mpn']], Cartridge
        puts "#{matching_cartridges.length} matching cartridges found"
        cart = matching_cartridges[0] 
        cart = Cartridge.new(clean_atts) if cart.nil? 
        comp = create_uniq_compatibility cart.id, 'Cartridge', gc.printerid , 'Printer'
        goff = GrabberOffering.find_or_create_by_item_number(gc.item_number)
        parse_and_set_attribute 'product_id', cart.id, goff
        offr = find_or_create_offering goff, clean_atts # This doesn't work.
        parse_and_set_attribute 'product_id', cart.id, offr
        parse_and_set_attribute 'product_type', 'Cartridge', offr
        parse_and_set_attribute 'url', special_url(gc.detailpageurl.strip), offr if gc.detailpageurl
      else
        puts "#{clean_atts['brand']} #{clean_atts['model']} #{clean_atts['mpn']} not a valid entry"
      end
    end
    puts 'done'
  end

  task :printer_matching_sandbox => :init do
    baseurl = 'http://inkgrabber.com'
    folder = 'scrape_me/inkgrabber'
    temp_models_file = File.open("./#{folder}/temp2.txt", 'r')
    
    while (line = temp_models_file.gets)
      stuff = line.split('|')
      matching = find_matching_product [stuff[0]], [stuff[1]], Printer, $printer_series
      debugger if matching.length == 0 and stuff[0].match(/^h/i)
      puts "#{matching.length} matches for #{stuff[0]} #{stuff[1]}."

    end        
    temp_models_file.close
  end

  task :sandbox2 => :init do
    baseurl = 'http://inkgrabber.com'
    folder = 'scrape_me/inkgrabber'
    temp_models_file = File.open("./#{folder}/temp.txt", 'r')
    
    while (line = temp_models_file.gets)
      stuff = line.split('|')
      matching = find_matching_product [stuff[0]], [stuff[1]], Printer, $printer_series
      puts "#{matching.length} matches for #{stuff[0]} #{stuff[1]}."
      if matching.length > 0
        printer_page_url ="#{baseurl}#{stuff[2]}"
        printer_page = Nokogiri::HTML(open(printer_page_url))
        
        pix = printer_page.css('td[width="18%"]').collect{|x| x.css('img @src').text}
        avails = printer_page.css('td[width="15%"]').collect{|x| x.css('img @src').text}
        forms = printer_page.css('form[action="/cgi/pgwebshop.cgi"]')
        forms.each_with_index do |form,index|
          
          itemno = get_el(form.css('input[name="Item_No"]')).[]('value')
          gc = GrabberCartridge.find_or_create_by_item_number_and_printerid(itemno, matching[0].id)
          atts = {}
          atts['detailpageurl'] = printer_page_url
          atts['imageurl' ] = baseurl+pix[index+1]
          atts['availability'] = avails[index+1]
          atts['pricestr'] = get_el(form.css('input[name="Item_Price"]')).[]('value')
          atts['title'] = get_el(form.css('input[name="Item_Name"]')).[]('value')
          atts['printermodel'] = stuff[0]
          atts['printerbrand'] = stuff[1]
          atts['printerids'] = matching.collect{|x| x.id} * ', '
          atts.each{|name,val| parse_and_set_attribute(name, val, gc)}
        end
        puts "#{matching[0]} works"
      end
    end        
    temp_models_file.close
  end

  task :sandbox1 => :init do 
    homepage = Nokogiri::HTML(open('http://inkgrabber.com/'))
    sleep(10)
    brand_links = homepage.css('span.style31 a').inject({}){|r,x| r.merge!(x.content => x.[]('href')) }
    folder = 'scrape_me/inkgrabber'
    temp_models_file = File.open("./#{folder}/temp.txt", 'w+')
    
    brand_links.each do |brand,link|
      puts "Getting page for #{brand}..."
      brandpage = Nokogiri::HTML(open(link))
      sleep(30)
      model_links = brandpage.xpath('//td/a').inject({}){|r,x| r.merge!(x.content => x.[]('href')) }
      model_links.each{|mdl, ln|  temp_models_file.puts "#{brand}|#{mdl}|#{ln}"}
    end
    temp_models_file.close
  end


  task :init => :environment do
    require 'open-uri'
    require 'nokogiri'
    include Nokogiri
    require 'helper_libs'
    include DataLib
    include CartridgeLib
    include Inkgrabber
    
    Session.product_type = Cartridge
  end
end