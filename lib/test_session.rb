
require 'webrat'
require 'mechanize'
require 'webrat/mechanize'
#require 'rubygems'

class TestSession < Webrat::MechanizeSession
     
  def initialize (log)
     super
     @logfile = log
     get_homepage
     
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
     
     @total_printers = self.num_printers
     
  end
     
   def set_slider which_slider, min, max
     set_hidden_field @slider_max_names[which_slider], :to => max
     set_hidden_field @slider_min_names[which_slider], :to => min
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
   
    def current_slider_min which_slider
      x= doc.css('div[data-startmin]')[which_slider]
      return x.attribute('data-startmin').to_s.to_f
    end
   
   def current_slider_max which_slider
     x= doc.css('div[data-startmax]')[which_slider]
     return x.attribute( 'data-startmax').to_s.to_f
   end
   
   def brand_id brandname
    all_brands = doc.css("#myfilter_brand option")
    all_brands.each_with_index { |el,i| return i if el.attribute('value').to_s == brandname }
    return -1
  end
   
   def brand_name which_brand
     brand_el = doc.css("#myfilter_brand option")[which_brand]
     return "" if (brand_el.nil?)
     return brand_el.attribute( 'value').to_s
   end
   
   def select_brand which_brand
     self.select brand_name(which_brand) #, :from => 'myfilter_brand'
   end
   
   def num_brands_in_dropdown
     return num_elements('#myfilter_brand option')
   end
   
   def remove_nth_selected_brand which_brand
     remove_link = doc.css('.selected_brands a')[which_brand]
     goto_addr= remove_link.attribute('href').to_s
     removed_brands_name = remove_link.attribute('href').to_s.gsub("javascript:removeBrand('"){''}.gsub("');"){''}
     #puts num_brands_selected
     my_selector = '.selected_brands' #+ which_brand.to_s +')'
     within( my_selector ) { |s| puts s.dom}
     #click_link_within my_selector, remove_link.attribute('title').to_s
     #puts my_selector
     click_link 'Remove Brand Filter'
     return removed_brands_name 
   end
   
   def num_brands_selected
     return num_elements('.selected_brands')
   end
   
   def brand_selected? which_brand
      if num_brands_selected > 0
        selected_brands = doc.css('.selected_brands')
        selected_brands.each do |brand_el| 
          if brand_el.content.to_s.match(brand_name(which_brand))
            return true
          end
        end
      end
      return false
   end
   
   # Returns the number of borderboxes on the page.
   def num_boxes
     num_elements(".borderbox")
   end

   # Reads the number of printers being browsed from the page.
   def num_printers
      leftbar = doc.css("#leftbar").first.content.to_s
      printer_phrase = leftbar.match('Browsing \d+ Printers').to_s
      num_printers = printer_phrase.match('\d+').to_s
      return num_printers.to_i
   end
   
   # Returns # of saved printers from the Savebar.
   def num_saved_items
     num_elements('#savebar_content .saveditem')
   end

   # Returns the number of "browse similar" links you can click.
   def num_similar_links
      num_elements(".sim")
   end

  def num_elements el_matcher
    elements = doc.css(el_matcher)
    if elements then return elements.length else return 0 end
  end
  
   # Tells you if the Clear Search link is showing.
   def num_clear_search_links
     num_elements('a#clearsearch')
   end
   
   # Reads the Session ID from the page.
   def session_id
      leftbar = doc.css("#leftbar").first.content.to_s
      session_phrase = leftbar.match('Session id: \d+').to_s
      sesh_id = session_phrase.match('\d+').to_s.to_i
      sesh_id ||= -1
      return sesh_id
   end
   
   # Returns a Nokogiri::HTML document
   def doc
     return self.response.parser
   end
   
   # Tells you if there is a "No printers selected" message displayed.
   def no_printers_found_msg?
     # Message is in the first span tag in the div with id main.
     msg_span = doc.css(".main span").first.content.to_s
     # TODO we should give this span tag an id! 
     printer_phrase = msg_span.match('No products ').to_s
     return (printer_phrase.length > 0)
   end
   
   def total_printers
     return @total_printers
   end

   # Returns true if the page's response is the error page.
   def error_page?
      return true if self.current_url == "http://localhost:3000/error"
      return true if "http://localhost:3000/error".eql?(self.current_url) 
      bd_div = doc.css('div.bd').first.content.to_s
      err_msg = bd_div.match("We're sorry but the website has experienced an error").to_s
      return true if err_msg.length > 0
      return false
   end

   # Writes the error both in the logfile and the console.
   def report_error msg
     @logfile.puts "ERROR  " + msg
     puts "ERROR " + msg
   end

   # Gets the homepage and makes sure nothing crashed.
   def get_homepage
      # TODO temporary fix!!! REMOVE ME!!
      begin
        self.visit 'http://localhost:3000'
      rescue Exception => e
        self.visit 'http://localhost:3000'
        report_error "There is an error on 1st load."
      end
      #visit "http://localhost:3000/"
      if error_page?
        report_error "Error loading homepage" 
        raise "Error loading homepage" 
      end
   end
  
end
