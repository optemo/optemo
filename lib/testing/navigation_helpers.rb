module NavigationHelpers
      
  def get_init_values
     @slider_min_names= []
     doc.css(".feature input.min").each do |x|
       @slider_min_names << x.attribute("name").to_s 
     end
     
     @slider_max_names = []
     doc.css(".feature input.max").each do |x| 
       @slider_max_names << x.attribute("name").to_s 
     end
     
     @slider_max = []
     (1..num_sliders).each do |x| 
       @slider_max << current_slider_max(x-1)
     end
     
     @slider_min = []
     (1..num_sliders).each do |x| 
        @slider_min << current_slider_min(x-1)
      end
     
     @slider_nicknames = []
     @slider_min_names.each do |x| 
       @slider_nicknames << x.gsub(/(\w+\[)/){''}.gsub(/(_.+)/){''} 
     end
     
     @total_products = [nil,nil,nil,nil,nil]
  end
  
   def set_total_products index, value
     @total_products[index] = value
   end
   
   def get_detail_page_link box
     pid = pid_by_box(box)
     return  "/compare/show/#{pid}"
   end
   
   def detail_page?
     return ( self.current_url.match(/compare\/show/) and !self.error_page?)
   end
   
   def num_checkboxes
     return doc.css('#filter_form input[@type="checkbox"]').length
   end
   
   def checkbox_selected? which_checkbox
     checkbox_el = doc.css('#filter_form input[@type="checkbox"]')[which_checkbox]
     return false unless checkbox_el
     return (!checkbox_el.[]('checked').nil? and checkbox_el.[]('checked')=='checked')
   end
   
   def num_sliders
     return @slider_min_names.length
   end
   
   def slider_name which_slider
      return @slider_nicknames[which_slider]
   end
   
   def slider_min which_slider
      return @slider_min[which_slider]
   end

   def slider_max which_slider
      return @slider_max[which_slider]
   end

   def slider_range which_slider
     return (slider_max(which_slider) - slider_min(which_slider))
   end
   
   def slider_step which_slider
      step = (slider_range(which_slider)/100.0)
      return step
   end
   
   def slider_percent_to_pos which_slider, percentmove
       realmove = percentmove.to_i * slider_step(which_slider)
       realpos = realmove + slider_min(which_slider)
       return realpos.to_i unless which_slider == 0
       return ((realpos*10).to_i/10.0)
   end
   
   def current_slider_min which_slider
      x= doc.css('div[data-startmin]')[which_slider]
      return x.attribute('data-startmin').to_s.to_f if x
      return nil
   end
   
   def current_slider_max which_slider
     x= doc.css('div[data-startmax]')[which_slider]
     return x.attribute( 'data-startmax').to_s.to_f if x
     return nil
   end
   
   def brand_id brandname
    all_brands = doc.css("#selector option")
    all_brands.each_with_index { |el,i| return i if el.attribute('value').to_s == brandname }
    return -1
   end
   
   def is_all_brands? bname
     return true if bname == 'All Brands'
     return true if bname == 'Add Another Brand'
     return false
   end
   
   def brand_name which_brand
     brand_el = doc.css("#selector option")[which_brand]
     return "" if (brand_el.nil?)
     return brand_el.attribute( 'value').to_s
   end
   
   def selected_brand_name which_brand
     brand_el = doc.css(".selected_brands")[which_brand]
     return "" if (brand_el.nil?)
     debugger
     return brand_el.attribute( 'value').to_s
   end
  
   def num_brands_in_dropdown
     return num_elements('select#selector option')
   end
   
   def num_brands_selected
     return num_elements('.selected_brands')
   end
   
   def brand_selected? bname
      if num_brands_selected > 0
        selected_brands = doc.css('.selected_brands').collect{|x| x.text.strip}
        return false unless selected_brands
        return true if selected_brands.include?(bname)
      end
      return false
   end
   
   # Returns the number of borderboxes on the page.
   def num_boxes
     num_elements(".navigator_box")
   end

   # Reads the number of products being browsed from the page.
   def num_products
      leftbar_el = get_el(doc.css("#navigator_bar"))
      return 0 if leftbar_el.nil?
      leftbar = leftbar_el.content.to_s
      product_phrase = leftbar.match('Browsing \d+ ').to_s
      num_products = product_phrase.match('\d+').to_s
      return num_products.to_i
   end
   
   # Returns # of saved products from the Savebar.
   def num_saved_items
     num_elements('#savebar_content .saveditem')
   end

   # Returns the number of "browse similar" links you can click.
   def num_similar_links
      num_elements(".sim a")
   end

  def num_elements el_matcher
    elements = doc.css(el_matcher)
    if elements then return elements.length else return 0 end
  end
   
   # Reads the Session ID from the page.
   def session_id
      leftbar_el =get_el doc.css("#navigator_bar")
      return nil if leftbar_el.nil?
      leftbar = leftbar_el.content.to_s
      session_phrase = leftbar.match('Session id: \d+').to_s
      sesh_id = session_phrase.match('\d+').to_s.to_i
      sesh_id ||= -1
      return sesh_id
   end
   
   # Tells you if there is a "No products selected" message displayed.
   def no_products_found_msg?
     msg_vis = get_el(doc.css("#outsidecontainer"))
     return false unless msg_vis and msg_vis.css('@style').to_s.match(/display: inline/)
     msg = get_text(doc.css("#outsidecontainer #info"))
     return true if (msg || '').match(/no matching results/i)
     return false
   end
   
   def total_products
     return @total_products
   end

   def home_page?
     return true if (self.current_url||'').match(/^http:\/\/((cameras|printers)\.)?localhost:\d+\/?(compare)?$/)
     return false 
   end
   
   def popup_tour?
     ptour = get_el(doc.css('div.popupTour'))
     vis = ptour.css('@style').to_s.match('display: block') if ptour
     return !vis.nil?
   end
   
   def get_bd_div_text
     bd_div = doc.css('div.bd').first
     if(bd_div == nil) 
       bd_div_content = '' 
       report_error 'No bd_div in page! Malformed page.'
     else 
       bd_div_content = bd_div.content.to_s 
     end
     return bd_div_content
   end
   
   # Returns true if the page's response is the error page.
   def error_page?
      popup_msg = get_el(doc.css('div#outsidecontainer'))
      return false if popup_msg.nil?
      return false if popup_msg.css('@style').to_s.match('display: none')
      return true if popup_msg.to_s.match(/error/i)
      return false
   end
   
   def already_saved_msg?
     msg_el = get_el doc.css('#already_added_msg')
     return false if msg_el.nil?
     return (msg_el.attribute('style').to_s.match('none').nil?)
   end
   
   def save_here_msg?
     msg_el = get_el doc.css('.savesome')
     return false if msg_el.nil?
     return (msg_el.attribute('style').to_s.match('none').nil?)
   end

   def compare_button?
     button_el = get_el doc.css('#compare_button')
     return false unless button_el
     return (button_el.attribute('style').to_s.match('none').nil?)
   end
   
   def pid_by_box which_box
     @box_hrefs = doc.xpath("((//a[@class='save'])[#{which_box}])/@href")
     return @box_hrefs.to_s.match('\d+').to_s.to_i
   end
   
   def was_saved? product_id
     @saved_ids = doc.xpath("(//div[@class='saveditem']/@id)")
     @saved_ids.each do |pid|
        if (pid.to_s.match('\d+').to_s.to_i == product_id.to_i)
          return true
        end
     end
     return false
   end
  
  def searched_term
    header_text = get_text(doc.css('#navigator_bar'))
    return nil unless header_text
    msg = (header_text.match(/Search: '.+'/)||'').to_s
    if msg and msg.length > 0
      term = (msg.match(/'.+'/)||'').to_s.gsub(/'/, '')
      if term and term.length > 0
        return term
      end
    end
    return nil
  end
  
  def has_search_history?
    return true if self.searched_term
  end
  
end
