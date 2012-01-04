var optemo_module;
optemo_module = (function (my){
  //****Public Functions****
  
  //****Private Functions****
  
  /* LiveInit functions */
  $('#keyword_submit').live("click", function(){
    if (my.loading_indicator_state.disable) return false;
    my.ajaxcall("/search", {"keyword" : $("#product_name").val()});
    return false;
  })
  
  $('.suggestion').live('click', function() {
      if (my.loading_indicator_state.disable) return false;
      my.ajaxcall("/search", {"keyword" : $(this).html()});
      return false;
  });
  /* End of LiveInit Functions */
  return my;
})(optemo_module || {});