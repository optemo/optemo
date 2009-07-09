# Some tests for the laser printer site.
namespace :printer_test do   

  # ------------------- TESTING ALGORITHMS ---------------------#
  desc "EVERYTHING!!!"
  task :all => [:sliders,:brand_selector,:search,:browse_similar]
  
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
  
  desc 'Ignore me please.'
  task :sandbox => :environment do
    setup 'sandbox'
    #this works
    #puts @sesh.current_url
    #@sesh.within('#header') do |scope| scope.click_link('LaserPrinterHub.com') end
    #puts @sesh.current_url
    
    # This works
    #@sesh.within('.navigator_box:nth-of-type(2)') do |scope| scope.dom end
    
    
    #@sesh.visit('file:///Users/maria/Desktop/sandbox/index.html')
    
    #@sesh.visit('file:///Users/maria/Desktop/sandbox/links_w_javascript.html'
  
   # begin
    #  @sesh.click_link "2"
   # rescue Exception =>e
  #    puts "Exception on link 2:" + e.message.to_s + e.type.to_s
  #  end
  #  
  #  begin
  #    @sesh.click_link "1"
  #  rescue Exception =>e
  #    puts "Exception on link 1:" + e.message.to_s + e.type.to_s
  #  end
  #  
  #  begin
  #    @sesh.visit 'alert("Works")'
  #  rescue Exception =>e
  #    puts "Exception on link 1:" + e.message.to_s + e.type.to_s
  #  end
    
    
    #@sesh.click_link 'Save it'
    #@sesh.visit 'javascript:saveit(227)'
    
    
    
   # test_add_brand 1
    #puts @sesh.num_brands_selected
    
     
    #@sesh.click_link 'Remove'
    #@sesh.visit "javascript:removeBrand('Brother');"
      
    #Try this
    #@sesh.within('.navigator_box:nth-of-type(2)') do |scope| scope.click_link "Save it" end
    
   # puts @sesh.num_saved_items.to_s + " saveds"
   # test_add_brand 1
    #test_add_brand 2
   # puts @sesh.num_brands_selected
   # s
    # Try this
   # @sesh.click_link 'Remove'
    
   # puts @sesh.num_brands_selected
    
    # Gets me the last thing
   # @sesh.within('.selected_brands') do |scope| puts scope.dom end
    
    # Gives errors WTF WTF !!!!
    #@sesh.within('.selected_brands:nth-of-type(1)') do |scope| puts scope.dom end
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
      
      new_min = @sesh.slider_min(pick_slider)
      new_max = @sesh.slider_max(pick_slider)
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
      setup "random" 
      
      search_strings = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]
      
      (@sesh.num_brands_in_dropdown-1).times do |x| 
        bname = @sesh.brand_name (x+1)
        search_strings << bname
        search_strings << bname.downcase
      end
      
      20.times do
        
        pick_action = rand 7
        # For the error page, the # of possible actions is very limited.
        pick_action = 5 + rand(2) if @sesh.error_page?
        
        if pick_action == 0                     #0 Test move sliders.
          slide_me = rand @sesh.num_sliders

          offset = rand(@sesh.slider_range(slide_me))
          distance = @sesh.slider_min(slide_me) + offset
          
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
        elsif pick_action == 4                  #5 Test clear search
          if @sesh.num_clear_search_links > 0
            test_remove_search 
          end
        elsif pick_action == 5                  #6 Test home logo
            test_click_home_logo
        elsif pick_action == 6                  #7 Test back button
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
      @sesh.set_slider(slider, min, max)
      @sesh.submit_form "filter_form" # When no submit button present use form id.
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
      @sesh.click_link 'Go back to previous Printers'
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
    @sesh.click_link 'LaserPrinterHub.com'
    
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
      @sesh.click_link 'sim' + (which_link-1).to_s
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
      @sesh.fill_in "search", :with => query
      @sesh.click_button "submit_button" 
    rescue Exception => e
      report_error "Error with search string '" + query + "'" + "\n" + e.type.to_s + e.message.to_s
    else
      assert_not_error_page
      assert_well_formed_page
      
      if @sesh.no_printers_found_msg?
        assert_clear_search_links_same
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
       @sesh.click_link 'clearsearch'
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
       @sesh.submit_form "filter_form"           
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
   
   def test_remove_brand which_brand
     report_error "Please implement test_remove_brand. (Requires Selenium.) This test will be ignored and no code will be run."
     #snapshot
     #begin
    #   removed_name = @sesh.remove_nth_selected_brand(which_brand)
    # rescue Exception => e
    #   report_error "Error removing #{which_brand}th brand. " + e.type.to_s + e.message.to_s
    # else
    #   removed_id = @sesh.brand_id removed_name
    #   log "Removing #{removed_id}th brand selected: " + removed_name
    #   assert_brand_deselected removed_id
    # end
   end
   
   def test_status_quo
     log "Testing status quo (not doing anythign)"
     
     snapshot
     
     assert_brands_same
     assert_saveds_same
     assert_num_printers_same
     assert_clear_search_links_same
     assert_session_id_same
     log "Done testing status quo"
   end
  
   # ------ ASSERTS ------ #
   
   def assert_no_results_msg_displayed
     report_error "No results msg hidden" if !@sesh.no_printers_found_msg?
   end
   
   def assert_no_results_msg_hidden
     report_error "No results msg displayed" if @sesh.no_printers_found_msg?
   end
   
   def assert_not_error_page
     report_error "Error page displayed" if @sesh.error_page?
   end

   def assert_well_formed_page
     
     # More than 0 boxes
     report_error "No borderboxes" if @sesh.num_boxes == 0
     
     if @sesh.num_printers <= 9  
       
       if @sesh.num_similar_links > 0
         report_error "Browse similar links available when browsing less than 9 printers"
       end
       
       if @sesh.num_boxes !=@sesh.num_printers
          report_error @sesh.num_boxes.to_s + " boxes but " + @sesh.num_similar_links.to_s +  " 'explore similar' links."
       end
       
     end
     
     if @sesh.num_printers > 9 and @sesh.num_similar_links == 0
       report_error "Browse similar links not available when browsing more than 9 printers"
     end
       
     if @sesh.num_boxes < 9 and @sesh.num_printers >= 9
       report_error "Less than 9 borderboxes for 9 or more printers"
     end
     
     # TODO other checks?
     
   end
   
   def assert_brand_selected brand
     report_error @sesh.brand_name(brand) +" not selected" unless (@sesh.brand_selected?(brand))
   end
   
   def assert_brand_deselected brand
     report_error @sesh.brand_name(brand) + ", brand number #{brand}, selected" if @sesh.brand_selected? brand
   end
   
  def assert_brands_same
    report_error "# of brands was changed." if @sesh.num_brands_selected != @num_brands_selected_before
  end
  
  def assert_brands_clear
    report_error "Brands not cleared" if @sesh.num_brands_selected != 0 
  end
  
  def assert_slider_range slider, min, max
    actual_min = @sesh.current_slider_min slider
    actual_max = @sesh.current_slider_max slider
    if actual_min != min or actual_max != max
      report_error "Slider " + @sesh.slider_name(slider) + " has wrong range. Expected (#{min},#{max}) and got (#{actual_min}, #{actual_max}). " 
    end
  end
  
  def assert_sliders_clear
    # All sliders' current max/min match absolute max/min
    (0..@sesh.num_sliders-1).each do |slider|
       if @sesh.current_slider_min( slider ) != @sesh.slider_min( slider )
         report_error "Slider min not reset for " + @sesh.slider_name( slider ) + ", ie slider #{slider}"
         report_error "Expected " + @sesh.slider_min(slider).to_s + ", got " + @sesh.current_slider_min(slider).to_s
       end 
       if @sesh.current_slider_max (slider) != @sesh.slider_max (slider)
         report_error "Slider max not reset for " + @sesh.slider_name (slider) + ", ie slider #{slider}"
         report_error "Expected " + @sesh.slider_max(slider).to_s + ", got " + @sesh.current_slider_max(slider).to_s
       end
    end
  end
 
  def assert_saveds_incremented
   if @sesh.num_saved_items == @num_saved_items_before
     report_error "Saved item not added" 
   elsif @sesh.num_saved_items != @num_saved_items_before + 1
     report_error "Weird number of saved items: was #{@num_saved_items_before}, now " + @sesh.num_saved_items.to_s
   end
  end

  def assert_saveds_same
    report_error "# of saved items was changed." if @sesh.num_saved_items != @num_saved_items_before
  end
   
  def assert_saveds_clear
    report_error "Saved printers not cleared" if @sesh.num_saved_items != 0 
  end
  
  def assert_browsing_all_printers
  # Total printers = current browsing printers
    report_error "Not all printers displayed" if @sesh.total_printers != @sesh.num_printers
  
  end
  
  def assert_num_printers_decreased
    if @sesh.num_printers >= @num_printers_before
      report_error "Number of printers browsed not decreased: was #{@num_printers_before}, now " + @sesh.num_printers.to_s 
    end
  end
  
  def assert_num_printers_same
    if @sesh.num_printers != @num_printers_before
      report_error "Number of printers browsed changed. Was #{@num_printers_before}, now " + @sesh.num_printers.to_s
    end
  end
  
  def assert_num_printers_increased
    if @sesh.num_printers <= @num_printers_before
      report_error "Number of printers browsed not increased: was #{@num_printers_before}, now " + @sesh.num_printers.to_s 
    end
     
  end
  
  def assert_clear_search_links_same
    if @sesh.num_clear_search_links != @num_clear_search_links_before
      report_error "Different number of Clear Search link" 
    end
  end
  
  def assert_has_search_history
    if @sesh.num_clear_search_links == 0
      report_error "No Clear Search link" 
    end
  end
  
  def assert_search_history_clear
    report_error "Search not cleared" if @sesh.num_clear_search_links != 0
  end
  
  def assert_session_id_same
    report_error "Session ID changed" if @sesh.session_id != @session_id_before
  end
  
  def assert_session_id_changed
    report_error "Session ID same" if @sesh.session_id == @session_id_before
  end
  
 
 # ---------------- OTHER HELPER METHODS ----------------- #
 
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
    @sesh.report_error msg
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

  # Sets up env and related stuff
  def setup_env
   # Check for all the right configs
   #raise "Rails test environment not being used." if ENV["RAILS_ENV"] != 'test' 
   #raise  "Forgery protection turned on in test environment."  if (ActionController::Base.allow_forgery_protection) 
   
 # Requires.
    require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
    require 'nokogiri'
    require 'webrat'
    require 'mechanize' # Needed to make Webrat work
    require 'test_session'
  
     Webrat.configure do |conf| 
      conf.mode = :mechanize  # Can't be rails or Webrat won't work 
      conf.parse_with_nokogiri = true
     end
     WWW::Mechanize.html_parser = Nokogiri::HTML
   end

end