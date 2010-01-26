# encoding: utf-8
module AmazonScraper
  
  # Detail page url from local_id and region
  def id_to_details_url local_id, region
    return "#{get_base_url(region)}/gp/product/#{local_id}"
  end
  
  # Sponsored link url from local_id and region
  def id_to_sponsored_link local_id, region, merchant=nil
    merchant_str = "&m="+merchant if merchant
    return "#{get_base_url(region)}/gp/product/#{local_id}?tag=#{region=="us" ? "optemo-20" : "laserprinterh-20"}#{merchant_str}"
  end
  
  # Base url from region
  def get_base_url region
    return "http://www.amazon.#{region=="us" ? "com" : region}"
  end
  
  # All local ids from region
  def scrape_all_local_ids region
    announce "[#{Time.now}] Getting a list of all Amazon IDs associated with #{$model}s. This may take a while"
    
    cachefile = open_cache(curr_retailer(region))
    nokocache = Nokogiri::HTML(cachefile)
    added = nokocache.css('item/asin').collect{|x| x.content}
    announce "[#{Time.now}] Done getting Amazon IDs!"
    
    return added.reject{|x| x.nil? or x == ''}
  end
  
  # Amazon-specific cleaning code
  def clean atts
    atts['listprice'] = (atts['listprice'] || '').match(/\$\d+\.(\d\d)?/).to_s
    
    atts = clean_printer(atts) if $model == Printer
    atts = clean_cartridge(atts) if $model == Cartridge
    atts = clean_camera(atts) if $model == Camera
    
    unless atts['itemwidth'] and atts['itemheight'] and atts['itemlength']
      temp = no_blanks([atts['dimensions']]) #, "#{atts['itemwidth']} x #{atts['itemheight']} x #{atts['itemlength']}" ])  
      mergeme = clean_dimensions(temp,1) # Dimensions are in 100ths of inches already
      mergeme.each{ |key, val| atts[key] = val}
    end
    if (atts['toolow'] || '').to_s  == 'true' and atts['listprice'] and atts['listprice'] != ""
      atts['stock']    = true
      atts['pricestr'] = "Less than #{atts['pricestr']}"
      atts['salepricestr'] = "Less than #{atts['salepricestr']}"
    end
    
    if (atts['stock'] || '').to_s == 'false'
      # Check on site if actually out of stock
      ['price', 'priceint', 'pricestr', 'saleprice', 'salepriceint', 'salepricestr'].each{|x| atts['x'] = nil}
    elsif (atts['priceint'].nil? or atts['pricestr'].nil?)
      announce "WARNING: Nil price after cleaning atts for #{atts['local_id']}"
    end
    
    return atts
  end
  
  # Scrape product specs and offering info (prices,
  # availability) by local_id and region
  def scrape local_id, region
    log ("Scraping ASIN #{local_id} from #{region}" )
    specs = scrape_specs local_id
    prices = rescrape_prices local_id, region
    atts = specs.merge(prices)
    atts['local_id'] = local_id
    atts['region'] = region
    return atts
  end
  
  private
  
  #DO NOT CACHE THIS STUFF
  # Scrape product specs from feed
   def scrape_specs local_id
     begin
       res = Amazon::Ecs.item_lookup(local_id, :response_group => 'ItemAttributes,Images', :review_page => 1)
       be_nice_to_amazon
     rescue Exception => exc
       report_error "Could not scrape #{local_id} data"
       report_error "#{exc.class.name} #{exc.message}"
       log_snore(120) 
       return {}
     else
       nokodoc = Nokogiri::HTML(res.doc.to_html)
       item = nokodoc.css('item').first
       if item
         detailurl = item.css('detailpageurl').first.content
         atts = {}

         temphash = {}
         item.xpath('itemattributes/*').each do |x| 
           temphash[x.name] = (temphash[x.name] || []) + [x.content]
         end
         temphash.each do |k, v|
           atts[k] = combine_for_storage(v)
         end

         item.css('itemattributes/itemdimensions/*').each do |dim|
           temp = (dim.attributes['units'] || '').to_s.strip
           case temp
           when 'inches'
             atts["item#{dim.name}"] =( dim.text.to_f*100).to_i
           when 'cm'
             report_error "WARNING: dimensions in cm! Don't know how to handle"
           else # assume it's in hundreths of inches
             atts["item#{dim.name}"] = dim.text.to_i
           end
         end

         atts['imageurl'] = get_text(item.css('largeimage/url'))

         (atts['specialfeatures'] || '').split('|').each do |x| 
           pair = x.split('^')
           next if pair.length < 2
           name = just_alphanumeric("#{pair[0]}")
           val = "#{pair[1]}"
           next if name.strip == '' or val.strip == ''
           if atts[name]
           	vals = combine_for_storage(separate(atts[name]) + [val])
           else
           	vals = val
           end
           atts.merge!(name => vals)
         end
         return atts
       end
     end
     return {}
   end
  
  # Find the offering with the lowest price
  # for a given asin and region. 
  # precondition -- $retailers should only
  # contain one retailer per region
  def scrape_best_offer asin, region, nokocache=nil
    ret = curr_retailer(region)
    nokocache = Nokogiri::HTML(open_cache(ret)) unless nokocache
    item = nokocache.css("item").reject{|x| get_text(x.css('asin')) != asin}.first
    if item
      offers = item.css('offers/offer')
      unless ret.name.match(/marketplace/i)
         debugger if offers.length > 1
         return offers.first if offers.length > 0
         return nil
      end
      #bestprice ||= item.css('offersummary/lowestnewprice/*')
      offers.each do |o| 
        temp = get_text(o.css('merchant/merchantid'))
        next if decipher_retailer(temp,region) != ret.name
        debugger
        0
        return o
      end
    end
    return nil
  end

  # Returns retailer name by region.
  # precondition -- $retailers should only
  # contain one retailer per region
  def curr_retailer(region)
    return $retailers.reject{|x| x.region != region}.first
  end
  
  # Gets a hash of attributes for the
  # best-priced offer for a given
  # asin in the given region
  def rescrape_prices asin, region
    offer_atts = {}
    best = scrape_best_offer(asin, region)
    
    if best.nil?
      offer_atts['stock'] = false
    else
      offer_atts = offer_to_atthash( best, asin, region)
    end   
    
    clean_prices!(offer_atts)
    return offer_atts
  end
  
  # Gets at all the data in an offering item
  # as it is in the feed and puts it into
  # a hash of {attribute => att value}.
  def offer_to_atthash offer, asin, region
    atts = {'local_id' => asin, 'region' => region.downcase}
    atts['pricestr'] = offer.css('offerlisting/price/formattedprice').text
    
    if get_text(offer.css('offerlisting/price/formattedprice')) == 'Too low to display'
        atts['toolow']   = true
        #atts['stock'] = false
        #TODO atts['pricestr'] = scrape_hidden_prices(asin,region)
    else
        atts['toolow']   = false
        atts['pricestr'] = get_text(offer.css('offerlisting/price/formattedprice'))
        atts['stock']    = true
    end
    
    atts['availability'] = get_text(offer.css('offerlisting/availability'))
    atts['availability'] = 'In stock' if (atts['availability'] || '').match(/out of stock/i) 
   
    atts['merchant']     = get_text(offer.css('merchant/merchantid'))
    
    atts['condition'] = get_text(offer.css('condition'))
    
    atts['url'] = id_to_sponsored_link(asin, region, atts['merchant'])
    atts['iseligibleforsupersavershipping'] = get_text(offer.css('offerlisting/iseligibleforsupersavershipping'))
    return atts
  end

  # Scrapes prices which are too low
  # to be displayed
  # TODO -- can I get this from the feed?
  def scrape_hidden_prices(asin,region)
    require 'open-uri'
    require 'nokogiri'
    url = "http://www.amazon.#{region=="us" ? "com" : region}/o/asin/#{asin}"
    log_snore(15)
    doc = Nokogiri::HTML(open(url))
    price_el = get_text(doc.css('.listprice'))
    price = price_el.text unless price_el.nil?
    return price
  end
  
  def parse_review result
    reviews = {}
    reviews["averagereviewrating"] = result.get('averagerating')
    reviews['totalreviews'] = result.get('totalreviews').to_i
    temp = result.search_and_convert('review')
    temp = Array(temp) unless reviews.class == Array #Fix single and no review possibility
    mytext = temp.collect{|x| "#{x.get('date')} -- #{x.get('summary')}. #{x.get('content')} "}.join(' || ')
    reviews['reviewtext'] = mytext
    return reviews
  end

  # TODO 1. this is not used anywhere
  # and 2. it probably needs to be re-written 
  # because it won't do as it implies
  def scrape_review asin
    reviews = {}
    begin
        res = Amazon::Ecs.item_lookup(asin, :response_group => 'Reviews', :review_page => 1)
        be_nice_to_amazon
    rescue Exception => exc
        report_error " --  #{exc.message}. Couldn't download reviews for product #{asin}"
    else
        result = res.first_item
        if result
          reviews = parse_review(result)
        end
    end
    
    return reviews
  end

  # TODO 1. this is not used anywhere
  # and 2. it probably needs to be re-written 
  # because it won't do as it implies
  def scrape_reviews asin, retailer_id
    reviews = []
    #averagerating,totalreviews,totalreviewpages = nil
    totalreviewpages = nil
    current_page = 1
    loop do
      begin
        res = Amazon::Ecs.item_lookup(asin, :response_group => 'Reviews', :review_page => current_page)
        be_nice_to_amazon
      rescue Exception => exc
        report_error "Couldn't download reviews for product #{asin}"
        report_error "#{exc.class.name} #{exc.message}"
      else
        nokodoc = Nokogiri::HTML(res.doc.to_html)
        result =  nokodoc.css('item').first
        #Look for old Retail Offering
        unless result.nil?
          averagerating ||= result.css('averagerating').text
          totalreviews ||= result.css('totalreviews').text.to_i
          totalreviewpages ||= result.css('totalreviewpages').text.to_i
          if totalreviews == 0
            log "#{$model.name} #{asin} has no reviews -- 0 min remaining"
            return [{'totalreviews' => totalreviews}]
          end
          log "#{$model.name} #{asin} review download: less than #{(totalreviewpages-current_page)/6 + 1} min remaining..." if current_page % 10 == 1
          temp = result.css('review')
          temp = Array(temp) unless reviews.class == Array # Fix single and no review possibility
          array_of_hashes = temp.collect{|x| x.css('*').inject({}){|r,y| r.merge({y.name => y.text})}}
          named_array_of_hashes = []
          array_of_hashes.each{ |hash|
              named_hash = {}
              hash.each{|k,v| 
                new_k = get_property_name(k,Review, ['id'])
                named_hash[new_k] = v 
              }
              named_hash['totalreviews'] = totalreviews # TODO can this be done automatically?
              named_hash['averagereviewrating'] = averagerating # TODO can this be done automatically?
              named_array_of_hashes << named_hash
          }
          reviews = reviews + named_array_of_hashes
        else
          report_error "Reviews result nil for product #{asin}"
          return reviews
        end
      end
      current_page += 1
      break if totalreviewpages and current_page > totalreviewpages # In case there is a bad request, break loop
    end
    
    return reviews
  end

  # Cleans attributes if they belong
  # to an Amazon printer
  def clean_printer atts
    atts['cpumanufacturer'] = nil # TODO hacky
    temp1 = ((atts['feature'] || '') +'|'+ (atts['specialfeatures'] || '')).force_encoding('UTF-8')
    temp2 = temp1.split(/¦|\|/)
    temp3 = temp2.collect{|x| separate(x)}.flatten
    temp3.each do |x| 
        temp_ppm =  get_ppm(x)
        temp_paperin = parse_max_num_pages(x)
        temp_res = x.match(/(res|\d\s?x\s?\d)/i)
        if temp_ppm
          atts['ppm'] ||= temp_ppm
        elsif temp_paperin and x.match(/(input|feed)/i)
          atts['paperinput'] ||= temp_paperin
        elsif temp_res
          temp_res_2 = parse_dpi(x)
          atts['resolution'] ||= temp_res_2
        end
    end
    semi_cleaned_atts = clean_property_names(atts) 
    semi_cleaned_atts['displaysize'] = nil # TODO it's just a weird value
    cleaned_atts = generic_printer_cleaning_code semi_cleaned_atts
    temp1 = clean_brand atts['title'], $printer_brands
    temp2 = clean_brand atts['brand'], $printer_brands
    cleaned_atts['brand'] = temp1 || temp2
    #cleaned_atts['condition'] ||= 'New'
    atts['resolutionmax'] = get_max_f(atts['resolution']) if atts['resolution']
    return cleaned_atts
  end
  
  # Cleans attributes if they belong
  # to an Amazon printer cartridge
  def clean_cartridge atts
    cleaned_atts = cartridge_cleaning_code atts
    
    init_brands
    init_series
        
    cleaned_atts['realbrand'] = clean_brand(cleaned_atts['brand'], $fake_brands+$real_brands)
    cleaned_atts['compatiblebrand'] = clean_brand(cleaned_atts['title'])
    cleaned_atts['real'] = same_brand?(cleaned_atts['realbrand'], cleaned_atts['compatiblebrand'])
    cleaned_atts['toner'] = true if (cleaned_atts['title'] || '').match(/toner/i) 
    cleaned_atts['toner'] = false if (cleaned_atts['title'] || '').match(/ink/i) 
    
    conditions = ['Remanufactured', 'Refurbished', 'Compatible', 'OEM', 'New']
    conditions.each do |c| 
      (cleaned_atts['condition'] = c) and break if (cleaned_atts['title'] || '').match(/#{c}/i)
    end
    
    cleaned_atts['compatible'] = cleaned_atts['feature'] + "#{cleaned_atts['compatible']}" if cleaned_atts['feature']
    return cleaned_atts
  end
  
  def clean_camera atts
    semi_cleaned_atts = clean_property_names(atts) 
    cleaned_atts = product_cleaner(semi_cleaned_atts)
    res_array = separate(cleaned_atts['resolution'] || '')
    mpix = to_mpix(parse_res(cleaned_atts['title']))
    mpix ||= res_array.collect{ |x| to_mpix(parse_res(x)) }.reject{|x| x.nil?}.max    
    mpix = mpix / 1_000_000.0 if (mpix and mpix > 100)
    cleaned_atts['maximumresolution'] = mpix if mpix
    remove_sep!(cleaned_atts)
    rearrange_dims!(cleaned_atts, ['D', 'H', 'W'], true)
    # TODO the following is hacky.
    cleaned_atts['displaysize'] = nil if ['0', '669.2913385827'].include?(cleaned_atts['displaysize'] || '').to_s
    return cleaned_atts
  end
  
  # Converts Amazon's cryptic merchant ID to
  # a String which will match a retailer name
  def decipher_retailer merchantid, region
    case merchantid 
      when AmazonID 
        return "Amazon"
      when AmazonCAID
        return "Amazon.ca"
      else
        case region
        when "us"
          return "Amazon Marketplace"
        when "ca"
          return "Amazon.ca Marketplace"
        end
    end
  end
  
  # Wait between requests.
  def be_nice_to_amazon
     sleep(1+rand()*30)
  end
  
  # CACHING
  
  def get_merchant_str retailer_name
    merchant_searchstring = nil
    merchant_searchstring = AmazonID if retailer_name == 'Amazon'
    merchant_searchstring = AmazonCAID if retailer_name == 'Amazon.ca'
    return merchant_searchstring
  end
  
  def cachefile_name(retailer)
    return "./cache/#{retailer.name.gsub(/(\s|\.)/,'_').downcase}_#{$model.name.downcase}.html"
  end
  
  def open_cache(retailer)
    cfname = cachefile_name(retailer)
    if(!File.exists?(cfname) or ((Time.now-File.mtime(cfname)).to_i/3600 > 12) )
      refresh_cache(retailer)
    end
    return File.open(cfname, 'r') if File.exists?(cfname)
    return nil
  end
  
  def refresh_cache(retailer)
    cachefile = File.open(cachefile_name(retailer), 'w')
    # params for the request...
      merch = get_merchant_str(retailer.name) || 'All'
      bnode = browse_node_id(retailer.region, $model)
      place = retailer.region.intern
    current_page = 1
    loop do
      begin
        res = Amazon::Ecs.item_search('',:browse_node => bnode, :search_index => $search_index, \
          :merchant_id => merch, :country => place, :response_group => 'Offers',\
          :item_page => current_page, :service => 'AWSECommerceService')
        be_nice_to_amazon
      rescue Exception => exc
        report_error "Couldn't download Offers for page #{current_page}"
        report_error "#{exc.class.name} #{exc.message}"
      else
        if(res)
          totalpages ||= res.total_pages
          nokodoc = res.doc.to_html
          cachefile.puts("#{nokodoc}")
        end      
      end
      timed_announce "Done #{current_page} of #{totalpages} pages"
      current_page += 1
      break if totalpages and current_page > totalpages # In case there is a bad request, break loop
    end
    cachefile.close
  end
  
  def browse_node_id region, model=$model
    case model.name
      when 'Printer'
        if region.downcase == 'ca'
          return '677265011'
        else 
          return '172648'
        end
      when 'Camera'
        if region.downcase == 'ca'
          return '677235011'
        else 
          return '330405011'
        end
      when 'Cartridge'
        return '172641'
    end
  end
  
end  
 #  res = Amazon::Ecs.item_search('',:browse_node => bn, :search_index => $search_index,\
 # :merchant_id => merchant_searchstring, :country => reg, \ #:availability => 'Available', #  :condition => 'New', 
 #  :response_group => 'Offers', :item_page => current_page, :service=> 'AWSECommerceService')