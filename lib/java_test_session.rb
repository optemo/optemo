class JavaTestSession < Webrat::SeleniumSession
  
  include PrinterPageHelpers
     
  def initialize (log)
    require 'webrat'
    require 'webrat/selenium'
    require 'printer_page_helpers'
     super
     @logfile = log
     get_homepage
     pick_printer_use
     get_init_values
     PrinterPageHelpers.uses.keys.each do |u|
        get_homepage
        pick_printer_use u
        set_total_printers u, self.num_printers 
     end
     get_homepage
     pick_printer_use
  end
     
  def click_checkbox clickme
    cbox_id = doc.css('#filter_form input[@type="checkbox"]')[clickme].[]('id')
    selenium.click cbox_id
    browser.submit "filter_form"
    wait_for_load
  end   
     
   def move_slider which_slider, min, max
     fill_in @slider_max_names[which_slider], :with => max
     fill_in @slider_min_names[which_slider], :with => min
     browser.submit "filter_form"
     wait_for_load
   end
   
   def select_brand which_brand
     self.selenium.select( 'myfilter_brand', 'value='+ brand_name(which_brand).to_s) 
     browser.submit "filter_form" 
     wait_for_load
   end
   
   def current_url
     return self.selenium.location
   end   
   
   # Returns a Nokogiri::HTML document
   def doc
     return Nokogiri::HTML(self.response.body)
   end
   
   def click_clear_search 
     selenium.click 'clearsearch'
   end
   
   def search_for query 
     browser.type 'search', query
     browser.click 'id=submit_button' 
     wait_for_load
   end
   
   # Gets the homepage and makes sure nothing crashed.
   def get_homepage
      visit "http://localhost:3000/"
      wait_for_load
      if error_page?
        report_error "Error loading homepage" 
        raise "Error loading homepage" 
      end
   end
   
   def pick_printer_use which_use=0
     browser.click "link=#{@@uses[which_use] || which_use}" 
     wait_for_load
   end
   
   def click_browse_similar which_link
     linkid='sim' + (which_link-1).to_s
      # TODO Check for element presence.
      # TO DO TO DO 
      browser.click linkid
      wait_for_load
   end
      
   def click_back_button
      selenium.click 'link=Go back to previous Printers'
      wait_for_load
   end
   
   def click_home_logo 
     self.selenium.click 'css=a[title="LaserPrinterHub.com"]'
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
