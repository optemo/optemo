module TigerScraper

  def id_to_details_url local_id, region
     base_url = get_base_url region
     return "#{base_url}#{local_id}"
  end
  
  def id_to_sponsored_link local_id, region, merchant=nil
    klik = case region
    when /us/i
      "id=lI8cIt0J/v0&subid=&offerid=102327.1&type=10&tmpid=3883"
    when /ca/i
      "id=lI8cIt0J/v0&subid=&offerid=102328.1&type=10&tmpid=3879"
    end
    link_prefix = "http://click.linksynergy.com/fs-bin/click?#{klik}&RD_PARM1=" 
    return (link_prefix+CGI.escape(id_to_details_url(local_id, region))) if klik
    return id_to_details_url(local_id, region)
  end

  def get_base_url region
    retailer = $retailers.reject{|x| x.region.match(/#{region}/i).nil?}.first
    return nil if retailer.nil?
    return retailer.url
  end

  def scrape_all_local_ids region
    link_lists = get_linklist_urls region
    links = []
    link_lists.each do |ll_url|
      page = Nokogiri::HTML(open(ll_url))
      snore(30)
      links = (scrape_links page) | links
    end
    return links
  end

  def clean atts
    atts['display'] = (atts['specialfeatures'] || "").split(',').delete_if{|x| x.match(/display/i).nil?}.first
    atts['scanner'] = true if (atts['specialfeatures'] || "").match(/scan/i)
    atts['printserver'] = true if (atts['specialfeatures'] || "").match(/network/i)
    atts['fax'] = true if (atts['specialfeatures'] || "").match(/fax/i)
    atts['stock'] = atts['itmdets'].match(/unavail/i).nil? if atts['itmdets']

    atts['condition'] = 'New'
    atts['condition'] = "Refurbished" if ((atts['upcno']||'').match(/^RB-/) or (atts['model']||'').match(/^RB-/) or (atts['title']||'').match(/refurbished/i) )
    atts['condition'] = "OEM" if (atts['title']||'').match(/oem/i) 

    atts['product_type'] = $model.name

    atts = clean_property_names atts
    clean_atts = generic_printer_cleaning_code(atts)

    
    atts['resolutionmax'] = get_max_f atts['resolution'] if atts['resolutionmax'].nil? and atts['resolution']

    temp = clean_brand(clean_atts['brand'], $printer_brands)
    clean_atts['brand'] = temp if temp
    clean_atts['model'] = clean_printer_model(clean_atts['model'], clean_atts['brand'])
    
    clean_atts['condition'] ||= 'New' # Default is new
    return clean_atts
  end
  
  def rescrape_prices local_id, region
    url = id_to_details_url local_id, region
    props = {}
    begin
      info_page = Nokogiri::HTML(open(url))
      snore(20)
      log "Re-scraping RetailerOffering # #{local_id}"
    rescue Exception => e
      report_error "Couldn't open page: #{url}. Rescraping price failed."
      report_error "#{e.type.to_s}, #{e.message.to_s}"
    else
      props.merge! scrape_prices info_page 
      props.merge! scrape_availty info_page
    end
    return props
  end
  
  def scrape local_id, region
    url = id_to_details_url local_id, region
    props = {}
    begin
      info_page = Nokogiri::HTML(open(url))
      snore(20)
      announce "Scraping #{url}"
    rescue Exception => e
      report_error "Problem scraping page: #{url}."
      report_error "#{e.type.to_s}, #{e.message.to_s}"
      return nil
    else
      props.merge! scrape_data info_page
      props.merge! scrape_prices info_page 
      props.merge! scrape_yellow_box info_page
      props.merge! scrape_availty info_page
      props.merge! scrape_modelinfo info_page
      props.merge! scrape_pic_url info_page
      props['region'] = region
      props['local_id']= local_id
    end
    return props
  end
  
  private 
  
  # -- Link scraping stuff -- #
  
  def get_linklist_url region, page
    base_url = get_base_url region
    return "#{base_url}/applications/category/category_slc.asp?page=#{page}&Nav=%7Cc:244%7C&Sort=0&Recs=30"
  end
  
  def get_linklist_urls region
    base_url = get_base_url region
    firstpage_url = get_linklist_url region, 1
    firstpage = Nokogiri::HTML(open(firstpage_url))
    sleep(15)
    last_pic_src = "#{base_url.sub(/tiger/, 'images.tiger').sub(/www./,'')}/search/navbar_last.gif"
    # firstpage.xpath('//a[img[@src="http://images.tigerdirect.ca/search/navbar_last.gif"]]').collect{|x| x.[]('href')}.uniq
    last_url = firstpage.xpath("//a[img[@src='#{last_pic_src}']]").collect{|x| x.[]('href')}.last
    last_num = (last_url || '').match(/\?page=\d+\&/).to_s.match(/\d+/).to_s.to_i
    urls = []
    last_num.times do |pg|
      urls << get_linklist_url( region, pg+1)
    end
    return urls
  end
  
  # -- Accessing the data on the website -- #
  
  def scrape_last_page url
    info_page = Nokogiri::HTML(open(url))
    snore(20)
    pg_numbers = info_page.css()
    return lastpg
  end
  
  def scrape_yellow_box info_page
    yellow_boxes = info_page.css('[bgcolor="#ffff99"] font')
    hsh = {}
    yellow_boxes.each do |box|  
      box.to_s.gsub(/[\t\r]+/,'').split("<br>").each do |x| 
        if x.split(/<\/?b>/).length == 2
          temparray = x.split(/<\/?b>/)
        elsif x.split(/\(/).length == 2
          temparray = x.split(/\(/)
        end
        if temparray
          key = just_alphanumeric( temparray[0].gsub(/<.*>/,'') )
          val = temparray[1].gsub(/<.*>/,'').gsub(/\n/,'').strip
          hsh.merge!( key => val )
        end
      end
    end
  
    return hsh
  end
  
  def scrape_pic_url info_page
    pic_el = get_el info_page.css('img[@name="imgLarge"]')
    
    if pic_el.nil?
      pic_el = get_el info_page.css('img[@onerror="this.src=\'http://images.tigerdirect.ca/SearchTools/no_image-med.gif\';"]')
    end
    
    if pic_el.nil?
      pic_el = get_el info_page.css('img[@onerror="this.src=\'http://images.tigerdirect.com/SearchTools/no_image-med.gif\';"]')
    end
    
    if pic_el
      return {'imageurl' => pic_el.[]('src')}
    end
    return {}
  end
  
  def scrape_modelinfo info_page
    returnme = {}
  
    title_el = info_page.css('td.font_size4bold h1')
    returnme['title'] = title_el.text if title_el
  
    itemno_row = info_page.xpath('//tr[td[text()="Item Number:"]]')
    itemno_el = itemno_row.xpath('td[2]')
    returnme['itemnumber'] = itemno_el.text if itemno_el
  
    return returnme
  end
  
  def scrape_availty info_page
    hsh = {}
    avail_row = info_page.xpath('//tr[td[text()="Availability:"]]')
    avail_el = avail_row.xpath('td[2]')
    hsh['availability'] = avail_el.text if avail_el
  
    itmdets = get_el info_page.css('form[name="itmdets"]')
    hsh['itmdets'] = itmdets.text if itmdets
  
    return hsh
  end
  
  def scrape_prices info_page
    prices_table = info_page.css('table#myPrice tr')
    prices = scrape_table prices_table, "td", "td"
    # TODO have a real test for it:
    prices['toolow'] = false
    return prices
  end
  
  def scrape_data info_page
      puts "#{info_page.css('table.viss').length} tables found "
      spec_table = info_page.css('table.viss tr')
      specs = scrape_table spec_table, 'td.techspec', 'td.techvalue'
      return specs
  end

  def scrape_links doc
   link_els = doc.css('table.maintbl form[name="frmCompare"] a[title="Click for more information"]')
   links = []
   link_els.each do |link|
     links << link.attribute('href').to_s
   end
   links.uniq!
   return links
  end
end
