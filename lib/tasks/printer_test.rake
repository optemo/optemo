# Some tests for the laser printer site.
namespace :printer_test do   
   
  desc "Test the brand selector"
  task :brand_selector => :environment do 
  
    setup
    logfile = setup_log "brand_selector" 
    
    sesh = Webrat.session_class.new   
    brands = get_avail_printer_brands(sesh,logfile)
    
    # Try selecting every brand
    brands.each do |brand| 
      brand_test(sesh, brand, log)
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
  
  def brand_test(sesh, brand, log)
    get_homepage(sesh, log)
  
    doc = sesh.response.parser   # Parser of WWW::Mechanize::Page should be a Nokogiri::HTML object
    brands_selected_pre = doc.css('a[title="Remove Brand Filter"]')
    
    begin 
      sesh.select brand
      sesh.submit_form "filter_form" # When no submit button present use form id.           
    rescue Exception => e # This detects crashing.
      report_error(log, "ERROR " + e.type.to_s + " with " + brand)
      report_error(log, "ERROR message:" + e.message.to_s )
    else
      report_error( log, "ERROR: get error page after" + brand) if error_page?(sesh)
      # Check if updated
      brands_selected_post = doc.css('a[title="Remove Brand Filter"]')
      puts "ERROR: # brands selected not increased by one" if brands_selected_post.length - 1 != brands_selected_pre.length
      # WIll this work? puts "ERROR: brand not selected" if !brands_selected_post.contains(brand)
    end
  end
  
  # Tests each query string in the array and uses the session given.
  def search_test( queries, session, logger)
    queries.each do |query| 
      get_homepage(session, logger)
      begin        
        session.fill_in "search", :with => query
        session.click_button "submit_button" 
      rescue Exception => e
        report_error(logger, "Error with search string '" + query + "'")
        logger.puts e.type.to_s
        logger.puts e.message.to_s
      else
        report_error( log, "ERROR: get error page searching for " + brand) if error_page?(sesh)
        logger.puts "Done searching for '" + query + "'"
      end
    end
  end
  
  # Recursive method to click all browse_similar
  def explore(session, hist, logfile)
    doc = session.response.parser                      # Parser of WWW::Mechanize::Page should be a Nokogiri::HTML object
    num_boxes_less_one = doc.css(".sim").length - 1    # Find num of clicky boxes
    similars =  0..num_boxes_less_one                  # Make array of their indices
    
    # Check for ERRORS!!!
    if doc.css(".borderbox").length == 0               # If there are no borderboxes
        report_error(logfile, "No borderboxes")
    end
    
    if "http://localhost:3000/error".eql?(session.current_url) # If error page
        report_error(logfile, "Get the error page")
    end
  
    # Log stuff
    logfile.puts "LOGGER : url when boxes calculated :   " + session.current_url
    logfile.puts "LOGGER : # boxes =                  #{num_boxes_less_one+1}"
  
    (0..num_boxes_less_one).each do |num|
      return_here = session.current_url # Where we are
      
      session.click_link 'sim'+num.to_s
      
      # Log stuff
      # TODO make it use a stack type thing.
      logfile.puts "LOGGER: session url :                 " + session.current_url
      hist << '#{num+1}'
      logfile.puts "LOGGER : history :                    "+ (hist * ',').to_s
      
      # Recursive!
      explore(session,hist,logfile)
      
      # Log stuff
      hist.pop
      
      session.visit return_here # Go back to where we were (hit the back button)
     end
  end
  
  # Returns true if the page's response is the error page.
  # TODO doesn't work too well.
  def error_page?(sesh)
     is_err_page = false
     is_err_page = (is_err_page || sesh.current_url == "http://localhost:3000/error")
     is_err_page = (is_err_page ||"http://localhost:3000/error".eql?(sesh.current_url) )
     #doc = sesh.response.parser
     #is_err_page = (is_err_page ||doc.css('#error_space>*').length.to_i > 0 )
     #puts "doc.css('#error_space>*').length.to_i > 0" + (doc.css('#error_space>*').length.to_i > 0).to_s
     return is_err_page
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
    raise  "Forgery protection turned on in test environment."  if (ActionController::Base.allow_forgery_protection) 
    
    # Requires.
    require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
    require 'webrat'
    require 'mechanize' # Needed to make Webrat work
    
    Webrat.configure do |conf|
      conf.mode = :mechanize # Can't be rails or Webrat won't work
    end
      
      
  end
end