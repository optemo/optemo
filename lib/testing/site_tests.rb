module SiteTest

  def test_detail_page box_index
    log "Getting Detail page for #{box_index+1}th box, product id #{@sesh.pid_by_box(box_index+1)}"
    begin
      @sesh.get_detail_page (box_index+1)
    rescue Exception => e
      report_error "Problem getting detail page for product #{@sesh.pid_by_box(box_index+1)}"
      report_error "#{e.class.name} #{e.message}"
    else
      assert_not_error_page
      assert_not_homepage
      assert_detail_price_not_nil
      assert_detail_pic_not_nil
    end
    @sesh.click_back_button
    @sesh.wait_for_load if java_enabled?
    assert_not_error_page
    assert_well_formed_page
  end

  def test_move_sliders(slider, min, max)
    log "Testing the " + @sesh.slider_name(slider) + " slider. Moving it to (#{min},#{max})"
    snapshot
  
    begin
      # TODO change methods to move_slider
      @sesh.move_slider(slider, min.to_i, max.to_i)
    rescue Exception => e
      report_error e.class.name.to_s + e.message.to_s
    else
      assert_not_error_page
      assert_well_formed_page
      assert_brands_same
      assert_clear_search_links_same
  
      if !@sesh.no_products_found_msg? 
        assert_slider_range(slider, min.to_i, max.to_i)
      end
  
      if min > max
        assert_no_results_msg_displayed
      end
    end
    log "Done testing move sliders"
  end
  
  # Recursive method to test all browse_similar.
  def explore(hist)
    (1..@sesh.num_similar_links).each do |num|
      log "Testing #{num}th browse similar link with history: " + hist * ", "
      test_browse_similar(num)
      hist << num.to_s
      explore(hist)
      hist.pop
      @sesh.click_back_button
    end
  end
  
  def test_back_button
     #@num_products_before = @sesh.num_products
     #@num_brands_selected_before = @sesh.num_brands_selected
     #@num_boxes_before = @sesh.num_boxes
     #@num_saved_items_before = @sesh.num_saved_items
     #@num_similar_links_before = @sesh.num_similar_links
     #@num_clear_search_links_before = @sesh.num_clear_search_links
     #@session_id_before = @sesh.session_id 
     #@no_products_found_msg_before = @sesh.no_products_found_msg?
     #@error_page_before = @sesh.error_page?
     #@url_before = @sesh.current_url
     #@history.push @sesh.current_url 
  end
  
  def test_goto_homepage
    log "Testing Goto Homepage"
    snapshot
    @sesh.get_homepage  
    assert_is_homepage
    log "Done testing goto homepage"
  end
  
  def test_checkbox klikme
    log "Testing clicking #{klikme+1}th checkbox"
    snapshot
    was_selected = @sesh.checkbox_selected?(klikme)
    @sesh.click_checkbox klikme 
    
    if !was_selected and !@sesh.no_products_found_msg?
      assert_box_checked klikme
    elsif !was_selected
      assert_num_products_same
      assert_box_unchecked klikme
    else
      assert_box_unchecked klikme
    end
    
    assert_not_error_page
    assert_well_formed_page
    
    log "Done clicking checkbox"
  end
  
  def test_click_home_logo
  
    log "Testing Click Homepage logo"
    snapshot
    @sesh.click_home_logo
    
    assert_is_homepage
    log "Done testing click homepage logo"
  end
  
  def test_browse_similar which_link
    log "Clicking on the #{which_link}th browse similar link"
    snapshot
  
    begin        
      @sesh.click_browse_similar which_link
    rescue Exception => e
      report_error "Error with box number #{which_link} \n" + e.class.name.to_s + e.message.to_s
    else
      assert_not_error_page
      assert_well_formed_page
      assert_num_products_decreased
    end
    log "Done testing browse similar"
  end
  
  def test_search_for query
    log "Searching for " + query
    snapshot
  
    begin
      @sesh.search_for query
    rescue Exception => e
      report_error "Error with search string '" + query + "'" + "\n" + e.class.name.to_s + e.message.to_s
    else
      assert_not_error_page
      assert_well_formed_page
  
      if @sesh.no_products_found_msg?
        assert_clear_search_links_same
        log "No products found for " + query
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
      report_error "Clear search history error, " + e.class.name.to_s + e.message.to_s
    else
    # TODO more asserts?
     assert_not_error_page
     assert_well_formed_page
     assert_search_history_clear
     assert_brands_same
     assert_session_id_same
   end
   log "Done testing clear search history."
  end
  
  def test_add_brand brand
    log "Adding brand " + @sesh.brand_name(brand)
    # Preconditions & stuff.
    snapshot
    bname = @sesh.brand_name(brand)
    @brand_selected_before = @sesh.brand_selected?(bname)
    begin 
      @sesh.select_brand(brand)          
    rescue Exception => e # This detects crashing.
      report_error e.class.name.to_s + " with " + bname + ", message:" + e.message.to_s
    else
      assert_not_error_page
      assert_well_formed_page
  
      if @sesh.is_all_brands?(bname)
        assert_brands_same
        assert_num_products_same
      elsif brand == 0
        puts "But it should be going to the loop above"
      elsif @brand_selected_before
        log "This brand was selected before."
        assert_num_products_same
        assert_brand_selected(bname)
      elsif @sesh.no_products_found_msg?
        log "There were no products found for this brand."
        assert_brand_deselected(bname)
        assert_num_products_same
        assert_brands_same
      else
        debugger unless @sesh.brand_selected?(bname)
        assert_brand_selected(bname)
        # TODO other asserts!
      end
    end
    log "Done testing add brand " + bname
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
      report_error "Crashed while saving item. Error: " + e.class.name.to_s + e.message.to_s
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
      report_error "Crashed while removing saved item. Error: " + e.class.name.to_s + e.message.to_s
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
    
    removed_name = @sesh.selected_brand_name(which_brand)
    @sesh.remove_brand(which_brand)
    log "Removing " + removed_name + ", #{which_brand}th brand in the list."
    
    assert_not_error_page
    assert_well_formed_page
    assert_brand_deselected(removed_name)
    
    log "Done removing brand"
  end
  
  def test_status_quo
     log "Testing status quo (not doing anything)"
  
     snapshot
  
     assert_brands_same
     assert_saveds_same
     assert_num_products_same
     assert_clear_search_links_same
     assert_session_id_same
     
     log "Done testing status quo"
  end
  
