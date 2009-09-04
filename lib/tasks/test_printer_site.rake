# Rake tasks to test the Laserprinter website
namespace :printer_test do   

   desc 'Run all tests'
   task :all => [:sliders, :browse_similar, :search, :brand_selector, :random]
  
   desc 'Both randoms'
   task :all_random => [:random_nojava, :random]
  
   desc 'Run all tests.'
   task :all_nojava => [:sliders, :browse_similar, :search, :brand_selector, :homepage, :random_nojava]
   
   task :sandbox => :init do
     setup 'sandbox'
    test_search_for 'Xerox'
    test_remove_search
    close_log
   end
   
   desc 'Check and uncheck every chekbox'
   task :checkboxes => :java_init do
      setup_java 'checkboxes'
      @sesh.num_checkboxes.times do |i|
        2.times {test_checkbox i}
      end
      close_log
   end
   
   desc 'detail page'
   task :detail_page => :init do 
     setup 'detail_page'
      
     all_pages = []
     test_detail_page 0
     
     n = 1
     hist = [1]
     url_hist = [@sesh.current_url]
     
     while !url_hist.empty?
       if( @sesh.num_similar_links == 0 or @sesh.num_similar_links < n)
          all_pages << url_hist.pop
          n = hist.pop + 1
          @sesh.visit url_hist.last unless url_hist.empty?
       elsif(@sesh.num_similar_links >= n)
          @sesh.click_browse_similar n
          hist << n 
          url_hist << @sesh.current_url
       end
     end
     
     all_pages.each do |page|
       @sesh.visit page
       (0..@sesh.num_boxes-1).each do |n|
          @sesh.visit page
          test_detail_page n
       end
     end
     
     close_log
   end
   
   desc 'Tests homepage clicking'
   task :homepage => :init do
     
     setup 'homepage'
     
     #@sesh.num_uses.times do |x|
       test_click_home_logo
       #test_pick_use x
     #end
     
     close_log
   end
  
   desc "Test the sliders."
   task :sliders => :init do
     setup "sliders" 

     100.times do

       pick_slider = rand @sesh.num_sliders

       distance =@sesh.slider_min(pick_slider).to_i + rand(@sesh.slider_range(pick_slider)).to_i
       # TODO This tests integer inputs ONLY!
       # TODO Testing non-integers might require changes in my assert code!
       log "Testing the " + @sesh.slider_name(pick_slider) + " slider. Moving it to " +  distance.to_s

       new_min = @sesh.current_slider_min(pick_slider).to_i
       new_max = @sesh.current_slider_max(pick_slider).to_i
       (rand >= 0.5)? new_min = distance.to_i : new_max = distance.to_i

       test_move_sliders(pick_slider, new_min, new_max)

     end

     close_log
   end

   desc "Test the brand selector."
   task :brand_selector => :init do 
     setup "brand_selector" 

     # Try selecting every brand
     (1..@sesh.num_brands_in_dropdown).each do |brand| 
       test_add_brand (brand - 1)      
       test_click_home_logo
       #test_pick_use 0
     end

     close_log
   end

   desc "Test the search box."
   task :search => :init do 
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
   task :browse_similar => :init do
     setup "browse_similar" 

     hist = ["root"]
     explore(hist)

     close_log
   end

   desc "Simulate a user session and test everything (ajax too)."
   task :random => :java_init do
       setup_java "random" 

       search_strings = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]

       (@sesh.num_brands_in_dropdown-1).times do |x| 
         bname = @sesh.brand_name (x+1)
         search_strings << bname
         search_strings << bname.downcase
       end

       200.times do

         pick_action = (rand 12).floor
         # For the error page, the # of possible actions is very limited.
         pick_action = 10 + rand(2) if @sesh.error_page?
         #pick_action = 12 if @sesh.home_page?
         pick_action = 13 if @sesh.get_bd_div_text == ''

         if pick_action == 0                     #0 Test move sliders.
           slide_me = rand @sesh.num_sliders

           offset = rand(@sesh.slider_range(slide_me))
           distance = @sesh.slider_min(slide_me).floor + offset

           new_min = @sesh.current_slider_min(slide_me).to_i
           new_max = @sesh.current_slider_max(slide_me).to_i
           (rand >= 0.5)? new_min = distance.to_i : new_max = distance.to_i

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
         elsif pick_action == 7                 #7 Test remove brand
           if( @sesh.num_brands_selected > 0 )
             deselect_me = (rand(@sesh.num_brands_selected) + 1).floor
             test_remove_brand deselect_me
           end
         elsif pick_action == 8                 #8 Test checkboxes
           clickme = rand(@sesh.num_checkboxes)
           test_checkbox clickme
         elsif pick_action == 9                 # Test details 
           #detailme = rand(@sesh.num_boxes)
           #test_detail_page detailme
         elsif pick_action == 10                  #10 Test home logo
           test_click_home_logo
         elsif pick_action == 11
           test_goto_homepage        
        # elsif pick_action == 11                  #11 Test back button
           # No back button test is implemented
         #elsif pick_action == 12                  #12 Test clicking a use button
        #   pickme = rand(@sesh.num_uses)
        #   test_pick_use pickme
         elsif pick_action == 13
           break 
         end

       end

       close_log
   end

   desc "Simulate a user session and test almost everything."
   task :random_nojava => :init do
       setup "random" 

       search_strings = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]

       (@sesh.num_brands_in_dropdown-1).times do |x| 
         bname = @sesh.brand_name (x+1)
         search_strings << bname
         search_strings << bname.downcase
       end

       200.times do

         pick_action = rand 8
         # For the error page, the # of possible actions is very limited.
         pick_action = 6 + rand(2) if @sesh.error_page?
         #pick_action = 8 if @sesh.home_page?

         if pick_action == 0                     #0 Test move sliders.
           slide_me = rand @sesh.num_sliders

           offset = rand(@sesh.slider_range(slide_me))
           distance = (@sesh.slider_min(slide_me) + offset).to_i

           new_min = (@sesh.current_slider_min(slide_me)).to_i
           new_max = (@sesh.current_slider_max(slide_me)).to_i
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
         elsif pick_action == 5                 #5 Test details 
            detailme = rand(@sesh.num_boxes)
            test_detail_page detailme
         elsif pick_action == 6                  #6 Test home logo
             test_click_home_logo
         elsif pick_action == 7
           test_goto_homepage
         #elsif pick_action == 7                  #7 Test back button
            #Back button test not implemented
         #elsif pick_action == 8                  #8 Test clicking a use button
         #  test_pick_use 0
         end

       end

       close_log
   end

   desc 'Init for normal settings (faster)'
   task :init => :environment do
       # Check for all the right configs
       #raise "Rails test environment not being used." if ENV["RAILS_ENV"] != 'test' 
       #raise  "Forgery protection turned on in test environment."  if (ActionController::Base.allow_forgery_protection) 

     # Requires.
        require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
        require 'testing_lib'
        include NoJavaTestLib
        
        Webrat.configure do |conf| 
         conf.mode = :mechanize  # Can't be rails or Webrat won't work 
        end

        WWW::Mechanize.html_parser = Nokogiri::HTML
        
       # Want something like this: WWW::Mechanize.open_timeout = 0.1
       # or thiss  WWW::Mechanize.read_timeout = 0.1        
   end
   
   desc 'Init for ajax testing and/or selenium'
   task :java_init => :environment do
     
      # Check for all the right configs
      #raise "Rails test environment not being used." if ENV["RAILS_ENV"] != 'test' 
      #raise  "Forgery protection turned on in test environment."  if (ActionController::Base.allow_forgery_protection) 

        require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
        require 'testing_lib'
        include JavaTestLib
        
        Webrat.configure do |config|
          config.mode = :selenium
          config.application_environment = :test  
          config.application_framework = :rails
        end

      
   end

end