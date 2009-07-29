module BestBuyScraper
  
  def get_matching_sets
    matching_sets = []
    
    Camera.all.each do |bbc|
       matches = match_printer_to_printer bbc, $model, $series
        if matches.length > 1
          matching_sets << matches.collect{|x| x.id }.sort
        end
    end
    
    return matching_sets.uniq!
  end
  
  def copy_spec_from_valid validid, matchingidset
    validrec = $model.find(validid)
    
    matchingidset.each do |matchingid|
      match = $model.find(matchingid)
      fill_in_all validrec.attributes, match, $ignoreme
    end
  end
    
  def copy_specs
    matching_sets = get_matching_sets
    valid_ids = Camera.valid.collect{ |x| x.id}
    matching_sets.each do |set|
      valids = set.reject{ |x| !valid_ids.include? x }
      if valids.size != set.size and valids.size > 0
        copy_spec_from_valid valids[0], set
      end
    end
  end  
    
  def clean_model_str model, brand
    return nil if model == nil
    clean_model = model.gsub(/camera/i,'')
    clean_model.gsub!(/d?slr/i,'')
    clean_model.gsub!(/digital/i, '')
    clean_model.gsub!(/ \d+(\.\d+)?\s?m(ega)?p(ixel(s)?)?/i,'')
    clean_model.gsub!(/#{brand}/i,'')
    clean_model.strip!
    return clean_model
  end
  
  def properly_formed_model_str mdl
     return false if mdl.nil? or mdl == ""
     return false if mdl.split(' ').reject{|x| x=='' or x.nil? or $series.include?(just_alphanumeric(x))}.length == 0
     return true
  end
  
  def get_model_from_str str, brand
    dirty_model = str.match(/#{brand} .+? \d+(\.\d+)?\s?m(ega)?p(ixel(s)?)?/i).to_s
    returnme = clean_model_str(dirty_model, brand)
    if !properly_formed_model_str returnme
      dirty_model = str.match(/#{brand} .+? (d(igital\s)?slr|camera)/i).to_s
      returnme = clean_model_str(dirty_model, brand)
    end
    if !properly_formed_model_str returnme
      dirty_model = (str.match(/\(.+?\)/i).to_s || '').to_s.gsub(/[\(\)]/,'')
      returnme = clean_model_str(dirty_model, brand)
    end
    
    return returnme  if properly_formed_model_str(returnme)
    return nil
  end
  
  def clean atts
    atts['producttype'] = $model.to_s
    atts['brand'].capitalize!
    
    atts['slr'] = !atts['category'].match(/s(ingle )?l(ens )?r(eflex )?/i).nil?
    
    atts['maximumresolution'] = to_mpix(parse_res(atts['effectivepixels'] || atts['megapixels'] || atts['title']))
    
    atts['displaysize'] = get_inches(atts['lcdmonitor'] )
    atts['displaysize'] = get_inches(atts['lcdsize']) unless atts['displaysize']
    
    atts['listpricestr'] = get_price_s( get_f(atts['price']))
    atts['listpriceint'] = get_price_i( get_f atts['price'] )
    
    atts['price']    = get_price_i( get_f(atts['saleprice'])) || atts['listpriceint']
    atts['pricestr'] = get_price_s( get_f(atts['saleprice'])) || atts['listpricestr']
    
    atts['itemweight'] = to_grams( parse_weight( atts['weight'] || atts['weightwithbatteries'] ))
    
    dims = ['depth', 'height', 'width']
    dims.each do |dim|
      atts["item#{dim}"] = to_cm(parse_metric_length(atts["#{dim}"] || atts["dimensions#{dim}"]))
    end
    atts['itemlength'] = atts['itemdepth']
    
    # Scrape description
    lookhere = atts['description'] + " " + atts['longdescription'] + " " + atts['title']
    if atts['displaysize'].nil?
      
      atts['displaysize'] = get_inches( lookhere.match(/\d.+?(lcd|monitor|display|screen)/i).to_s )
    end
    
    if atts['maximumresolution'].nil? or atts['maximumresolution'] == 0
      atts['maximumresolution'] = to_mpix(parse_res(atts['title'] + atts['description']))
    end
    
    atts['model'] = get_model_from_str atts['title'], atts['brand']
    
    atts['opticalzoom'] = parse_lens(atts['focallength'] || atts['35mmequivalent']) if atts['opticalzoom'].nil?
    atts['opticalzoom'] = parse_ozoom(lookhere) if atts['opticalzoom'].nil?
    atts['opticalzoom'] = parse_lens(atts['label']) if atts['opticalzoom'].nil?
    atts['opticalzoom'] = 1 if atts['opticalzoom'].nil? and atts['slr']
    
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
    
end

namespace :scrape_bestbuy do
  
  desc 'Download & resize all picture files'
  task :get_pix => :init do
    require 'scraping_helper'
    include ScrapingHelper
    require 'RMagick'
    require 'image_helper'
    include ImageHelper
    
    urls = {}
    Camera.all.each{|x| urls[x.skuid]= x.imageurl }
    
    failed = download_all_pix urls
    puts " Num Failed: #{failed.size}"

    puts "Resizing.."
    failed = resize_all urls.keys
    
    puts " Num Failed: #{failed.size}"
    record_pic_stats Camera.all
  end
  
  desc 'Download & resize all picture files'
  task :update_pix => :init do
    require 'scraping_helper'
    include ScrapingHelper
    require 'RMagick'
    require 'image_helper'
    include ImageHelper
    
    picless = picless_recs
    unresized = unresized_recs
    urls = picless.each{|x| urls[x.skuid]= x.imageurl }
    
    puts "Downloading #{urls.length} missing pictures"
    failed = download_all_pix urls
    puts " Num Failed: #{failed.size}"

    puts "Resizing #{urls}"
    failed = resize_all unresized.collect{|x| x.skuid}
    puts " Num Failed: #{failed.size}"
    
    puts "Recording pic stats"
    record_pic_stats Camera.all
    
    puts "Done"
  end
  
  desc 'Update scraped data'
  task :update_data => :init do 
    
  end
  
  desc 'Scrape all data from scratch from the rss feeds.'
  task :scrape_all => :init do 
     
      feeds = ["scrape_me/bestbuy/CameraAndCamcorder.xml", "scrape_me/bestbuy/Computers.xml", "scrape_me/bestbuy/TVandVideo.xml"]

      feeds.each do | feed |
        rss = Nokogiri::XML(open(feed))
        products = filter_items rss.css('item').to_a

        products.each do |item|
           
           # Scrape
           params = scrape_item item
           
           # Clean
           params.delete_if{|x,y| y.nil?}.each{ |k,v| params.store( @bestbuy_properties[k] || k, v )  }
           params = clean(params)
           
           bbc = Camera.find_or_create_by_skuid(params['skuid'])
           fill_in_all params, bbc
           
        end
      end
     
  end
  
  desc 'Adds more data to scraped data'
  task :supplement => [:copy_specs,:scrape_website, :copy_specs]
  
  task :copy_specs => :init do
    copy_specs
  end
  
  task :scrape_website => :init do
    
    (Camera.all - Camera.valid).each do |invalid|
      page = Nokogiri::HTML(open(invalid.detailpageurl))
      if page.css('div.pdp_product_container').length > 0
        page.css('div.pdp_product_container').each do |product|
          links = product.css('div.desc_box a')
          links.each do |link|
            if (( invalid.model and link.content.include?(invalid.model)) or link.content.include?('Camera'))
              page = Nokogiri::HTML(open(link.[]('href').to_s))
              break
            end
          end
        end
      end
      dispsize =  get_inches( page.css('#tabbedcontentbox').text.match(float_and_regex(/.*?(lcd|monitor|display|screen)/i)).to_s )
      dispsize = get_f( page.css('#tabbedcontentbox').text.match(float_and_regex(/..(lcd|monitor|display|screen)/i)).to_s ) unless dispsize
      model = clean_model_str(page.css('.pdpsummarybox').text, invalid.brand)
      
      fill_in 'displaysize', dispsize, invalid
      fill_in 'model', model, invalid unless invalid.model
      sleep(20)
    end
    
  end
  
  task :validate => :init do
    matching_sets = get_matching_sets
    
    valid_ids = Camera.valid.collect{ |x| x.id}
    
    matching_sets.each do |set|
      validity = set.collect { |x| valid_ids.include? x }
      puts " None of #{set} valid" if !validity.include?(true)
    end
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
    
    $imgfolder= 'bestbuy'
        
    $ignoreme= ['opticalzoom', 'digitalzoom', 'pricestr', 'price', 'skuid', 'fsskuid', 'listpriceint', 'listpricestr']
    
    $series = ['exilim', 'powershot', 'alpha', 'finepix', 'insignia', 'stylus','eos', 'cybershot', 'rebel']
    
    $id_field = 'skuid'
    
    feeds_urls = ["http://www.bestbuy.ca/rssfeeds/GetProductsFeedForCameraandCamcorders.aspx",\
       " http://www.bestbuy.ca/rssfeeds/GetProductsFeedForComputers.aspx", " http://www.bestbuy.ca/rssfeeds/GetProductsFeedForTVandVideo.aspx"]
    
    $feeds_local = ["scrape_me/bestbuy/CameraAndCamcorder.xml", "scrape_me/bestbuy/Computers.xml", "scrape_me/bestbuy/TVandVideo.xml"]
        
    include BestBuyScraper
    @bestbuy_properties = {'title' => 'label', 'mfgpartnum' => 'mpn', 'mfrpartnumber' => 'mpn', \
      'link' => 'detailpageurl', 'manufacturer' => 'brand', 'modelnumber' => 'model', 'provincecode' => 'state',\
      'redeyereductionflashmode' => 'hasredeyereduction', 'includedbatterymodel' => 'batterydescription'}
      
    $feeds_local.each do |feed| 
      file = 
      #file.stat.mtime
    end
  end
  
end