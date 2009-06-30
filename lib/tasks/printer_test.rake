# Some tests for the laser printer site.
namespace :printer_test do   

  require 'printer_test_asserts'
  include PrinterTestAsserts

  # ------------------- TESTING ALGORITHMS ---------------------#
  
   desc 'Run all tests.'
   task :all => [:tricky, :sliders, :browse_similar, :search, :brand_selector, :random, :random_nojava]
  
   desc 'A series of clever moves to get back button errors.'
   task :tricky => :environment do
       setup "tricky" 

       test_back_button

       (@sesh.num_brands_in_dropdown-1).times{ |i|
         (@sesh.num_brands_in_dropdown-1).times{ |j|
           test_click_home_logo
           test_add_brand i+1
           one_brand = @sesh.num_printers
           test_add_brand j+1
           both_brands = @sesh.num_printers
           test_back_button
           one_brand_return = @sesh.num_printers

           report_error "Was #{one_brand} printers, now #{one_brand_return}." if one_brand != one_brand_return
         }
       }
       close_log
   end

   desc "Test the sliders."
   task :sliders => :environment do
     setup "sliders" 

     20.times do
       pick_slider = rand @sesh.num_sliders

       distance =@sesh.slider_min(pick_slider) + rand(@sesh.slider_range(pick_slider))
       # TODO This tests integer inputs ONLY!
       # TODO Testing non-integers might require changes in my assert code!
       log "Testing the " + @sesh.slider_name(pick_slider) + " slider. Moving it to " +  distance.to_s

       new_min = @sesh.current_slider_min(pick_slider)
       new_max = @sesh.current_slider_max(pick_slider)
       (rand >= 0.5)? new_min = distance : new_max = distance

       test_move_sliders(pick_slider, new_min, new_max)

     end

     close_log
   end

   desc "Test the brand selector."
   task :brand_selector => :environment do 
     setup "brand_selector" 

     # Try selecting every brand
     (1..@sesh.num_brands_in_dropdown).each do |brand| 
       test_add_brand (brand - 1)      
       test_click_home_logo
     end

     close_log
   end

   desc "Test the search box."
   task :search => :environment do 
       setup "search"

       # Brand name based search strings
       (1..@sesh.num_brands_in_dropdown).each do |brand| 
         test_search_for @sesh.brand_name(brand)
         test_search_for @sesh.brand_name(brand).downcase         
       end

     # Other search strings
     other = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]
     other.each do |x|
       test_search_for x
     end

     close_log
   end

   desc "Exhaustive testing for Browse Similar."
   task :browse_similar => :environment do
     setup "browse_similar" 

     hist = ["root"]
     explore(hist)

     close_log
   end

   # Recursive method to test all browse_similar.
   def explore(hist)
     previous_url = @sesh.current_url
     (1..@sesh.num_similar_links).each do |num|
       log "Testing #{num}th browse similar link with history: " + hist * ", "
       come_back_here = @sesh.current_url
       test_browse_similar(num)
       hist << num.to_s
       explore(hist)
       hist.pop
       @sesh.visit come_back_here
     end
   end

   desc "Simulate a user session and test almost everything."
   task :random => :environment do
       setup_java "random" 

       search_strings = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]

       (@sesh.num_brands_in_dropdown-1).times do |x| 
         bname = @sesh.brand_name (x+1)
         search_strings << bname
         search_strings << bname.downcase
       end

       20.times do

         pick_action = (rand 10).floor
         # For the error page, the # of possible actions is very limited.
         pick_action = (8 + rand(2)).floor if @sesh.error_page?

         if pick_action == 0                     #0 Test move sliders.
           slide_me = rand @sesh.num_sliders

           offset = rand(@sesh.slider_range(slide_me))
           distance = @sesh.slider_min(slide_me).floor + offset

           new_min = @sesh.current_slider_min(slide_me)
           new_max = @sesh.current_slider_max(slide_me)
           (rand >= 0.5)? new_min = distance : new_max = distance

           test_move_sliders(slide_me, new_min, new_max)
         elsif pick_action == 1                  #1 Test add brand
           brand_to_add = rand(@sesh.num_brands_in_dropdown)
           test_add_brand brand_to_add
         elsif pick_action == 2                  #2 Test search
           search_me = search_strings[rand(search_strings.length)] 
           rand(2).times do 
             (rand >= 0.5)? connector = " and " : connector = ' or '
             search_me += connector + search_strings[rand(search_strings.length)] 
           end
           test_search_for search_me
         elsif pick_action == 3                 #3 Test browse similar
           if @sesh.num_similar_links > 0
             click_me = (rand( @sesh.num_similar_links) + 1).floor
             test_browse_similar click_me
           end
         elsif pick_action == 4                  #4 Test clear search
           if @sesh.num_clear_search_links > 0
             test_remove_search 
           end
         elsif pick_action == 5                 #5 Test save item
            save_me = (rand( @sesh.num_boxes) + 1).floor
            test_save_item save_me
         elsif pick_action == 6                 #6 Test remove saved item
           if @sesh.num_saved_items > 0
             unsave_me = (rand(@sesh.num_saved_items) + 1).floor
             test_remove_saved unsave_me
           end
         elsif pick_action == 7                 #5 Test remove brand
           if( @sesh.num_brands_selected > 0 )
             deselect_me = (rand(@sesh.num_brands_selected) + 1).floor
             test_remove_brand deselect_me
           end
         elsif pick_action == 8                  #5 Test home logo
             test_click_home_logo
         elsif pick_action == 9                  #6 Test back button
           test_back_button
         end

       end

       close_log
   end

   desc "Simulate a user session and test almost everything."
   task :random_nojava => :environment do
       setup "random" 

       search_strings = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]

       (@sesh.num_brands_in_dropdown-1).times do |x| 
         bname = @sesh.brand_name (x+1)
         search_strings << bname
         search_strings << bname.downcase
       end

       50.times do

         pick_action = rand 7
         # For the error page, the # of possible actions is very limited.
         pick_action = 5 + rand(2) if @sesh.error_page?

         if pick_action == 0                     #0 Test move sliders.
           slide_me = rand @sesh.num_sliders

           offset = rand(@sesh.slider_range(slide_me))
           distance = @sesh.slider_min(slide_me).floor + offset

           new_min = @sesh.current_slider_min(slide_me)
           new_max = @sesh.current_slider_max(slide_me)
           (rand >= 0.5)? new_min = distance : new_max = distance

           test_move_sliders(slide_me, new_min, new_max)
         elsif pick_action == 1                  #1 Test add brand
           brand_to_add = rand(@sesh.num_brands_in_dropdown)
           test_add_brand brand_to_add
         elsif pick_action == 2                  #2 Test search
           search_me = search_strings[rand(search_strings.length)] 
           rand(2).times do 
             (rand >= 0.5)? connector = " and " : connector = ' or '
             search_me += connector + search_strings[rand(search_strings.length)] 
           end
           test_search_for search_me
         elsif pick_action == 3                 #3 Test browse similar
           if @sesh.num_similar_links > 0
             click_me = rand( @sesh.num_similar_links) + 1
             test_browse_similar click_me
           end
         elsif pick_action == 4                  #4 Test clear search
           if @sesh.num_clear_search_links > 0
             test_remove_search 
           end
         elsif pick_action == 5                  #5 Test home logo
             test_click_home_logo
         elsif pick_action == 6                  #6 Test back button
           test_back_button
         end

       end

       close_log
   end

   # ------------------ POSSIBLE USER ACTIONS ----------------------#

   def test_move_sliders(slider, min, max)
     log "Testing the " + @sesh.slider_name(slider) + " slider. Moving it to (#{min},#{max})"
     snapshot

     begin
       # TODO change methods to move_slider
       @sesh.move_slider(slider, min, max)
     rescue Exception => e
       report_error e.type.to_s + e.message.to_s
     else
       assert_not_error_page
       assert_well_formed_page
       assert_saveds_same
       assert_brands_same
       assert_clear_search_links_same

       if !@sesh.no_printers_found_msg? 
         assert_slider_range(slider, min, max)
         #assert_slider_range(slider, min.floor, max.ceil)
       end

       if min > max
         assert_no_results_msg_displayed
       end
     end
     log "Done testing move sliders"
   end

   def test_back_button
     log "Testing the back button."
     begin
       @sesh.click_back_button
     rescue Exception => e
       report_error e.type.to_s + e.message.to_s
     else
       @history.pop

       # Just like status quo except no snapshot taken before, so we're comparing to last time
       assert_brands_same
       assert_saveds_same
       assert_num_printers_same
       assert_clear_search_links_same
       assert_session_id_same

     end
     log "Done back button test"
   end

   def test_goto_homepage

     log "Testing Goto Homepage"
     snapshot
     @sesh.get_homepage

     assert_brands_clear
     assert_search_history_clear
     assert_saveds_clear
     assert_no_results_msg_hidden
     assert_browsing_all_printers
     assert_sliders_clear

     log "Done testing goto homepage"

   end

   def test_click_home_logo

     log "Testing Click Homepage logo"
     snapshot
     @sesh.click_home_logo
     
     assert_brands_clear
     assert_search_history_clear
     assert_saveds_clear
     assert_no_results_msg_hidden
     assert_browsing_all_printers
     assert_sliders_clear

     log "Done testing click homepage logo"
   end

   def test_browse_similar which_link

     log "Clicking on the #{which_link} browse similar link"
     snapshot

     begin        
       @sesh.click_browse_similar which_link
     rescue Exception => e
       report_error "Error with box number #{which_link} \n" + e.type.to_s + e.message.to_s
     else
       assert_not_error_page
       assert_well_formed_page
       assert_num_printers_decreased
     end

     log "Done testing browse similar"
   end

   def test_search_for query
     log "Searching for " + query
     snapshot

     begin
       @sesh.search_for query
     rescue Exception => e
       report_error "Error with search string '" + query + "'" + "\n" + e.type.to_s + e.message.to_s
     else
       assert_not_error_page
       assert_well_formed_page

       if @sesh.no_printers_found_msg?
         assert_clear_search_links_same
         log "No printers found for " + query
       else
         assert_has_search_history
       end

     end

     log "Done searching"
   end

   def test_remove_search
     log "Testing clear search history"
     snapshot
     begin
       @sesh.click_clear_search
     rescue Exception => e
       report_error "Clear search history error, " + e.type.to_s + e.message.to_s
     else
     # TODO more asserts?
      assert_not_error_page
      assert_well_formed_page
   
      assert_search_history_clear
      assert_brands_same
      assert_saveds_same
      assert_session_id_same
    end
    log "Done testing clear search history."
   end
   
   def test_add_brand brand
     log "Adding brand " + @sesh.brand_name(brand)
     # Preconditions & stuff.
     snapshot
     @brand_selected_before = @sesh.brand_selected? brand
   
     begin 
       @sesh.select_brand brand          
     rescue Exception => e # This detects crashing.
       report_error e.type.to_s + " with " + @sesh.brand_name(brand) + ", message:" + e.message.to_s
     else
       assert_not_error_page
       assert_well_formed_page
   
       if @sesh.brand_name(brand) == "All Brands" or @sesh.brand_name(brand) == "Add Another Brand"
         assert_brands_same
         assert_num_printers_same
       elsif brand == 0
         puts "But it should be going to the loop above"
   
       elsif @brand_selected_before
         log "This brand was selected before."
         assert_num_printers_same
         assert_brand_selected brand
   
       elsif @sesh.no_printers_found_msg?
         log "There were no printers found for this brand."
         assert_brand_deselected brand
         assert_num_printers_same
         assert_brands_same
   
       else
         assert_brand_selected brand
         # TODO other asserts!
       end
   
     end
   
     log "Done testing add brand " + @sesh.brand_name(brand)
   end
   
   def test_save_item which_item
     
     return unless java_enabled?
     
     log "Saving item number #{which_item}"
     snapshot
     
     pid_to_save = @sesh.pid_by_box which_item
     log "Product being saved has id #{pid_to_save}"
     already_saved = @sesh.was_saved?( pid_to_save)
     
     begin
       @sesh.selenium.click "xpath=(//a[@class='save'])[#{which_item}]"
       @sesh.wait_for_ajax
     rescue Exception => e
       report_error "Crashed while saving item. Error: " + e.type.to_s + e.message.to_s
     else
       assert_not_error_page
       assert_well_formed_page
       
       assert_item_saved pid_to_save
       if already_saved
         assert_saveds_same
         assert_already_saved_msg_displayed
       else
        assert_saveds_incremented 
         assert_already_saved_msg_hidden
       end
     end
     log "Done testing save item."
   end
   
   def test_remove_saved which_saved
     
     return unless java_enabled?
     
     log "Removing #{which_saved}th saved item."
     snapshot
     
     begin
       @sesh.selenium.click "xpath=(//div[@class='saveditem']/a)[#{which_saved}]" 
       @sesh.wait_for_ajax
     rescue Exception => e
       report_error "Crashed while removing saved item. Error: " + e.type.to_s + e.message.to_s
     else
         assert_not_error_page
         assert_well_formed_page
         assert_already_saved_msg_hidden
       #assert_item_not_saved pid_to_remove
       
     end
     log "Done testing remove saved."
   end
   
   def test_remove_brand which_brand
     
     return unless java_enabled?
     
     log "Testing remove brand"
     snapshot
     
     link_xpath = "(//a[@title='Remove Brand Filter'])[#{which_brand}]"
     removed_name = @sesh.doc.xpath(link_xpath+"/@href").first.to_s.gsub("javascript:removeBrand('"){''}.gsub("');"){''}
     
     log "Removing " + removed_name + ", #{which_brand}th brand in the list."
     
     begin
       @sesh.selenium.click ("xpath=" +link_xpath)
       @sesh.wait_for_ajax
       @sesh.wait_for_load
     rescue Exception => e
       report_error "Error removing #{which_brand}th brand. " + e.type.to_s + e.message.to_s
     else
       assert_not_error_page
       assert_well_formed_page
       removed_id = @sesh.brand_id removed_name
       assert_brand_deselected removed_id
     end
     log "Done removing brand"
   end
   
   def test_status_quo
      log "Testing status quo (not doing anything)"

      snapshot

      assert_brands_same
      assert_saveds_same
      assert_num_printers_same
      assert_clear_search_links_same
      assert_session_id_same
      
      log "Done testing status quo"
   end

  # ---------------- HELPER METHODS ----------------- #

   def java_enabled?
     return true if(@sesh.type == JavaTestSession)
     return false
   end
   
    # Take a 'snapshot' of the current page for comparison for later.
   def snapshot
      @num_printers_before = @sesh.num_printers
      @num_brands_selected_before = @sesh.num_brands_selected
      @num_boxes_before = @sesh.num_boxes
      @num_saved_items_before = @sesh.num_saved_items
      @num_similar_links_before = @sesh.num_similar_links
      @num_clear_search_links_before = @sesh.num_clear_search_links
      @session_id_before = @sesh.session_id 
      @no_printers_found_msg_before = @sesh.no_printers_found_msg?
      @error_page_before = @sesh.error_page?
      @url_before = @sesh.current_url
      @history.push @sesh.current_url
   end
    
   def log msg
     @logfile.puts "LOGGER      " + msg
   end
   
   def report_error msg
     @logfile.puts "ERROR      " + msg
     puts "ERROR: " + msg
   end
   
   def close_log
       puts "Test completed. Log file at " + @logfile.path
       @logfile.close
   end
   
   def setup_log(name)
     @logfile = File.open("./log/printertest_"+name+".log", 'w+')
   end
   
   def setup logname
     setup_env
     setup_log logname 
     @sesh = TestSession.new @logfile
     @history = []
     snapshot
   end
   
   def setup_java logname
    setup_java_env
    setup_log "java_"+logname 
    @sesh = JavaTestSession.new @logfile
    @history = []
    snapshot
   end

   def setup_env
    # Check for all the right configs
    #raise "Rails test environment not being used." if ENV["RAILS_ENV"] != 'test' 
    #raise  "Forgery protection turned on in test environment."  if (ActionController::Base.allow_forgery_protection) 

  # Requires.
     require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
     require 'webrat'
     require 'mechanize' # Needed to make Webrat work
     require 'test_session'

      Webrat.configure do |conf| 
       conf.mode = :mechanize  # Can't be rails or Webrat won't work 
      end
      
      WWW::Mechanize.html_parser = Nokogiri::HTML
      
   end

   def setup_java_env
   # Check for all the right configs
   #raise "Rails test environment not being used." if ENV["RAILS_ENV"] != 'test' 
   #raise  "Forgery protection turned on in test environment."  if (ActionController::Base.allow_forgery_protection) 
   
     require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
     require 'webrat'
     require 'webrat/selenium'
     require 'java_test_session'
   
     Webrat.configure do |config|
       config.mode = :selenium 
     end
   
   end
end