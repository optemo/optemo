module NeweggScraper

  def id_to_details_url local_id, region
    return "#{get_base_url(region)}/Product/Product.aspx?Item=#{local_id}"
  end
  
  def id_to_sponsored_link local_id, region, merchant=nil
    url = id_to_details_url local_id, region
    klik = case region
    when /us/i
      "-3328141-10446076"
    when /ca/i
      "-3328141-10657534"
    end
    special_url = "http://www.jdoqocy.com/click#{klik}?url="
    special_url += CGI.escape(url)
    return special_url
  end

  def get_base_url region
    ext = '.com'
    ext = '.ca' if region.match(/ca/i)
    return "http://www.newegg#{ext}"
  end
  
  def scrape_all_local_ids region
    ids = []
    pg = 1
    loop do
      doc = get_links_page(region, pg)
      resultset = doc.xpath('//div[@id="bcaBreadcrumbTop"]/dl/dd').last.content.to_s
      log "Scraping Page \##{pg}: #{resultset}" 
      
      printer_id_els = doc.xpath('//td[@class="midCol"]/h3/a/@href')
      break if printer_id_els.count == 0
      pg += 1
      
      ids += printer_id_els.collect{|el|
        el.to_s.gsub(/.*Item=/,'')
      }
    end
    
    return ids.uniq.reject{|x| x.nil? or x == ''}
  end

  def clean atts
    colorprops = ["colorprinter", "ppmcolor", "copyspeedcolor", "copyqualitycolor", "scancolordepth", "colorfax", "colorresolution"]
    atts = infer_boolean('colorprinter', colorprops, atts)
  
    scanprops = ["scanresolutionenhanced", "scancolordepth", "scanresolutionoptical", "scanelement", "scanresolutionhardware"]
    atts = infer_boolean('scanner',scanprops,atts,false)
  
    faxprops = ["faxfeatures", "faxmemory", "faxtransmissionspeed", "faxresolutions", "colorfax"]
    atts = infer_boolean('fax',faxprops,atts)
  
    atts['printserver'] = (atts['networkports'].nil? == false)
    
    atts['platform'] = multiple_fields_to_one([atts['windowscompatible'],atts['macintoshcompatible'],\
      atts['windowsvista']])
  
    (atts['blackprintquality'] or "").gsub!(/ dpi/,'') 
    (atts['mediasizessupported'] or "").gsub!('~','to')
    
    # Dimensions
    temp = [atts['dimensions'], "#{atts['itemwidth']} x #{atts['itemheight']} x #{atts['itemlength']}" ].compact.reject(&:blank?)
    mergeme = clean_dimensions(temp,100)
    mergeme.each{ |key, val| atts[key] = val}
    
    cleanatts = generic_printer_cleaning_code atts
    
    # For the offering
    cleanatts['toolow'] = false if cleanatts['toolow'].nil?
    cleanatts['stock'] = true unless cleanatts['priceint'].nil? or cleanatts['stock'] == false
    cleanatts['stock'] = false unless cleanatts['stock'] == true
    
    cleanatts['condition'] = 'New'# if cleanatts['condition'].nil?
    if cleanatts['condition'] == 'New' and cleanatts['local_id'].match(/R$/)
      cleanatts['condition'] = 'Refurbished' 
    end
    
    return cleanatts
  end
  
  def rescrape_prices(local_id, region)
    infopage = Nokogiri::HTML(open(id_to_details_url(local_id, region)))
    log_snore(15)
    atts = scrape_prices infopage, local_id, region
    atts['local_id'] = local_id
    atts['region'] = region
    
    clean_atts = (clean(atts)).reject{|x,y| y.nil? || !RetailerOffering.column_names.include?(x)}
    
    return clean_atts
  end
  
  def scrape(local_id, region)
      return nil if local_id.nil? or region.nil?
      infopage = Nokogiri::HTML(open(id_to_details_url(local_id, region)))
      log_snore(15)
      atts = scrape_prices infopage, local_id, region
      atts.merge!(scrape_title infopage)
      atts.merge!(scrape_urls infopage)
      atts.merge!(scrape_specs infopage)
      atts = clean_property_names atts
      return atts
  end
  
  private

 # newegg specific
  
  def scrape_all_local_ids_from_feed feed_url
    feed = Nokogiri::XML(open(feed_url))
    
    recent_items = feed.css("item")
    recent = []
    
    # Scrape all product numbers of recently added/updated printers
    recent_items.each do |item|
      
      product_link = get_el(item.css('guid')).content
      product_num = product_link.gsub(/.+?Item=/,'').gsub(/&.+/,'').strip
      date = get_el(item.css('pubDate')).content # can use this to ignore older entries
      recent << product_num if product_num
    end
    return recent
  end

  def get_links_page region, pagenum
    url = "#{get_base_url(region)}/Product/ProductList.aspx?Submit=ENE&N=2010330630&page=#{pagenum}&bop=And&ActiveSearchResult=True&Pagesize=100"
    page = Nokogiri::HTML(open(url))
    log_snore(30)
    return page
  end
    
  def scrape_urls infopage
    retme = {}
    manuf_url = scrape_att_via_css( infopage, \
          "#pclaManufacture a[title *= 'Manufacturer Product Page']",'href' ) 
    retme["manufacturerproducturl"] = manuf_url
    img_url = scrape_att_via_css(infopage,'#pclaImageArea img[src]','src')
    retme["imageurl"] = img_url
    return retme
  end
  
  def scrape_title infopage
    retme = {}
    title_el = get_el infopage.css("#bcapcHeaderArea h1")
    title_text = title_el.text if title_el
    retme["title"] = title_text if title_text
    return retme
  end
  
  def scrape_prices infopage, item_number, region
    retme = {}
  
    price_el = get_el(infopage.xpath('//div[@id="pclaPriceArea"]/dl[@class="price"]'))
    
    if(price_el)    
      sale_price_el = get_el price_el.css(".final")
      retme['saleprice'] = sale_price_el.text if sale_price_el
      orig_price_el = get_el price_el.css(".original")
      retme['listprice'] = orig_price_el.text if orig_price_el
      
      # -- Shipping --- #
      shipping_el = get_el price_el.css('.shipping')
      retme['shipping']  = shipping_el.text if shipping_el
      
      # --- Too low? --- #
      low_price_el = get_el price_el.css('.lowestPrice')
      
      if(low_price_el)
        lowpricepage = Nokogiri::HTML(open("#{get_base_url(region)}/Product/MappingPrice.aspx?Item=#{item_number}"))
        log_snore(15)
        lowpage_lowprice_el = get_el lowpricepage.css('.final')
        retme['saleprice'] = lowpage_lowprice_el.text if lowpage_lowprice_el
        retme['toolow'] = true
      else
        retme['toolow'] = false
      end
      
      # --- Availability --- #
      stock_el = get_el price_el.css('.stockInfo')
      retme['stock'] = stock_el.text if stock_el
    else
      retme['stock'] = false 
    end
      
    return retme
  end
  
  def scrape_specs infopage
    tablehtml = infopage.xpath("//table[@class='specification']/tr")
    spec_table = scrape_table(tablehtml, 'td.name', 'td.desc')
    return spec_table
  end
  
end
