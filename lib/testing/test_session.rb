class TestSession < Webrat::MechanizeSession
   
   include NavigationHelpers
      
   def initialize (log)
     super
     @logfile = log
     get_homepage
     get_init_values
     set_total_products 0, self.num_products
  end
     
   def move_slider which_slider, min, max
     set_hidden_field @slider_max_names[which_slider], :to => max
     set_hidden_field @slider_min_names[which_slider], :to => min
     submit_form "filter_form" # When no submit button present use form id.
   end
   
   # Returns a Nokogiri::HTML document
   def doc
     return self.response.parser
   end
   
   def select_brand which_brand
     select brand_name(which_brand), :from => 'myfilter_brand'
     submit_form 'filter_form'
   end

   def click_clear_search 
     click_link 'clearsearch'
   end
   
   def search_for query 
     fill_in "search", :with => query
     click_button "submit_button"
   end
   
   def get_detail_page box
     visit get_detail_page_link(box)
   end
   
   # Gets the homepage and makes sure nothing crashed.
   def get_homepage product_type='printer'
     begin
      visit "http://#{product_type.downcase}s.localhost:3000/"
     rescue Timeout::Error => e
       report_error "#{e.class.name} #{e.message}"
     end
      if error_page?
        report_error "Error loading homepage" 
        raise "Error loading homepage" 
      end
   end
   
   def click_browse_similar which_link
     the_link = doc.css('.simlinks')[which_link-1]
     click_link the_link.text if the_link
     report_error "#{which_link}th browse sim. link not found" if the_link.nil?
   end
   
   def click_home_logo
     # TODO what about camera site 
      click_link 'LaserPrinterHub.com'
    end
end
