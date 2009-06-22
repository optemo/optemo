# Some tests for the laser printer site.
namespace :printer_test do   
   
  desc "Test the sliders"
  task :sliders => :environment do
    setup
    sesh = Webrat.session_class.new
    logfile =  setup_log "sliders" 
    
    get_homepage sesh, logfile
    doc = sesh.response.parser
    
    slider_min_names = []
    doc.css(".feature input.min").each do |x| slider_min_names << x.attribute("name").to_s end
    
    slider_max_names = []
    doc.css(".feature input.max").each do |x| slider_max_names << x.attribute("name").to_s end
    
    slider_max = []
    doc.css(".feature .endlabel_max").each do |x| slider_max << x.content.to_i end
    
    slider_min = []
    doc.css(".feature .endlabel_min").each do |x| slider_min << x.content.to_i end
    
    1000.times do
      pick_slider = rand slider_min_names.length
      
      distance =slider_min[pick_slider] + rand(slider_max[pick_slider]-slider_min[pick_slider])
      logfile.puts "LOGGER    Testing the " + slider_min_names[pick_slider] + " slider. Moving it to " +  distance.to_s
      
      new_min = slider_min[pick_slider]
      new_max = slider_max[pick_slider]
      (rand >= 0.5)? new_min = distance : new_max = distance
      
      # Test the sliders.
      begin
        sesh.set_hidden_field slider_max_names[pick_slider], :to => new_max
        sesh.set_hidden_field slider_min_names[pick_slider], :to => new_min
        
        logfile.puts "LOGGER    Setting " + slider_min_names[pick_slider] + " Slider to (#{new_min},#{new_max})" 
        
        sesh.submit_form "filter_form" # When no submit button present use form id.
      rescue Exception => e
        report_error logfile, e.type.to_s
        report_error logfile, e.message.to_s
        break
        get_homepage sesh, logfile
        logfile.puts "LOGGER     Starting over from homepage."
      else
        doc = sesh.response.parser
        if none_selected?(doc) 
          logfile.puts "LOGGER    No printers found."
        else
          logfile.puts "LOGGER    Number of printers matching criteria: " + num_printers(doc).to_s
        end
        # Error checking code 
        report_error(log, "Error loading homepage") if error_page?(sesh)
        # End error checking code
      end
      
    end
    
    close_log logfile
  end

  desc "Test the brand selector"
  task :brand_selector => :environment do 
  
    setup
    logfile = setup_log "brand_selector" 
    
    sesh = Webrat.session_class.new   
    brands = get_avail_printer_brands(sesh,logfile)
    
    # Try selecting every brand
    brands.each do |brand| 
      brand_test(sesh, brand, logfile)
    end
  
    close_log logfile 
  end
  
  desc "Testing the search box"
  task :search => :environment do 
    
    setup
    sesh = Webrat.session_class.new
    logfile =  setup_log("search")
    
    # Printer brand names
    brands = get_avail_printer_brands(sesh, logfile)
    search_test( brands, sesh, logfile)
    
    # Now all lowercase
    brands.each{ |x| x.downcase! } 
    search_test( brands, sesh, logfile)
    
    # Other search strings
    other = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]
    search_test( other, sesh, logfile)

    close_log logfile 

  end
  
  desc "Exhaustive testing for Browse Similar"
  task :browse_similar => :environment do
    setup
    sesh = Webrat.session_class.new
    logfile = setup_log "browse_similar" 
    
    get_homepage(sesh, logfile)
    hist = ["root"]
    explore(sesh,hist,logfile)
    
    close_log logfile
  end
   
  # Tests the brand selector for the given brand.
  def brand_test(sesh, brand, log)
    get_homepage(sesh, log)
  
    doc = sesh.response.parser   # Parser of WWW::Mechanize::Page should be a Nokogiri::HTML object
    num_brands_before = doc.css('a[title="Remove Brand Filter"]').length
    num_printers_before = num_printers(doc)
    begin 
      sesh.select brand
      sesh.submit_form "filter_form" # When no submit button present use form id.           
    rescue Exception => e # This detects crashing.
      report_error(log, e.type.to_s + " with " + brand+ ", message:" + e.message.to_s)
    else
      report_error( log, "get error page after" + brand) if error_page?(sesh)
      doc = sesh.response.parser   # Parser of WWW::Mechanize::Page should be a Nokogiri::HTML object
      num_brands_after = doc.css('a[title="Remove Brand Filter"]').length
      num_printers_after = num_printers(doc)
      log.puts "LOGGER      Number of printers selected is "  + num_printers_after
      log.puts "No printers found for "+ brand if none_selected? doc
      
      # ERROR CHECKING CODE. 
      if brand == "All Brands" or brand == "Add Another Brand" 
        if(num_brands_before != num_brands_after)
          report_error log, "# brands shown changed and" + brand + " selected" 
        end
        if(num_printers_before != num_printers_after)
          report_error log, "# printers changed and" + brand + " selected" 
        end
      else
        if num_brands_before == num_brands_after 
         if !none_selected?(doc) 
           report_error "# brands not incremented for " + brand + " and 'no matching printers' message not shown."
         end
         if num_printers_before != num_printers_after
           report_error log, "# brands not incremented for " + brand + " and # of printers changed"
         end
        elsif num_brands_before == num_brands_after - 1 
          if num_printers_before == num_printers_after   
            report_error log, "# brands incremented for " + brand + " although no new products found" 
          end
          if none_selected?(doc)  
            report_error log, "# brands incremented for " + brand + " and 'no matching printers' message showing." 
          end
        else
          report_error log, "# brands changed by " + (num_brands_after - num_brands_before).to_s + " for " + brand
        end
      end
      # END of the error checking code.
      
    end
  end
  
  # Tests each query string in the array and uses the session given.
  def search_test( queries, session, logger)
    queries.each do |query| 
      get_homepage(session, logger)
      begin
        logger.puts "LOGGER    Searching for " + query        
        session.fill_in "search", :with => query
        session.click_button "submit_button" 
      rescue Exception => e
        report_error(logger, "Error with search string '" + query + "'")
        logger.puts e.type.to_s
        logger.puts e.message.to_s
      else
        report_error( log, "get error page searching for " + brand) if error_page?(session)
        doc = session.response.parser
        logger.puts "LOGGER    Search gives 0 results" if none_selected? doc 
        logger.puts "LOGGER    Done searching for '" + query + "'"
      end
    end
  end
  
  # Recursive method to click all browse_similar
  # and check for errors.
  def explore(session, hist, logfile)
    doc = session.response.parser                      # Parser of WWW::Mechanize::Page should be a Nokogiri::HTML object
    highest_link_index = doc.css(".sim").length - 1    # Find num of clicky boxes
    
    # Log stuff
    logfile.puts "LOGGER : url when boxes calculated :   " + session.current_url
    logfile.puts "LOGGER : # boxes =                  "+doc.css(".borderbox").length.to_s
    logfile.puts "LOGGER : # links =                  #{highest_link_index+1}"
  
    (0..highest_link_index).each do |num|
      return_here = session.current_url # Current page
      
      begin        
         session.click_link 'sim'+num.to_s
      rescue Exception => e
        report_error(logger, "Error with link number #{num} and history" + hist + "'")
        logfile.puts e.type.to_s + e.message.to_s
      else
        logfile.puts "LOGGER: session url :                 " + session.current_url
        hist << (num+1).to_s
        logfile.puts "LOGGER : history :                    "+ (hist * ',').to_s
        
        # ERROR CHECKING CODE
        
        doc = session.response.parser
        num_boxes = doc.css(".borderbox").length.to_s
        num_printers_showing = num_printers(doc)
        report_error(logfile, "No borderboxes") if  num_boxes.to_i == 0
        report_error(logfile, "Get the error page") if error_page?(session)
        if num_printers_showing.to_i < 10 
          if num_boxes.to_i != num_printers_showing.to_i
            report_error logfile, "number of borderboxes: " + num_boxes +", number of printers :" +num_printers_showing
          end
          if doc.css(".sim").length != 0
            report_error logfile, doc.css(".sim").length.to_s + " Similar Links showing with " + num_printers_showing +" printers displayed." 
          end
        else 
          if doc.css(".sim").length != 9
            report_error logfile, doc.css(".sim").length.to_s + " Similar Links showing with " + num_printers_showing +" printers displayed." 
          end
          report_error logfile, "Less than 9 boxes for"+ num_printers_showing +" printers" if num_boxes.to_i < 9
        end
        
        # END OF ERROR CHECKING CODE
        
      end
     
      # Recursive!
      explore(session,hist,logfile)
      hist.pop
      session.visit return_here

     end
  end
  
  # Tells you if there is a "No printers selected" message displayed.
  def none_selected?(doc)
    # Message is in the first span tag in the div with id main.
    msg_span = doc.css(".main span").first.content.to_s
    # TODO we should give this span tag an id! 
    printer_phrase = msg_span.match('No products ').to_s
    return (printer_phrase.length > 0)
  end
  
  # Returns the number of printers on a printers/list type page.
  # Very useful for checking if filtering did anything.
  def num_printers(doc)
    leftbar = doc.css("#leftbar").first.content.to_s
    printer_phrase = leftbar.match('Browsing \d+ Printers').to_s
    num_printers = printer_phrase.match('\d+').to_s
    return num_printers
  end
  
  # Returns true if the page's response is the error page.
  # TODO doesn't work too well.
  def error_page?(sesh)
     return true if sesh.current_url == "http://localhost:3000/error"
     return true if "http://localhost:3000/error".eql?(sesh.current_url) 
     doc = sesh.response.parser
     bd_div = doc.css('div.bd').first.content.to_s
     err_msg = bd_div.match("We're sorry but the website has experienced an error").to_s
     return true if err_msg.length > 0
     return false
  end
  
  def close_log(logfile)
      puts "Test completed. Log file at " + logfile.path
      logfile.close
  end
  
  def setup_log(name)
    file = File.open("./log/printertest_"+name+".log", 'w+')
  end
  
  # Puts the error both in the logfile and on the console.
  def report_error(logfile, msg)
    logfile.puts "ERROR  " + msg
    puts "ERROR " + msg
  end
  
  # Gets the homepage and makes sure nothing crashed.
  def get_homepage(my_session, log) # TODO my_session,log
    # Check that it doesn't give you error page right away
    my_session.visit "http://localhost:3000/"
    if error_page?(my_session)
      report_error(log, "Error loading homepage")
      raise "Error loading homepage" # TODO Should we just log it instead of throwing an exception?
    end
    
  end
  
  # Gets printer brand name list from drop-down menu on main page
  def get_avail_printer_brands( sesh, log)
    get_homepage(sesh, log)
    doc = sesh.response.parser
    selector_options = doc.css("#myfilter_brand option")
    brand_names = []
    selector_options.each { |opt| brand_names << opt.attribute("value").to_s}
    return brand_names
  end
  
  # Sets up env and related stuff
  def setup()
    # Check for all the right configs
    raise "Rails test environment not being used." if ENV["RAILS_ENV"] != 'test' 
    #raise  "Forgery protection turned on in test environment."  if (ActionController::Base.allow_forgery_protection) 
    
    # Requires.
    require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
    require 'webrat'
    require 'mechanize' # Needed to make Webrat work
    
    Webrat.configure do |conf|
      conf.mode = :mechanize # Can't be rails or Webrat won't work
    end

  end
  
end