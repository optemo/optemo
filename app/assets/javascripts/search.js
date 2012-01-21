var optemo_module;
optemo_module = (function (my){
  //****Public Functions****
  //****Private Functions***
	function get_filtering_specs(){
		 // check if there is any filtering before starting the keyword search (maybe it's needed to combine with my.submitAJAX)
		 var selections = $("#filter_form").serializeObject();
			$.each(selections, function(k,v){
	       if(v == "" || v == "-") {
	           delete selections[k];
	       }
	       /* Look for weird $ error */
	   });
		return selections
	}
  /* LiveInit functions */
  $('#keyword_submit').live("click", function(){
    if (my.loading_indicator_state.disable) return false;
 	 var selections = get_filtering_specs();
	
		if ($("#product_name").val()!="" && $("#product_name").val()!= "Keyword or Web Code")
		 {my.ajaxcall("/search", $.extend(selections,{"keyword" : $("#product_name").val()}));}
		else
		 my.ajaxcall("/search", selections);
    return false;
  })
  
  $('.suggestion').live('click', function() {
      if (my.loading_indicator_state.disable) return false;
			 var selections = get_filtering_specs();
		 	my.ajaxcall("/search", $.extend(selections,{"keyword" : $.trim($(this).html())}));
    return false;
  });

 
  /* End of LiveInit Functions */
  return my;
})(optemo_module || {});