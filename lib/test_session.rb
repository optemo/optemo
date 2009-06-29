
require 'webrat'
require 'mechanize'
require 'webrat/mechanize'
#require 'rubygems'
require 'printer_page_helpers'

class TestSession < Webrat::MechanizeSession
  
  include PrinterPageHelpers
     
  def initialize (log)
     super
     @logfile = log
     get_homepage
     
     get_init_values
     
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
   
   # Gets the homepage and makes sure nothing crashed.
   def get_homepage
      visit "http://localhost:3000/"
      if error_page?
        report_error "Error loading homepage" 
        raise "Error loading homepage" 
      end
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

    # Gets the homepage and makes sure nothing crashed.
    def get_homepage
       visit "http://localhost:3000/"
       if error_page?
         report_error "Error loading homepage" 
         raise "Error loading homepage" 
       end
    end

    def click_browse_similar which_link
      click_link 'sim' + (which_link-1).to_s
    end

    def click_back_button
       click_link 'Go back to previous Printers'
    end

    def click_home_logo 
      click_link 'LaserPrinterHub.com'
    end
end
