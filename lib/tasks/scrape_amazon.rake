module AmazonScraper
  def download(url)
    return nil if url.nil?
    return url if url.index(/\/images\/Amazon\//)
    url = 'http://ecx.images-amazon.com/images/I/'+url if url.length < 30 
    filename = url.split('/').pop
    puts filename
    ret = '/images/Amazon/'+filename
    begin
    f = open('/optemo/site/public/images/Amazon/'+filename,"w").write(open(url).read)
    rescue OpenURI::HTTPError
      ret = ""
    end
    ret
  end

  # Sets up env and related stuff
  def regularsetup
    # Requires.
    require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
    require 'webrat'
    require 'mechanize' # Needed to make Webrat work
  
    Webrat.configure do |conf|
      conf.mode = :mechanize # Can't be rails or Webrat won't work
    end
    sesh = Webrat.session_class.new
    sesh.mechanize.user_agent_alias = 'Mac Safari'
    sesh.mechanize.user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1"
    sesh
  end

  def special_url asin
    return "http://www.amazon.com/o/asin/#{asin}"
  end

  def details_from_one_page doc, model=$model
    array = doc.css('.content ul li')
    features = {}
    array.each_with_index {|i, index|
      t = i.content.split(/:/)
      props = get_property_names(t[0], model)
      props.uniq.each do |property|
        features[property]= t[1].strip  + " #{features[property] || ''}" if t[1]
      end
    }
    return features
  end

  def scrape_compatibility(asin,sesh=nil)
  
    sesh = regularsetup unless sesh
   
    features = {}
    
    begin
      sesh.visit('http://www.amazon.com/o/asin/' + asin)
      doc = Nokogiri::HTML(sesh.response.body)
      compatible_el = get_el(doc.css('div.content').reject{|x| x.text.nil? \
        || x.text.match(/(compatible|use with)/i).nil?})
      
      if(compatible_el and compatible_el.css('li').count > 0)
        compatible_el = get_el( compatible_el.css('li').\
        reject{|x| x.text.nil? || x.text.match(/(compatible|use with)/i).nil?})
      end
      features['compatible'] = compatible_el.text.gsub(/.*(compatible|use with)/i,'') if compatible_el
      
      sleep(10)
    end
    doc = Nokogiri::HTML(sesh.response.body)
    
    return features
  end

  def scrape_details_general(asin,sesh=nil)
  
    sesh = regularsetup unless sesh
    features = {}
    
    begin
      sesh.visit('http://www.amazon.com/o/asin/' + asin)
      doc = Nokogiri::HTML(sesh.response.body)
      features['region'] = 'US'
      features['title'] = get_el(doc.css('h1')).content if get_el(doc.css('h1'))
      
      features['imageurl'] = get_el(doc.css('img#prodImage')).attribute('src') if get_el(doc.css('img#prodImage'))
      
      brand_el = doc.css('span').reject{|x| x.content.match(/other products by/i).nil?}.first
      features['brand'] = brand_el.css('a').text if brand_el
      
      features.merge!(( details_from_one_page(doc) || {} ).reject{|x,y| x == 'brand'})
      sleep(10)
      
      sesh.click_link('See more technical details')       
      doc = Nokogiri::HTML(sesh.response.body)
      features.merge!(( details_from_one_page(doc) || {} ).reject{|x,y| x == 'brand'})
      sleep(10)
    rescue
      features['nodetails'] = true
    end
    doc = Nokogiri::HTML(sesh.response.body)
    
    return features
  end

  def scrape_details(p)
    require 'webrat'
    puts 'ASIN='+p.asin
    sesh = regularsetup
    begin
    sesh.visit('http://www.amazon.com/o/asin/' + p.asin)
    #fetch 'http://www.amazon.com/o/asin/' + 'B000F005U0'
    #fetch 'http://www.amazon.com/Magicolor-2550-Dn-Color-Laser/dp/tech-data/B000I7VK22/ref=de_a_smtd'
    sesh.click_link('See more technical details')
    rescue
      p.nodetails = true
      return p
    end
    doc = Nokogiri::HTML(sesh.response.body)
    array = doc.css('.content ul li')
    features = {}
    array.each {|i|
      t = i.content.split(': ')
      features[t[0].downcase.tr(' -\(\)_','')]=t[1]
      }
  
    #pp features
    res = []
    features.each {|key, value| 
      next if value.nil?
      if key[/maximumprintspeed/]
        p.ppm = value.to_f unless !p.ppm.nil? && p.ppm >= value.to_i #Keep fastest value
        #puts 'PPM: '+p.ppm.to_s
      end
      if key[/maximumprintspeed/] && key[/colou?r/] #Color
        p.ppmcolor = value.to_f
        #puts 'PPM(Color): '+p.ppmcolor.to_s
      end
      if key[/firstpageoutputtime|timetoprint/]
        p.ttp = value.match(/\d+(.\d+)?/)[0].to_f
        #puts 'TTP:'+p.ttp.to_s
      end
      if key[/sheetcapacity|standardpapercapacity/]
        p.paperinput = value.match(/\d+/)[0].to_i unless !p.paperinput.nil? && p.paperinput > value.to_i #Keep largest value
        #puts 'Paper Input:'+p.paperinput.to_s
      end
      if key[/resolution/] && res.size < 2
        if v = value.match(/(\d,\d{3}|\d+) ?x?X? ?(\d,\d{3}|\d+)?/)
          tmp = v[1,2].compact
          tmp*=2 if tmp.size == 1
          p.resolution = tmp.sort{|a,b| 
            a.gsub!(',','')
            b.gsub!(',','')
            a.to_i < b.to_i ? 1 : a.to_i > b.to_i ? -1 : 0
          }.join(' x ')
          p.resolutionmax = p.resolution.split(' x ')[0]
        end
      end
      if key[/printerinterface/] || (key[/connectivitytechnology/] && value != 'Wired')
        p.connectivity = value
        #puts p.connectivity
      end
      if key[/hardwareplatform/]
        p.platform = value
        #puts 'HW: '+p.platform
      end
      if key[/width/]
        #puts 'Width: ' + p.itemwidth.to_s + ' <> ' + value rescue nil
        p.itemwidth = value.to_f * 100
        #puts 'Width: ' + p.itemwidth.to_s
      end
      if key[/ram/]
        p.systemmemorysize = value.match(/\d+/)[0]
        #puts "RAM" + p.systemmemorysize.to_s
      end
      if key[/printeroutput/]
        p.colorprinter = !value[/(C|c)olou?r/].nil?
        #puts 'Color:' + (p.colorprinter ? 'True' : 'False')
      end
      if key[/scannertype/]
        p.scanner = value[/(N|n)one/].nil?
        #puts 'Scanner:' + (p.scanner ? 'True' : 'False')
      end
      if key[/networkingfeature/]
        p.printserver = !value[/(S|s)erver/].nil?
      end
      if key[/printtechnology/]
        p.colorprinter = value.index(/(B|b)(\/|&)?(W|w)/).nil?
      end
      if key[/duplex/]
        p.duplex = !value.downcase.index('yes').nil?
      end
      if key[/dutycycle/]
        p.dutycycle = value.match(/(\d|,)+/)[0].tr(',','').to_i
      end
    }
  
    p.scrapedat = Time.now
    p
  end

end

namespace :scrape_amazon do


  task :cart_init => :init do 
    require 'helper_libs'
    include DataLib
    include CartridgeLib
    
    init_series
    init_brands
    
    $ignoreme =  ['brand','model','id']
    $model = Cartridge
    $amazonmodel = AmazonCartridge  
  end

  desc 'Convert AmazonCartridges to Cartridges'
  task :to_cartridge => :cart_init do
  
    # Pick only toner cartridges with 
    # reasonably valid model names for matching.
    convertme = AmazonCartridge.toner.reject{|x| 
      (likely_cartridge_model_name(x.model) < 2) or \
      x.model.nil? or x.realbrand.nil?  or x.real.nil?}
    
    convertme.each do |ac|
      brand = nil
      if ac.real == true
        brand = ac.realbrand 
      elsif ac.real == false and ac.condition != nil
        brand = "#{ac.realbrand} #{ac.condition} #{ac.compatiblebrand}" 
      end
            
      matches = match_rec_to_printer [brand], [ac.model, ac.mpn], Cartridge if brand
      matches.reject!{|x| !x.real.nil? and !ac.real.nil? and x.real != ac.real } if matches
      matching_c = nil
      
      if matches and matches.length == 0
        atts = {'brand' => brand, 'model' => ac.model}
        puts atts.values * '  -  '
        matching_c = create_product_from_atts atts, Cartridge
      elsif matches and matches.length == 1
        matching_c = matches[0]
      elsif matches
        debugger
        puts "Duplicate found"
      end
      
      if matching_c
        fill_in_all ac.attributes, matching_c, $ignoreme
        fill_in 'product_id', matching_c.id, ac
        fill_in 'brand', ac.realbrand, matching_c
      end
    end
  end
  
  desc 'Make entries into Compatibility table'
  task :compatibilities => :cart_init do
  
    start =  Time.now
  
    all_printer_models = Printer.all.collect{|x| [just_alphanumeric(x.model),x.id]}.uniq.reject{|x| x[0].nil? or x[0] == ''}
    all_printer_models += Printer.all.collect{|x| [just_alphanumeric(x.mpn),x.id]}.uniq.reject{|x| x[0].nil? or x[0] == ''}
    nice_printer_models = all_printer_models.reject{|x| likely_model_name(x[0]) < 2}.uniq
  
    counter = 0
  
    AmazonCartridge.scraped.toner.each do |ac|
      cid = ac.product_id
      if cid 
        c = Cartridge.find(cid)
        compat_txt = just_alphanumeric(ac.compatible)
        if compat_txt and compat_txt != ''
          nice_printer_models.each do |mdl|
            mymatch = compat_txt.match(/#{mdl[0]}/ix)
            if mymatch
              puts "Match found: #{mymatch.to_s} (printer #{mdl[1]}) fits cartridge #{cid}" 
              counter+= 1
              create_uniq_compatibility(cid, 'Cartridge', mdl[1], 'Printer')
            end
          end
        end
      end 
    end
  
    finish = Time.now
    puts "This took #{finish - start} seconds"
    puts "#{counter} matching models found!"
  end
  
  desc "Rename %2B (+)"
  task :image_unescape => :init do
    Camera.find(:all).each {|c|
      s = c.imagesurl.gsub(/%2(b|B)/,'-') if !c.imagesurl.nil?
      m = c.imagemurl.gsub(/%2(b|B)/,'-') if !c.imagemurl.nil?
      l = c.imagelurl.gsub(/%2(b|B)/,'-') if !c.imagelurl.nil?
      c.update_attributes(:imagelurl => l, :imagemurl => m, :imagesurl => s)
    }
  end

  task :init => :environment do 
  
    require 'rubygems'
    require 'amazon_ecs'
    include Amazon
    require 'open-uri'
    #require 'net/http'
    include AmazonScraper
    
    $amazonmodel = AmazonPrinter
    $model = Printer
    
    Amazon::Ecs.options = {:aWS_access_key_id => '0NHTZ9NMZF742TQM4EG2', :aWS_secret_key => 'WOYtAuy2gvRPwhGgj0Nz/fthh+/oxCu2Ya4lkMxO'}

    AmazonID =   'ATVPDKIKX0DER'
    AmazonCAID = 'A3DWYIK6Y9EEQB'  
  end

end