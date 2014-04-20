module InkgrabberScraper
  
  def id_to_details_url local_id, region
    return "#{baseurl(region)}/skus/#{local_id}.jsp"
  end
  
  def id_to_sponsored_link local_id, region, merchant=nil
    url = id_to_details_url(local_id,region)
    special_url = "http://www.jdoqocy.com/click-3328141-10429337?url="
    special_url += CGI.escape(url)
    return special_url
  end
  
  def get_base_url region
    return "http://www.inkgrabber.com"
  end
  
  def scrape_all_local_ids(region)
    scrape_all_local_ids_1 region
  end
  
  def scrape_all_local_ids_1 region
    baseurl = get_base_url(region)
    homepage = Nokogiri::HTML(open(baseurl))
    sleep(15)
    
    brand_links = homepage.xpath('//a[contains(@href, "menu.html")]/@href').collect{|x| x.to_s}.uniq.reject{|x| 
      x.nil?}
    
    #model_links = []
    skus = []
    brand_links.each do |link|
      brandpage = Nokogiri::HTML(open(link))
      sleep(15)
      temp = brandpage.css('select')[1]
      if temp
        temp2 = temp.css('option/@value').collect{|x| x.to_s}.reject{|x| x.nil? or x.strip == ''}
        #model_links += temp2
        temp2.each do |ln|
          reallink = "#{get_base_url(region)}#{ln}"
          modelpage = Nokogiri::HTML(open(reallink))
          sleep(15)
          debugger
          temp = modelpage.css('td[width="18%"]').collect{|x| x.text}
          skus += temp
        end
      end
      
    end
    
    #model_links.each do |link|
    #  modelpage = Nokogiri::HTML(open(link))
    #  sleep(15)
    #  debugger
    #  temp = modelpage.css('td[width="18%"]').collect{|x| x.text}
    #  skus += temp
    #end
    return skus
  end
  
  def scrape_all_local_ids_2 region
    baseurl = get_base_url(region)
    homepage = Nokogiri::HTML(open(baseurl))
    sleep(15)
    
    
    brands = homepage.xpath('//a[contains(@href, "menu.html")]').collect{|x| x.text}.uniq.reject{|x| x.nil?}
    brand_links = brands.collect{|x| "http://www.inkgrabber.com/printers.mhtml?search_for=#{x}"}
    
    skus = []
    brand_links.each do |link|
      brandpage = Nokogiri::HTML(open(link))
      sleep(15)
      temp = brandpage.css('td[width="18%"]').collect{|x| x.text}
      skus += temp
    end
    return skus
  end
  
  #  def rescrape_prices local_id, region
  #  def scrape local_id, region
  #  def get_linklist_url region, page
  #  def get_linklist_urls region
  #  def scrape_pic_url info_page
  #  def scrape_modelinfo info_page
  #  def scrape_availty info_page
  #  def scrape_prices info_page
  #  def scrape_data info_page
  #  def scrape_links doc
  
  def clean dirty_atts
    clean_atts = cartridge_cleaning_code(dirty_atts, 'Ink Grabber', false)
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
  
end