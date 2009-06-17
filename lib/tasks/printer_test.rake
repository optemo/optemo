# Some tests for the laser printer site.
namespace :printer_test do   
   
    desc "Test the brand selector"
    task :brand_selector => :environment do 

      setup
      sesh = Webrat.session_class.new   
            
      # Printer brand names
      brands = ["Brother","Hewlett-Packard","Samsung","Xerox","Lexmark","Oki Data","Konica","Ricoh","Tektronix","Tally"]

      brands.each do |brand| 
        get_homepage(sesh)
        
        begin        
          doc = sesh.response.parser   # Parser of WWW::Mechanize::Page should be a Nokogiri::HTML object
      
          # TODO: Pre?
          num_brands_before = doc.css('a[title="Remove Brand Filter"]').length.to_i
          
          sesh.select brand
          sesh.submit_form "filter_form" # When no submit button present use form id.
               
         # TODO: Post?
         if error_page?(sesh)
           puts "ERROR: get error page after" + brand
         end
                  
         # Check if updated
         puts "# boxes after:" + doc.css(".sim").length.to_s
         puts "# brands after: " + doc.css('a[title="Remove Brand Filter"]').length.to_s
        rescue Exception => e # This detects crashing.
          msg1 = "ERROR " + e.type + " with " + brand
          msg2 = "ERROR message:" + e.message
          puts msg1
          puts msg2
        end
      end
 
    end
  
  desc "Testing the search box"
  task :search => [:environment] do 
    
    setup
    sesh = Webrat.session_class.new
    get_homepage(sesh)
    
    # Printer brand names
    brands = ["Brother","Hewlett-Packard","Samsung","Xerox","Lexmark","Oki Data","Konica","Ricoh","Tektronix","Tally"]
    search_test( brands, sesh)
    
    # Now all lowercase
    brands.each{ |x| x.downcase! } 
    search_test( brands, sesh)
    
    # Other search strings
    other = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]
    search_test( other, sesh)

  end

  desc "Exhaustive testing for Browse Similar"
  task :browse_similar => :environment do
    setup
    
    # Set up log file
    logfile = File.open("./log/printer_test_log.txt", 'w+')
        
    # Starts a Webrat session & goes to the homepage! :)
    sesh = Webrat.session_class.new
    get_homepage(sesh)
    hist = "root"
    explore(sesh,hist,logfile)
    
    # Close logfile
    puts "Done! Log file at " + logfile.path
    logfile.close
    
  end
  
  def search_test( queries, session)
    queries.each do |query| 
      get_homepage(session)
      begin        
        session.fill_in "search", :with => query
        session.click_button "submit_button" 
        # TODO: check for stuff otherwise put error.
        doc = session.response.parser   # Parser of WWW::Mechanize::Page should be a Nokogiri::HTML object
        # 1. check sesh url
        # 2. either none found msg or # printers showing is < before.
        
        puts "Success with search string '" + query + "'"
      rescue Exception => e
        puts "Error with search string '" + query + "'"
        puts e.type
        puts e.message
      end
    end
  end
  
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
      logfile.puts "LOGGER: session url :                 " + session.current_url
      hist_old = hist
      hist += ",#{num+1}"
      logfile.puts "LOGGER : history :                    "+ hist
      
      # Recursive!
      explore(session,hist,logfile)
      
      # Log stuff
      hist = hist_old
      
      session.visit return_here # Go back to where we were (hit the back button)
     end
  end
  
  def error_page?(sesh)
     is_err_page = false
     is_err_page = (is_err_page || sesh.current_url == "http://localhost:3000/error")
     is_err_page = (is_err_page ||"http://localhost:3000/error".eql?(sesh.current_url) )
     
     doc = sesh.response.parser
     is_err_page = (is_err_page ||doc.css('#error_space').length.to_i > 0 )
     
     return is_err_page
  end
  
  def report_error(logfile, msg)
    logfile.puts "ERROR  " + msg
    puts "ERROR " + msg
  end
  
  def get_homepage(my_session)
    # Check that it doesn't give you error page right away
    my_session.visit "http://localhost:3000/"
    raise "Error on load homepage" if error_page?(my_session)
  end
  
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