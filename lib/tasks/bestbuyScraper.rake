module BestBuyScraper
  
  def clean atts
    atts['producttype'] = $model.to_s
    
    atts['slr'] = !atts['category'].match(/s(ingle )?l(ens )?r(eflex )?/i).nil?
    
    atts['maximumresolution'] = to_mpix(parse_res(atts['totalpixels'] || atts['megapixels'] || atts['title']))
    
    atts['displaysize'] = get_inches(atts['lcdmonitor'] )
    atts['displaysize'] = get_inches(atts['lcdsize']) unless atts['displaysize']
    
    atts['listpriceint'] = get_price_i( get_f atts['price'] )
    atts['listpricestr'] = get_price_s(get_f(atts['price']))
    
    atts['itemweight'] = to_grams( parse_weight( atts['weight'] || atts['weightwithbatteries'] ))
    
    dims = ['depth', 'height', 'width']
    dims.each do |dim|
      atts["item#{dim}"] = to_cm(parse_metric_length(atts["#{dim}"] || atts["dimensions#{dim}"]))
    end
    atts['itemlength'] = atts['itemdepth']
    
    # Scrape description
    lookhere = atts['description'] + " " + atts['longdescription'] + " " + atts['title']
    if atts['displaysize'].nil?
      atts['displaysize'] = get_f( lookhere.match(append_regex(ConversionHelper.float_rxp, /(in(ch(es)?)? |\").*?lcd/i)).to_s )
    end
    
    if atts['maximumresolution'].nil? or atts['maximumresolution'] == 0
      atts['maximumresolution'] = to_mpix(parse_res(lookhere))
    end
    
    unless atts['brand'].nil? or atts['brand'].empty?
      dirty_model = atts['label'].match(/#{atts['brand']} .+? \d+(\.\d+)?\s?MP/i).to_s.split(' ')
      dirty_model = atts['label'].match(/#{atts['brand']} .+? d(igital\s)?slr/i).to_s.split(' ') if dirty_model.length < 3
      if dirty_model.length > 2
        atts['model'] = dirty_model[1..(dirty_model.length-2)].join(' ') 
      else
        atts['model'] = (atts['label'].match(/\(.+?\)/i).to_s || '').to_s.gsub(/[\(\)]/,'')
      end
      atts['model'].gsub!(/\sdigital/i, '')
    end
    
    atts['opticalzoom'] = parse_lens(atts['focallength'] || atts['35mmequivalent'])
    atts['opticalzoom'] = parse_ozoom(lookhere) if atts['opticalzoom'].nil?
    atts['opticalzoom'] = parse_lens(atts['label']) if atts['opticalzoom'].nil?
    atts['opticalzoom'] = 1 if atts['opticalzoom'] == 0 or atts['category']=='DSLR Packages'
    atts['digitalzoom'] = 1 if atts['digitalzoom'] == 0
    
    return atts
  end

  def scrape_item item
    params = {}
    item.children.each do |el|
      params[just_alphanumeric(no_leading_spaces(el.name))] = no_leading_spaces(el.text) unless el.name == 'ItemSpecs'
    end
    params.merge!( scrape_table item.xpath('FS:ItemSpecs').css('ATT'), 'ATT_NAME', 'ATT_VALUE' )
    item.css('IA').first.attributes.each {|x,y| params[just_alphanumeric(no_leading_spaces(x.to_s))]=no_leading_spaces(y.to_s)}
    
    return params
  end
  
  def filter_items products
    
    ok_category = ["Get Camera and Camcorders products", "Digital Camera Kits", "Stylish & Compact", "DSLR Packages", \
      "DSLR Cameras", "Basic Point and Shoot", "Waterproof", "Ultra Zoom", "Advanced Compact"]
    # Only digital cameras
    products.delete_if{ |item| 
      item.xpath('FS:CatDept').first.text != "Digital Cameras" or !ok_category.include?(item.css('category').text.to_s.strip )
    }
    return products
  end
  
  def all_duplicates
    matching_sets = []
    
    BestBuyCamera.all.each do |bbc|
       matches = match_printer_to_printer bbc, BestBuyCamera  
       if matches.length > 1
         matching_sets << matches.collect{|x| x.id }.sort
       end
    end
    
    return matching_sets.uniq!
  end
  
end

namespace :scrape_bestbuy do
  
  desc 'asdf'
  task :scrape_all_products => :init do 
     
      feeds = ["scrape_me/bestbuy/CameraAndCamcorder.xml", "scrape_me/bestbuy/Computers.xml", "scrape_me/bestbuy/TVandVideo.xml"]
      careful = false

      feeds.each do | feed |
        rss = Nokogiri::XML(open(feed))
        products = filter_items rss.css('item').to_a

        products.each do |item|
           
           # Scrape
           params = scrape_item item
           
           # Clean
           
           params.delete_if{|x,y| y.nil?}.each{ |k,v| params.store( @bestbuy_properties[k] || k, v )  }
           params = clean(params)
           debugger if params['displaysize'].nil?
           # Find or create offering
           bbpo = BestBuyPilotOffering.find_or_create_by_skuid(params['skuid'])
           fill_in_all params, bbpo
           # Find or create camera
           
           makes = [just_alphanumeric(params['brand'])].delete_if{ |x| x.nil? or x == ""}
           models = [just_alphanumeric(params['model'])].delete_if{ |x| x.nil? or x == ""}
           matches = match_rec_to_printer makes, models, BestBuyCamera
                      
           if matches.length == 0
             bbc = create_product_from_atts params, BestBuyCamera
           else
             # bbc = matches[0]
             #debugger if params['opticalzoom'].nil?]
             bbc = create_product_from_atts params, BestBuyCamera
             matches.each do |m|
              fill_in_all m.attributes, bbc, $ignoreme
              fill_in_all params, m, $ignoreme
            end
           end
           
           fill_in 'bb_camera_id', bbc.id, bbpo
           
        end
      end
     
  end
  
  desc 'Old scrape'
  task :old_scrape => :init do
    possible_params = []
     feeds = ["scrape_me/bestbuy/CameraAndCamcorder.xml", "scrape_me/bestbuy/Computers.xml", "scrape_me/bestbuy/TVandVideo.xml"]
     careful = false
     
     feeds.each do | feed |
       rss = Nokogiri::XML(open(feed))
      
       # Array of rss feed items
       products = filter_items rss.css('item').to_a
       products.each do |item|
          params = scrape_item item
          #possible_params << params.keys
          params.delete_if{|x,y| y.nil?}.each{ |k,v| params.store( @bestbuy_properties[k] || k, v )  }
          params = only_overlapping_atts((clean params), BestBuyCamera)
          x = BestBuyCamera.find_or_initialize_by_skuid(params['skuid'])
          fill_in_all params, x
          sleep(20) if careful
       end
     end
          
     #puts possible_params.flatten.sort.uniq
  end
  
  desc 'Re-scrape from the web if the item is missing key values'
  task :supplementary_scrape => :init do
    
    
    
  end
  
  desc 'Is at least 1 in a set of duplicates valid?'
  task :validate => :init do
    matching_sets = all_duplicates
    
    valid_ids = BestBuyCamera.valid.collect{ |x| x.id}
    
    matching_sets.each do |set|
      validity = set.collect { |x| valid_ids.include? x }
      puts " None of #{set} valid" if !validity.include?(true)
    end
  end
  
  desc 'find duplicates'
  task :duplicates => :init do
    
    @logfile = File.open("./log/bestbuy_duplicates.log", 'w+')
    
    matching_sets = []
    
    BestBuyCamera.all.each do |bbc|
       matches = match_printer_to_printer bbc, BestBuyCamera  
       if matches.length > 1
         matching_sets << matches.collect{|x| x.id }.sort
         @logfile.puts "Matched more than one for #{bbc.id}: "
         @logfile.puts matches.collect{|x| x.id } * ', '
       end
       
    end
    
    @logfile.puts " All matching sets:"
     matching_sets.uniq!
     @logfile.puts matching_sets
     @logfile.puts "#{matching_sets.flatten.length} items in #{matching_sets.length} sets"
    @logfile.close
  end
  
  task :init => :environment do
    require 'Nokogiri'
    
    require 'scraping_helper'
    include ScrapingHelper
    
    require 'conversion_helper'
    include ConversionHelper
    
    require 'database_helper'
    include DatabaseHelper
     
    $model = Camera 
        
    $ignoreme= ['opticalzoom', 'digitalzoom', 'listpricestr', 'listpriceint', 'skuid', 'fsskuid']
        
    include BestBuyScraper
    @bestbuy_properties = {'title' => 'label', 'mfgpartnum' => 'mpn', 'mfgpartnumber' => 'mpn', \
      'link' => 'detailpageurl', 'manufacturer' => 'brand', 'modelnumber' => 'model', 'provincecode' => 'state',\
      'redeyereductionflashmode' => 'hasredeyereduction', 'includedbatterymodel' => 'batterydescription'}
  end
  
end