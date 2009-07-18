require 'webrat'
require 'nokogiri'

module PrinterPageHelpers
  
  @@uses = {0 => "All-Purpose", 1 =>"Home Office", \
    2 => "Small Office", 3 => "Corporate Use", 4 => "Photography"}
  
  def self.uses
    return @@uses
  end
  
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
     
     @total_printers = self.num_printers
     
  end
   
   def get_detail_page_link which_product
     @box_hrefs = doc.xpath("(//a[span[@class='easylink']]/@href)[#{which_product}]").to_s
     return nil unless @box_hrefs
     return @box_hrefs
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
      return nil unless x
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
   
   def num_brands_in_dropdown
     return num_elements('#myfilter_brand option')
   end
   
   def num_brands_selected
     return num_elements('.selected_brands')
   end
   
   def brand_selected? which_brand
      if num_brands_selected > 0
        selected_brands = doc.css('.selected_brands')
        return false unless selected_brands
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
      leftbar_el =get_el doc.css("#leftbar")
      return 0 if leftbar_el.nil?
      leftbar = leftbar_el.content.to_s
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
      leftbar_el =get_el doc.css("#leftbar")
      return nil if leftbar_el.nil?
      leftbar = leftbar_el.content.to_s
      session_phrase = leftbar.match('Session id: \d+').to_s
      sesh_id = session_phrase.match('\d+').to_s.to_i
      sesh_id ||= -1
      return sesh_id
   end
   
   # Tells you if there is a "No printers selected" message displayed.
   def no_printers_found_msg?
     # Message is in the first span tag in the div with id main.
     msg_span_el = get_el doc.css(".main span")
     return false if msg_span_el.nil?
     msg_span = msg_span_el.content.to_s
     
     # TODO we should give this span tag an id! 
     printer_phrase = msg_span.match('No products').to_s
     return (printer_phrase.length > 0)
   end
   
   def total_printers
     return @total_printers
   end

   def home_page?
     return true if self.current_url == 'http://localhost:3000/'
     return true if self.current_url == 'http://localhost:3000/printers/'
     bd_div_content = get_bd_div_text
     welcome_msg = bd_div_content.match("Find, compare and buy the right laser printer")
     return !welcome_msg.nil?  
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
      return true if self.current_url == "http://localhost:3000/error"
      return true if "http://localhost:3000/error".eql?(self.current_url) 
      bd_div_content = get_bd_div_text
      err_msg = bd_div_content.match("error")
      return !err_msg.nil?
   end

   # Writes the error both in the logfile and the console.
   def report_error msg
     @logfile.puts "ERROR  " + msg
     puts "ERROR " + msg
   end
   
   def already_saved_msg?
     msg_el = get_el doc.css('#already_added_msg')
     return false if msg_span_el.nil?
     return (msg_el.attribute('style').to_s.match('none').nil?)
   end
   
   def save_here_msg?
     msg_el = get_el doc.css('#deleteme')
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
  
end
