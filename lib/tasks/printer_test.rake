# Some tests for the laser printer site.
namespace :printer_test do 

  desc "Exhaustive testing for Browse Similar"
  task :browse_similar => :environment do
    # Sets up the env
    ENV["RAILS_ENV"] = "test"
    require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
    require 'webrat'
    require 'webrat/core/matchers'
    require 'mechanize' # Needed to make Webrat work
    require 'nokogiri'
    
    Webrat.configure do |config|
      config.mode = :mechanize # Can't be rails or Webrat won't work
    end
    
    # Set up log file
    logfile = File.open("./log/printer_test_log.txt", 'w+')
        
    # Starts a Webrat session & goes to the homepage! :)
    sesh = Webrat.session_class.new
    sesh.visit "http://localhost:3000/"
    hist = "root"
    explore(sesh,hist,logfile)
    
    # Close logfile
    puts "Done! Log file at " + logfile.path
    logfile.close
    
  end
  
  def explore(session, hist, logfile)
    
    
    
    # Find # of clicky boxes & make array of their indices
    #TODO hacky, eww
    doc = Nokogiri::HTML(open(session.current_url))  
    num_boxes_less_one = doc.css(".sim").length - 1
    similars =  0..num_boxes_less_one
    
    # Check for ERRORS!!!
    if doc.css(".borderbox").length == 0
        report_error(logfile)
    end
    
    if "http://localhost:3000/error".eql?(session.current_url) 
        report_error(logfile)
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
  
  def report_error(logfile)
    logfile.puts "ERROR!!"
    puts "ERROR!!"
  end
end