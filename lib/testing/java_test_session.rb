class JavaTestSession < Webrat::SeleniumSession
  
  include NavigationHelpers
  
  def initialize (log)
     super
     @logfile = log
     get_homepage
     get_init_values
     set_total_products(0,self.num_products) 
     get_homepage
  end
     
  def get_detail_page box
    the_link = doc.css('div.productinfo .easylink')[box]
    the_text = (the_link.text || '').strip
    selenium.click("link=#{the_text}")
    wait_for_ajax  
  end   
    
  def close_popup_tour
    selenium.click('css=div.popupTour a.deleteX')
  end
     
  def click_checkbox clickme
    cbox_id = doc.css('#filter_form input[@type="checkbox"]')[clickme].[]('id')
    selenium.click cbox_id
    wait_for_ajax
  end   
     
  # This function uses parse_and_set_attribute() erroneously. It's probably severely deprecated, July 2010
  def move_slider which_slider, min, max
    parse_and_set_attribute(@slider_max_names[which_slider], :with => max)
    parse_and_set_attribute(@slider_min_names[which_slider], :with => min)
    browser.run_script('submitAJAX()')
    #browser.run_script('ajaxcall("/products/filter", $("#filter_form").serialize())')
    wait_for_ajax
  end
   
   def select_brand which_brand
     self.selenium.select( 'selector', 'value='+ brand_name(which_brand).to_s) 
     wait_for_ajax
   end
   
   def current_url
     return self.selenium.location
   end   
   
   # Returns a Nokogiri::HTML document
   def doc
     return Nokogiri::HTML(self.response.body)
   end
   
   def search_for query 
     browser.type 'search', query
     browser.click 'id=submit_button' 
     wait_for_ajax
   end
  
  def close_msg_box
    msg_vis = get_el(doc.css("#outsidecontainer"))
    return false unless msg_vis and msg_vis.css('@style').to_s.match(/display: inline/)
    browser.click 'css=#outsidecontainer a.close'
    wait_for_ajax
  end

  def click_link_in_msg_box
    msg_vis = get_el(doc.css("#outsidecontainer"))
    return false unless msg_vis and msg_vis.css('@style').to_s.match(/display: inline/)
    browser.click 'css=#outsidecontainer #info a'
    wait_for_ajax
  end
  
  # fill in the pref form 
  def pref_for query
     browser.type 'price', query
     browser.click 'id=submit_button'   
     wait_for_load  
  end 
  
   # Gets the homepage and makes sure nothing crashed.
   def get_homepage product_type='printer'
      visit "http://#{product_type}s.localhost:#{$port}/"
      wait_for_load
      if error_page?
        report_error "Error loading homepage" 
        raise "Error loading homepage" 
      end
   end
   
   def click_browse_similar which_link
     the_link = doc.css('.simlinks')[which_link-1]
     if the_link and !the_link.text.nil? and !the_link.text.strip.empty?
       browser.click "link=#{the_link.text}" 
       wait_for_ajax
     else
       report_error "#{which_link}th Browse Similar Link not found"
     end
   end
   
   def remove_brand which_brand
     selenium.click "css=.selected_brands a"
     wait_for_ajax
   end
      
   def click_back_button
     selenium.go_back #:wait_for => :ajax, :javascript_framework => :jquery
     sleep 5 #sleep because wait_for does not seem to work
   end
   
   def click_home_logo 
     # TODO what bout cameras
     self.selenium.click 'css=a#logo'
     self.wait_for_load
   end
   
   def wait_for_ajax
      # Either or both of these will wait for AJAX
      selenium.wait_for_condition 'selenium.browserbot.getCurrentWindow().jQuery.active == 0'
      selenium.wait_for_condition 'window.jQuery.active == 0'
   end
   
   def wait_for_load
      selenium.wait_for_page_to_load
   end
  
end
