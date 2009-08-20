module Scrape123
  
  def make_offering_from_atts atts, web_id
    url = get_special_url web_id
    offer = RetailerOffering.find(web_id)
    offer = create_product_from_atts atts, RetailerOffering if offer.nil?
    fill_in 'product_type', 'Cartridge', offer
    fill_in 'toolow', false, offer
    fill_in 'priceUpdate', Time.now, offer
    fill_in 'availabilityUpdate', Time.now, offer
    fill_in 'retailer_id', 16, offer
    return offer
  end
  
  def get_special_url web_id
    #TODO For now this is just a regular url.
    base_url = "http://www.123inkjets.com/"
    url = "#{base_url}#{web_id},product.html"
    return url
  end
  
  def clean_brand_rec rec
    brand = clean_brand(rec.model, rec.title)
    fill_in 'brand', brand, rec if brand
  end
  
  def clean_brand model, title
    brand = nil
    if title
      $real_brands.each do |b|
        brand = b unless just_alphanumeric(title).match(/#{just_alphanumeric(b)}/i).nil?
      end
    end
    if title and model and brand.nil?
      debugger
      brand = title.gsub(/.*(compatible|genuine|oem|remanufactured|refurbished|for|other)\s?/i,'').gsub(/\s?#{model}.*/,'') 
    end
    return brand
  end
  
end

namespace :scrape_123 do
  
  task :validate => :init do 
  
    
  
  end
  
  task :clean => :init do 
    
    # Fix brand + model
    $model.all.each{|x| clean_brand_rec(x)}
    
    # fill in Ink
    $model.all.each{|x| 
      fill_in 'ink',  true, x if x.title.match(/ink/i)
      fill_in 'ink', false, x if x.title.match(/toner/i) 
    }
    
    # fill in Real
    $model.all.each{|x| 
      fill_in 'real', false, x if x.title.match(/(alternative|compatible|remanufactured|refurbished)/i)
      fill_in 'real', true, x if x.title.match(/genuine|oem/i)
    }
    
    # fill in Condition
    conditions = ['New', 'OEM', 'Remanufactured', 'Refurbished', 'Compatible']
    $model.all.each{|x| 
      conditions.each{|c| 
        fill_in('condition', c, x) and break if x.title.match(/#{c}/i)
      }
      fill_in 'condition', 'New', x unless x.condition
    }
    
  end
  
  task :sandbox => :init do
    matchingsets = get_matching_sets $model.toner
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
    
      matches = match_rec_to_printer [realbrand], [cart.model], Cartridge
      matching_c = nil
      
      if matches.length == 0
        atts = {'brand' => realbrand, 'model' => cart.model}
        matching_c = create_product_from_atts atts, Cartridge
      elsif matches.length == 1
        matching_c = matches[0]
      else
        debugger
        puts "Duplicate found"
      end
      
      fill_in_all cart.attributes, matching_c, ignoreme
      fill_in 'product_id', matching_c.id, cart
      fill_in 'compatiblebrand', compatbrand, matching_c
      
      make_offering_from_atts(cart.attributes, cart.web_id)
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
        
        matching += (match_rec_to_printer([p_br], [p_md], Printer, $series)).collect{|x| x.id} if p_br and p_md
        
        prevsize = matching.size
      end
      
      matching.each do |pid|
        atts = {'product_id' => pid, 'accessory_id' => cart.product_id, \
          'product_type' => 'Printer', 'accessory_type' => 'Cartridge'}
        compat = Compatibility.find_by_product_type_and_product_id_and_accessory_id_and_accessory_type(\
          'Printer',pid,cart.product_id,'Cartridge')
        compat = create_product_from_atts atts, Compatibility if compat.nil?
      end
    end
  end
  
  task :scrape => :init do
    
    counter = 0
    
    (One23Cartridge.last.web_id-2..3000).each do |num|
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
              props = get_property_names(x, $model)
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
      
      cart = $model.find_or_create_by_web_id(num)
      fill_in_all clean_specs, cart 
      fill_in 'scrapedat', Time.now, cart
      counter += 1
      puts " Done #{counter} #{$model}s "        
      
      sleep(30)
    end
  end
  
  task :re_clean => :init do
    One23Cartridge.all.each do |x|
      clean_brand_rec(x)
    end
  end
  
  task :init => :environment do 
  
      $model = One23Cartridge
      require 'rubygems'
      require 'open-uri'
      
      require 'nokogiri'
  
      require 'scraping_helper'
      include ScrapingHelper
      
      require 'database_helper'
      include DatabaseHelper

      include Scrape123
      
      $series = ['laserjet', 'laserwriter', 'oki', 'phaser',  'imagerunner', 'printer', 'printers', 'qms', \
        'estudio', 'optra', 'pro', 'officejet', 'workcentre', 'other', 'okifax', 'lanierfax', 'okipage',\
        'pixma', 'deskjet', 'stylus', 'docuprint', 'series','color', 'laser', 'printer']
      
      $real_brands = Printer.all.collect{|x| x.brand}.uniq.reject{|x| x.nil?}
      $real_brands += ["Apple", "Brother", "Canon", "Copystar", 'DEC',"Dell", "Easy-On", "Epson", "IBM", \
        'Kodak', "Kyocera Mita", "Lexmark", 'Lanier', "Okidata", "Panasonic", "Pitney Bowes",\
        "Promedia", "Ricoh","Samsung", "Sharp", "Toshiba", "Xerox"]
      
  end
end