# ---------------- HELPER METHODS ----------------- #

  def java_enabled?
    return true if(@sesh.class.name.to_s == "JavaTestSession")
    return false
  end
  
   # Take a 'snapshot' of the current page for comparison for later.
  def snapshot
     @num_products_before = @sesh.num_products
     @num_brands_selected_before = @sesh.num_brands_selected
     @num_boxes_before = @sesh.num_boxes
     @num_saved_items_before = @sesh.num_saved_items
     @num_similar_links_before = @sesh.num_similar_links
     @num_clear_search_links_before = @sesh.num_clear_search_links
     @session_id_before = @sesh.session_id 
     @no_products_found_msg_before = @sesh.no_products_found_msg?
     @error_page_before = @sesh.error_page?
     @url_before = @sesh.current_url
     @history.push @sesh.current_url
  end
   
  def close_log
      puts "Test completed. Log file at " + @logfile.path
      @logfile.close
  end
  
  def setup_log(name)
    @logfile = File.open("./log/site_tests/"+name+".log", 'w+') #+Time.now.to_s.gsub(/ /, '_')
  end
  
  def setup logname
    setup_log logname 
    @sesh = TestSession.new @logfile
    @history = []
    
    snapshot
  end
  
  def setup_java logname
    setup_log "java_"+logname 
    @sesh = JavaTestSession.new @logfile
    @history = []
    snapshot
    # TODO take this out?
    if @sesh.popup_tour?
      @sesh.close_popup_tour
    end
  end
 
end