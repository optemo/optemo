# Rake tasks to test the web app
namespace :test_site do   

   desc 'Quick test'
   task :quick => [:hurryinit, :sliders, :search, :brand_selector, :homepage]
   
   desc 'Run all tests'
   task :all => [:sliders, :browse_similar, :search, :brand_selector, :random]
   
   task :sandbox => :java_init do
    setup_java 'sandbox_1'
    test_add_brand(10) # add canon
    if(@sesh.no_products_found_msg? or @sesh.error_page? or @sesh.detail_page?)
        test_close_msg_box
     elsif(@sesh.doc.nil?)
        break
      end
    test_browse_similar(1) # 1st browse link
    if(@sesh.no_products_found_msg? or @sesh.error_page? or @sesh.detail_page?)
        test_close_msg_box
     elsif(@sesh.doc.nil?)
        break
      end
    test_checkbox(0) # 1st checkbox
    if(@sesh.no_products_found_msg? or @sesh.error_page? or @sesh.detail_page?)
        test_close_msg_box
     elsif(@sesh.doc.nil?)
        break
      end
    test_add_brand(11) # add genicom
    if(@sesh.no_products_found_msg? or @sesh.error_page? or @sesh.detail_page?)
        test_close_msg_box
     elsif(@sesh.doc.nil?)
        break
      end
    close_log
   end
   
   desc 'Check and uncheck every chekbox'
   task :checkboxes => :java_init do
      setup_java 'checkboxes'
      if @sesh.popup_tour?
        @sesh.close_popup_tour
      end
      @sesh.num_checkboxes.times do |i|
        2.times do
          test_checkbox i
        end
      end
      close_log
   end
   
   desc 'detail page'
   task :detail_page => :java_init do 
     setup_java 'detail_page'
      
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
   task :homepage => :java_init do
     
     setup_java 'homepage'
     
     #@sesh.num_uses.times do |x|
       test_click_home_logo
       #test_pick_use x
     #end
     
     close_log
   end
  
   desc "Test the sliders."
   task :sliders => :java_init do
     setup_java "sliders" 

     ( $num_tests || 100).times do
       
       slideme = rand @sesh.num_sliders
       new_position = @sesh.slider_percent_to_pos slideme, rand(101)

       log "Testing the " + @sesh.slider_name(slideme) + " slider. Moving it to " +  new_position.to_s

       new_min = new_max = new_position
       (rand >= 0.5)? new_min = @sesh.current_slider_min(slideme) : new_max = @sesh.current_slider_max(slideme)

       test_move_sliders(slideme, new_min, new_max)
       
       if(@sesh.no_products_found_msg? or @sesh.error_page?)
          test_close_msg_box
       end
     end

     close_log
   end

   desc "Test the brand selector."
   task :brand_selector => :java_init do 
     setup_java "brand_selector" 
     
     # Try selecting & deselecting every brand
     (1..@sesh.num_brands_in_dropdown).each do |brand| 
       test_add_brand (brand - 1)
       if(@sesh.num_brands_selected > 0)      
         test_remove_brand(1)
       end
     end

     close_log
   end

   desc "Test the search box."
   task :search => :java_init do 
       setup_java "search"

       testme = []
       (1..@sesh.num_brands_in_dropdown).each do |brand|
         testme << @sesh.brand_name(brand)
         testme << @sesh.brand_name(brand).downcase
       end

        # Other search strings
        other = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]
        
       testme += other
     testme.each do |x|
       test_search_for x
       if(@sesh.no_products_found_msg?)
        test_close_msg_box
         # TODO test_close_popup
       end
     end

     close_log
   end



##//////////////////////

desc "write into the search box."
task :form => :java_init do 
    setup_java "pref"

    # Brand name based search strings
    #(1..@sesh.num_brands_in_dropdown).each do |brand| 
      test_search_for '2'#@sesh.brand_name(brand)
    #  test_search_for @sesh.brand_name(brand).downcase         
    #end

  # Other search strings
  #other = ["","asdf","apples","Sister","Helwett","Hewlett","xena", "Data","cheap"]
  #other.each do |x|
  #  test_search_for x
  #end

  close_log
end


##/////////////////////

   desc "Exhaustive testing for Browse Similar."
   task :browse_similar => :java_init do
     setup_java "browse_similar" 

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
       

       ( $num_random_tests || 100).times do

         pick_action = (rand 10).floor
         
         if(@sesh.no_products_found_msg? or @sesh.error_page? or @sesh.detail_page?)
            test_close_msg_box
         elsif(@sesh.doc.nil?)
            break
         else
           case pick_action
           when 0                     #0 Test move sliders.
             slide_me = rand @sesh.num_sliders
             distance = @sesh.slider_percent_to_pos slide_me, rand(101)
           
             new_min = (@sesh.current_slider_min(slide_me)).to_i
             new_max = (@sesh.current_slider_max(slide_me)).to_i
             (rand >= 0.5)? new_min = distance : new_max = distance
           
             test_move_sliders(slide_me, new_min, new_max)
           when 1                  #1 Test add brand
             brand_to_add = rand(@sesh.num_brands_in_dropdown)
             test_add_brand brand_to_add
           when 2                  #2 Test search
             search_me = search_strings[rand(search_strings.length)] 
             rand(2).times do 
               (rand >= 0.5)? connector = " and " : connector = ' or '
               search_me += connector + search_strings[rand(search_strings.length)] 
             end
             test_search_for search_me
           when 3                 #3 Test browse similar
             if @sesh.num_similar_links > 0
               click_me = (rand( @sesh.num_similar_links) + 1).floor
               test_browse_similar click_me
             end
           when 4                 #7 Test remove brand
             if( @sesh.num_brands_selected > 0 )
               deselect_me = (rand(@sesh.num_brands_selected) + 1).floor
               test_remove_brand deselect_me
             end
           when 5                 #8 Test checkboxes
             clickme = rand(@sesh.num_checkboxes)
             test_checkbox clickme
           when 6                 # Test details 
             detailme = rand(@sesh.num_boxes)
             test_detail_page detailme
           when 7                  #10 Test home logo
             test_click_home_logo
           when 8                #Test goto homepage
             test_goto_homepage        
           when 9                  #11 Test back button
             test_back_button
           end
        end

       end

       close_log
   end

   task :hurryinit do
    $num_tests = 10
    $num_random_tests = 50
   end

   task :init =>  [:environment, :port_init] do
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
   
   task :java_init => [:environment, :port_init] do
       
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
   
   task :port_init do
      $port="3001" # Your Favourite Port! (or Sherry.)
   end

end