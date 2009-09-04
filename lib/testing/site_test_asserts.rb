module PrinterTestAsserts
  def assert_already_saved_msg_displayed
    report_error "Already saved msg hidden" unless @sesh.already_saved_msg?
  end
  
  def assert_boxes_clear 
    @sesh.num_checkboxes.times do |i|
      assert_box_unchecked i
    end
  end
  
  def assert_box_checked boxnum
    report_error "Checkbox not selected" unless @sesh.checkbox_selected? boxnum
  end
  
  def assert_box_unchecked boxnum
    report_error "Checkbox selected" if @sesh.checkbox_selected? boxnum
  end
  
  def assert_detail_pic_not_nil
    unless @sesh.detail_page?
      report_error "Not the detail page" 
      return
    end
    price_el = @sesh.doc.css('div.showtable .left')
    report_error "Nil price in detail page" unless (price_el and price_el.first.content.match(/\$/) )
  end
  
  def assert_detail_price_not_nil
    unless @sesh.detail_page?
      report_error "Not the detail page" 
      return
    end
    pic_el = @sesh.doc.css('#image img')
    report_error "Nil image in detail page" unless (pic_el and pic_el.first)
  end
  
  def assert_is_homepage
    report_error "Is not the homepage" unless @sesh.home_page?
  end
  
  def assert_not_homepage
    report_error "Is the homepage" if @sesh.home_page?
  end
  
  def assert_already_saved_msg_hidden
    report_error "Already saved msg showing" if @sesh.already_saved_msg?
  end
  
  def assert_no_results_msg_displayed
    report_error "No results msg hidden" if !@sesh.no_products_found_msg?
  end
  
  def assert_no_results_msg_hidden
    report_error "No results msg displayed" if @sesh.no_products_found_msg?
  end
  
  def assert_not_error_page
    report_error "Error page displayed" if @sesh.error_page?
  end
  
  def assert_well_formed_page
  
    # More than 0 boxes
    report_error "No borderboxes" if @sesh.num_boxes == 0
  
    if @sesh.num_products <= 9  
  
      if @sesh.num_similar_links > 0
        report_error "Browse similar links available when browsing less than 9 products"
      end
  
      if @sesh.num_boxes !=@sesh.num_products
         report_error @sesh.num_boxes.to_s + " boxes but " + @sesh.num_similar_links.to_s +  " 'explore similar' links."
      end
  
    end
  
    if @sesh.num_products > 9 and @sesh.num_similar_links == 0
      report_error "Browse similar links not available when browsing more than 9 products"
    end
  
    if @sesh.num_boxes < 9 and @sesh.num_products >= 9
      report_error "Less than 9 borderboxes for 9 or more products"
    end
  
    # Save here message : displayed only if no saved items.
    # Compare button: only if 1/more saved items.
    if(@sesh.num_saved_items == 0)
      report_error "Save here message hidden" unless @sesh.save_here_msg?
      report_error "Compare button displayed" if @sesh.compare_button?
    else
      report_error "Save here message displayed" if @sesh.save_here_msg?
      report_error "Compare button hidden" unless @sesh.compare_button?
    end
  
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
  
  def assert_item_saved pid
    report_error "Product with id #{pid} has'nt been saved." unless @sesh.was_saved? pid
  end
  
  def assert_item_not_saved pid
    report_error "Product with id #{pid} is in saved list." if @sesh.was_saved? pid
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
    report_error "Saved products not cleared" if @sesh.num_saved_items != 0 
  end
  
  def assert_browsing_all_products i=0
    if @sesh.total_products[i] != @sesh.num_products
      report_error "Not all products displayed: should be #{@sesh.total_products[i]}, is #{@sesh.num_products}" 
    end
  end
  
  def assert_num_products_decreased
    if @sesh.num_products >= @num_products_before
      report_error "Number of products browsed not decreased: was #{@num_products_before}, now " + @sesh.num_products.to_s 
    end
  end
  
  def assert_num_products_same
    if @sesh.num_products != @num_products_before
      report_error "Number of products browsed changed. Was #{@num_products_before}, now " + @sesh.num_products.to_s
    end
  end
  
  def assert_num_products_increased
    if @sesh.num_products <= @num_products_before
      report_error "Number of products browsed not increased: was #{@num_products_before}, now " + @sesh.num_products.to_s 
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
end
    