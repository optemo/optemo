module One23Scraper
  
  def id_to_details_url local_id, region
    url = "#{base_url}/catalog.php?path=product&id=#{local_id}"
    return url
  end
  
  def id_to_sponsored_link local_id, region, merchant=nil
    #TODO get sponsored link
    return id_to_details_url(local_id,region)
  end
  
  def get_base_url region
    return "http://www.123inkjets.com"
  end
  
  def scrape_all_local_ids region
      baseurl = get_base_url(region)
      homepage = Nokogiri::HTML(open(baseurl))
      sleep(15)

      brand_links = homepage.css('.catalog-nav a').collect{|x| x.[]('href') }
      folder = 'scrape_me/inkgrabber'

      all_ids = []
      brand_links.each do |link|
        reallink = "#{baseurl}/#{link}"
        brandpage = Nokogiri::HTML(open(reallink))
        sleep(15)
        model_links = brandpage.css('select#id option').collect{|x| x.css('@value').to_s}
        all_ids += model_links[2..-1] || [] if model_links
      end
      return all_ids
  end
  #  def clean atts
  #  def rescrape_prices local_id, region
  #  def scrape local_id, region
  #  def get_linklist_url region, page
  #  def get_linklist_urls region
  #  def scrape_last_page url
  #  def scrape_yellow_box info_page
  #  def scrape_pic_url info_page
  #  def scrape_modelinfo info_page
  #  def scrape_availty info_page
  #  def scrape_prices info_page
  #  def scrape_data info_page
  #  def scrape_links doc
  
  
  def clean_refill dirty_atts
    # TODO
  end

  def special_url web_id
    #TODO For now this is just a regular url.
    base_url = "http://www.123inkjets.com/"
    url = "#{base_url}#{web_id},product.html"
    return url
  end
  
end