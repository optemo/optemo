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
    
    puts "[#{Time.now}] Getting a list of all Amazon IDs associated with #{$model}s. This may take a while"
    
    current_page = 1
    count = 0
    added = []
    loop do
      begin
        res = Amazon::Ecs.item_search('',:browse_node => $browse_node_id, :search_index => $search_index, :response_group => 'ItemIds', :item_page => current_page)# , :country => region.intern
        be_nice_to_amazon
      rescue Exception => exc
        report_error "Problem while getting local ids, on #{current_page}th page of request."
        report_error "#{exc.message}"
        snore(10)
        current_page += 1
      else
        report_error "#{res.error}. Couldn't download ASINs for page #{current_page}" if  res.has_error?    
        total_pages = res.total_pages unless total_pages
        added += res.items.collect{ |item| item.get('asin') }
        current_page += 1
      end
      puts "[#{Time.now}] Read #{current_page-1} pages..."
      break if (current_page > total_pages) #or current_page > 5) # <-- For testing only!
    end
    
    puts "[#{Time.now}] Done getting Amazon IDs!"
    
    return added.reject{|x| x.nil? or x == ''}
  end
  
  # Amazon-specific cleaning code
  def clean atts
    atts['listprice'] = (atts['listprice'] || '').match(/\$\d+\.(\d\d)?/).to_s
    
    atts = clean_printer(atts) if $model == Printer
    atts = clean_cartridge(atts) if $model == Cartridge
    atts = clean_camera(atts) if $model == Camera
    
    if (atts['toolow'] || '').to_s  == 'true' and atts['listprice'] and atts['listprice'] != ""
      atts['stock']    = true
      atts['pricestr'] = "Less than #{atts['pricestr']}"
      atts['salepricestr'] = "Less than #{atts['salepricestr']}"
    end
    
    if (atts['stock'] || '').to_s == 'false'
      #debugger
      # Check on site if actually out of stock
      ['price', 'priceint', 'pricestr', 'saleprice', 'salepriceint', 'salepricestr'].each{|x| atts['x'] = nil}
    elsif (atts['priceint'].nil? or atts['pricestr'].nil?)
      #debugger # Should never happen
      puts "Price is nil?!?!? HOW DID THIS HAPPEN" # TODO 
      0
    end
    
    atts['resolutionmax'] ||= maxres_from_res(atts['resolution']) if atts['resolution']
    
    return atts
  end
  
  # Re-scrape everything needed to update an offering
  def rescrape_prices local_id, region
    return scrape_offer local_id, region
  end
  
  # Scrape product specs and offering info (prices,
  # availability) by local_id and region
  def scrape local_id, region
    log ("Scraping ASIN #{local_id} from #{region}" )
    specs = scrape_specs local_id
    prices = scrape_offer local_id, region
    atts = specs.merge(prices)
    atts['local_id'] = local_id
    atts['region'] = region
    
    return atts
  end
  
  private
  
  # Scrape product specs from feed
  def scrape_specs local_id
    res = Amazon::Ecs.item_lookup(local_id, :response_group => 'ItemAttributes,Images', :review_page => 1)
    be_nice_to_amazon
    
    nokodoc = Nokogiri::HTML(res.doc.to_html)
    item = nokodoc.css('item').first
    if item
      detailurl = item.css('detailpageurl').first.content
      atts = item.xpath('itemattributes/*').inject({}){|r,x| 
        val = x.content
        val += "#{CleaningHelper.sep} #{r[x.name]}" if r[x.name]
        r.merge(x.name => val)
      }
      item.css('itemattributes/itemdimensions/*').each do |dim|
        atts["item#{dim.name}"] = dim.text.to_i
      end
      
      temp = get_el item.css('largeimage/url')
      atts['imageurl'] = temp.content if temp
      
      (atts['specialfeatures'] || '').split('|').each do |x| 
        pair = x.split('^')
        next if pair.length < 2
        name = just_alphanumeric("#{pair[0]}")
        val = "#{pair[1]}"
        next if name.strip == '' or val.strip == ''
        val += "#{CleaningHelper.sep} #{atts[name]}" if atts[name]
        atts.merge!(name => val)
      end      
      
      return atts
    end
    return {}
  end
  
  # Find the offering with the lowest price
  # for a given asin and region. 
  # precondition -- $retailers should only
  # contain one retailer per region
  def scrape_best_offer asin, region
    lowestprice = 1000000000
    lowoffer = nil
    
    merchant_searchstring = 'All'
    merchant_searchstring = AmazonID if curr_retailer(region).name == 'Amazon'
    merchant_searchstring = AmazonCAID if curr_retailer(region).name == 'Amazon.ca'
    
    current_page = 1    
    begin
      begin
        res = Amazon::Ecs.item_lookup(asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => merchant_searchstring, :offer_page => current_page, :country => region.intern)
        be_nice_to_amazon
      rescue Exception => exc
        report_error "#{exc.message} . Could not look up offers for #{asin} in region #{region}"
        snore(30) 
        return
      else
        total_pages = res.total_pages unless total_pages
        if res.first_item.nil?
          current_page += 1
          next
        end
        offers = res.first_item.search_and_convert('offers/offer')
        if offers.nil?
          current_page += 1
          next
        end
        offers = [] << offers unless offers.class == Array
        offers.each do |o| 
          # Their stock info is often wrong!
          #if o.get('offerlisting/availability').match(/out of stock/i) 
          #  debugger
          #  # Check that it's out of stock on the site?
          #  next
          #end
          price = o.get('offerlisting/price/formattedprice')
          if price.nil? or o.get('offerlisting/price').to_s.match(/too low/i)
            price = 0  # TODO scrape_hidden_prices(asin,region)
            #price = lowestprice # Do not use the too-low offerings!
          else
            price = get_min_f(price.to_s)
          end
          merchant = decipher_retailer(o.get('merchant/merchantid'), region)
          if price < lowestprice and merchant == (curr_retailer(region)).name
            lowestprice = price
            lowoffer = o
          end
        end
        current_page += 1
      end
    end while (!total_pages.nil? and current_page <= total_pages)
    return lowoffer
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
  def scrape_offer asin, region
    offer_atts = {}
    best = scrape_best_offer(asin, region)
    
    if best.nil?
      offer_atts['stock'] = false
    else
      offer_atts = offer_to_atthash best, asin, region
    end
    return offer_atts
  end
  
  # Gets at all the data in an offering item
  # as it is in the feed and puts it into
  # a hash of {attribute => att value}.
  def offer_to_atthash offer, asin, region
    atts = {}
    atts['pricestr'] = offer.get('offerlisting/price/formattedprice').to_s
    if offer.get('offerlisting/price/formattedprice') == 'Too low to display'
        atts['toolow']   = true
        atts['stock'] = false
        #TODO atts['pricestr'] = scrape_hidden_prices(asin,region)
    else
        atts['toolow']   = false
        atts['pricestr'] = offer.get('offerlisting/price/formattedprice')
        atts['stock']    = true
    end
    
    atts['availability'] = offer.get('offerlisting/availability')
    # TODO availability sometimes wrong!
   # debugger if atts['availability'].nil?
    atts['availability'] = 'In stock' if (atts['availability'] || '').match(/out of stock/i) 
    
   # debugger if (atts['availability'] || '').match(/out/i) 
    # Check against the website..
    
    atts['merchant']     = offer.get('merchant/merchantid')
    
    atts['url'] = "http://amazon.#{region=="us" ? "com" : region}/gp/product/"+asin+"?tag=#{region=="us" ? "optemo-20" : "laserprinterh-20"}&m="+atts['merchant']
    atts['iseligibleforsupersavershipping'] = offer.get('offerlisting/iseligibleforsupersavershipping')
     
    return atts
  end

  # Scrapes prices which are too low
  # to be displayed
  # TODO -- can I get this from the feed?
  def scrape_hidden_prices(asin,region)
    require 'open-uri'
    require 'nokogiri'
    url = "http://www.amazon.#{region=="us" ? "com" : region}/o/asin/#{asin}"
    snore(15)
    doc = Nokogiri::HTML(open(url))
    price_el = get_el(doc.css('.listprice'))
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
    
    #debugger
    
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
        report_error " #{exc.message}. Couldn't download reviews for product #{asin}"
      else
        nokodoc = Nokogiri::HTML(res.doc.to_html)
        result =  nokodoc.css('item').first
        #Look for old Retail Offering
        unless result.nil?
          averagerating ||= result.css('averagerating').text
          totalreviews ||= result.css('totalreviews').text.to_i
          totalreviewpages ||= result.css('totalreviewpages').text.to_i
          puts "#{$model.name} #{asin} review download: #{(totalreviewpages-current_page)/6} min remaining..." if current_page % 10 == 1
          temp = result.css('review')
          temp = Array(temp) unless reviews.class == Array #Fix single and no review possibility
          array_of_hashes = temp.collect{|x| x.css('*').inject({}){|r,y| r.merge({y.name => y.text})}}
          named_array_of_hashes = []
          array_of_hashes.each{ |hash|
              named_hash = {}
              hash.each{|k,v| 
                new_k = get_property_name(k,Review, ['id'])
                named_hash[new_k] = v 
              }
              named_hash['totalreviews'] = totalreviews
              named_hash['averagereviewrating'] = averagerating
              named_array_of_hashes << named_hash
          }
          reviews = reviews + named_array_of_hashes
        else
          report_error "Reviews result nil for product #{asin}"
          return reviews
        end
      end
      current_page += 1
      break if current_page > totalreviewpages #or current_page > 3 # Debugging purposes only!
    end
    
    return reviews
  end

  # Cleans attributes if they belong
  # to an Amazon printer
  def clean_printer atts
    atts['cpumanufacturer'] = nil # TODO
    ((atts['feature'] || '') +'|'+ (atts['specialfeatures'] || '')).split(/¦|\||#{CleaningHelper.sep}/).each do |x| 
        temp_ppm =  get_ppm(x)
        temp_paperin = parse_max_num_pages(x)
        temp_res = x.match(/(res|\d\s?x\s?\d)/i)
        if temp_ppm
          #debugger
          atts['ppm'] ||= temp_ppm
        elsif temp_paperin and x.match(/(input|feed)/i)
          #debugger
          atts['paperinput'] ||= temp_paperin
        elsif temp_res
          temp_res_2 = parse_dpi(x)
         # temp_resmax =  maxres_from_res(temp_res_2)
          #debugger
          atts['resolution'] ||= temp_res_2
         #atts['resolutionmax'] ||= temp_resmax
        end
    end
    semi_cleaned_atts = clean_property_names(atts) 
    semi_cleaned_atts['displaysize'] = nil # TODO it's just a weird value
    #prices = ['listprice', 'listpriceint', 'listpricestr', 'saleprice', 'salepriceint', 'salepricestr',  'price', 'pricestr', 'priceint'].collect{|x|
    #  (semi_cleaned_atts[x] || '').split(/#{@@sep}/)}.flatten.reject{|x| !x.match(/\./)}
    cleaned_atts = generic_printer_cleaning_code semi_cleaned_atts
    temp1 = clean_brand atts['title'], $printer_brands
    temp2 = clean_brand atts['brand'], $printer_brands
    cleaned_atts['brand'] = temp1 || temp2
    cleaned_atts['condition'] ||= 'New'
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
    conditions.each{|c| 
      (cleaned_atts['condition'] = c) and break if (cleaned_atts['title'] || '').match(/#{c}/i)
    }
    
    cleaned_atts['compatible'] = cleaned_atts['feature'] + "#{cleaned_atts['compatible']}" if cleaned_atts['feature']
    return cleaned_atts
  end
  
  def clean_camera atts
    semi_cleaned_atts = clean_property_names(atts) 
    cleaned_atts = generic_cleaning_code semi_cleaned_atts
    cleaned_atts['resolutionmax'] = maxres_from_res(cleaned_atts['resolution'] || '')
    atts3 = remove_sep(cleaned_atts)
    #debugger
    return atts3
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
  
  #def interpret_special_features(p)
  #  sf = p.specialfeatures
  #  a = sf[3..-1].split('|') #Remove leading nv:
  #  features = {}
  #  a.map{|l| 
  #    c = l.split('^') 
  #    features[c[0]] = c[1]
  #  }
  #  p.ppm = features['Print Speed'].match(/\d+[.]?\d*/)[0] if features['Print Speed']
  #  p.ttp = features['First Page Output Time'].match(/\d+[.]?\d*/)[0] if features['First Page Output Time'] && features['First Page Output Time'].match(/\d+[.]?\d*/)
  #  if features['Resolution']
  #    tmp = features['Resolution'].match(/(\d,\d{3}|\d+) ?x?X? ?(\d,\d{3}|\d+)?/)[1,2].compact
  #    tmp*=2 if tmp.size == 1
  #    p.resolution = tmp.sort{|a,b| 
  #      a.gsub!(',','')
  #      b.gsub!(',','')
  #      a.to_i < b.to_i ? 1 : a.to_i > b.to_i ? -1 : 0
  #    }.join(' x ') 
  #    p.resolutionmax = p.resolution.split(' x ')[0]
  #  end # String drop down style
  #  p.duplex = features['Duplex Printing'] # String
  #  p.connectivity = features['Connectivity'] # String
  #  p.papersize = features['Paper Sizes Supported'] # String
  #  p.paperoutput = features['Standard Paper Output'].match(/(\d,\d{3}|\d+)/)[0] if features['Standard Paper Output'] #Numeric
  #  p.dimensions = features['Dimensions'] #Not parsed yet
  #  p.dutycycle = features['Maximum Duty Cycle'].match(/(\d{1,3}(,\d{3})+|\d+)/)[0].gsub(',','') if features['Maximum Duty Cycle']
  #  p.paperinput = features['Standard Paper Input'].match(/(\d,\d{3}|\d+)/)[0] if features['Standard Paper Input'] && features['Standard Paper Input'].match(/(\d,\d{3}|\d+)/) #Numeric
  #  #Parse out special features
  #  if !features['Special Features'].nil?
  #    if features['Special Features'] == "Duplex Printing"
  #      features['Special Features'] = nil
  #      p.duplex = "Yes" if p.duplex.nil?
  #    end
  #  end
  #  p.special = features['Special Features']
  #  p
  #end
  
end