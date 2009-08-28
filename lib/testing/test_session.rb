class TestSession < Webrat::MechanizeSession
  
  include PrinterPageHelpers
     
  def initialize (log)
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

    def pick_printer_use which_use=0
      #use = PrinterPageHelpers.uses[which_use] || which_use
      the_link = doc.css('div.category a')[which_use]
      visit the_link.[]('href') if the_link
    end

    # Gets the homepage and makes sure nothing crashed.
    def get_homepage
      begin
       visit "http://localhost:3000/"
      rescue Timeout::Error => e
        report_error "#{e.type} #{e.message}"
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
      click_link 'LaserPrinterHub.com'
    end
end
