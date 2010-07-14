module Scrape123
  def get_special_url web_id
    #TODO For now this is just a regular url.
    base_url = "http://www.123inkjets.com/"
    url = "#{base_url}#{web_id},product.html"
    return url
  end
end

namespace :scrape_123 do
  task :clean => :init do 
    clean_cartridges
  end
  
  task :sandbox => :init do
    matchingsets = get_matching_sets $product_type.toner
    msets = matchingsets.reject{|x| x.length < 2}
    yields = msets.each {|x| puts (x.collect{|z| z.yield} * ", ")}
    debugger
    puts "Matching sets: #{matchingsets.size}"
  end
  
  task :to_cartridge => :init do 
    ignoreme = ['brand','model','id']
    
    all_toner = One23Cartridge.toner.all
    all_toner.each do |cart|
    
      if cart.real
        realbrand = cart.brand 
      else
        realbrand = "123Inkjet #{cart.condition} #{cart.brand}"
      end
      
      compatbrand = cart.brand
    
      matches = find_matching_product([realbrand], [cart.model], Cartridge)
      matching_c = nil
      
      if matches.length == 0
        atts = {'brand' => realbrand, 'model' => cart.model}
        matching_c = Cartridge.new(atts)
      elsif matches.length == 1
        matching_c = matches[0]
      else
        debugger
        puts "Duplicate found"
      end
      
      cart.attributes.each{|name,val| parse_and_set_attribute(name, val, matching_c, ignoreme)}
      parse_and_set_attribute('product_id', matching_c.id, cart)
      parse_and_set_attribute('compatiblebrand', compatbrand, matching_c)
      
      make_offering_from_atts(cart) # This doesn't work
    end
  end
  
  task :compat => :init do
    all_toner = One23Cartridge.toner.all
    all_toner.reject{|x| x.product_id.nil?}.each do |cart|
    
      matching = []
    
      prevsize = 0
    
      cart.compatible.split(',').each do |comp|
        p_br= just_alphanumeric(clean_brand '',comp)
        p_md= comp
        
        matching += (find_matching_product([p_br], [p_md], Printer, $series)).collect{|x| x.id} if p_br and p_md
        
        prevsize = matching.size
      end
      
      matching.each do |pid|
        atts = {'product_id' => pid, 'accessory_id' => cart.product_id, \
          'product_type' => 'Printer', 'accessory_type' => 'Cartridge'}
        compat = Compatibility.find_by_product_type_and_product_id_and_accessory_id_and_accessory_type(\
          'Printer',pid,cart.product_id,'Cartridge')
        compat = Compatibility.new(atts) if compat.nil?
      end
    end
  end
  
  task :scrape => :init do
    
    counter = 0
    
    (One23Cartridge.last.web_id-1..3000).each do |num|
      base_url = "http://www.123inkjets.com/"
      url = "#{base_url}#{num},product.html"
      
      doc = Nokogiri::HTML(open(url))
      specs = {}
      
      
      if doc.css('title').text.match(/oops/i).nil?
        
        specs['detailpageurl'] = url
        
        pic_el = get_el(doc.css('#product_image'))
        specs['imageurl'] = "#{base_url}#{pic_el.[]('src').gsub(/\.md\./, '.lg.')}" if pic_el
        
        title_el = get_el(doc.css('.product-name'))
        specs['title'] = title_el.text if title_el
        
        tables = [scrape_table(doc.css('table.data-table tr'), 'td.label', 'td.value'), \
        scrape_table(doc.css('div.price-box p'), 'span.price-label', 'span.price')]
        
        tables.each{|table|
          table.each{|x,y| 
              props = get_property_names(x, $product_type)
              props.uniq.each do |property|
                specs[property]= y.strip  + " #{specs[property] || ''}" if y
              end 
          }
        }
        
        compat_models = []
        
        compat = get_el(doc.css('div.brand-printer-list'))
        (compat.css('h4').count).times{ |index|
          brand = (compat.css('h4')[index]).text
          models = (compat.css('table')[index]).css('span').collect{|x| x.text}
        
          compat_models += models.collect{|x| 
            ("#{brand} #{x}").split(/\s|-/).reject{|x| x.nil? or x.empty?}.uniq.join(' ')
          }
        } unless compat.nil?
        
        compat_model_str = compat_models.join(', ')
        
        specs['compatible'] = compat_model_str
        
        # DEFAULTS
        specs['region'] = 'US'
        specs['brand'] = clean_brand(specs['model'], specs['title'])
        
        specs['stock'] = specs['instock'] = true
      else
        specs['stock'] = specs['instock'] = false
      end
      
      clean_specs = cartridge_cleaning_code(specs)
      
      cart = $product_type.find_or_create_by_web_id(num)
      clean_specs.each{|name,val| parse_and_set_attribute(name, val, cart)}
      parse_and_set_attribute 'scrapedat', Time.now, cart
      counter += 1
      puts " Done #{counter} #{$product_type}s "        
      
      sleep(30)
    end
  end
  
  task :re_clean => :init do
    activerecords_to_save = []
    One23Cartridge.all.each do |x|
      clean_brand_rec(x)
      activerecords_to_save.push(x)
    end
    One23Cartridge.transaction do
      activerecords_to_save.each(&:save)
    end
  end
  
  task :init => :environment do 
  
      $product_type = One23Cartridge
      require 'rubygems'
      require 'open-uri'
      
      require 'nokogiri'
  
      require 'scraping_helper'
      include ScrapingHelper
      
      require 'database_helper'
      include DatabaseHelper      
      
      require 'cartridge_helper'
      include CartridgeHelper

      include Scrape123
      
      init_series
      
      init_brands
      
  end
end