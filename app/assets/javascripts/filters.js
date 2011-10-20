/* Filters */

var optemo_module;
optemo_module = (function (my){
  //****Public Functions****
  
  //****Private Functions****
  
  /* LiveInit functions */
  
  $('.binary_filter').live('click', my.submitAJAX);
  $('.cat_filter').live('click', my.submitAJAX);
  $('.checkbox_text').live('click', function(){
      if (my.loading_indicator_state.disable) return false;
      var checkbox = $(this).siblings('input');
      if (checkbox.attr('checked'))
          checkbox.removeAttr("checked");
      else
          checkbox.attr("checked", "checked");
      my.submitAJAX();
      return false;
  });
  
  // Add a color selection -- submit
  $('.swatch_button').live('click', function(){
      if (my.loading_indicator_state.disable) return false;
      var t = $(this);
      if (t.hasClass("selected_swatch"))
      { //Removed selected color
        $('#categorical_color').val("");
      }
      else
      { //Added selected color
        var whichThingSelected = t.attr("style").replace(/background-color: (\w+);?/i,'$1');
        // Fix up the case issues for Internet Explorer (always pass in color value as "Red")
        whichThingSelected = whichThingSelected.toLowerCase();
        whichThingSelected = whichThingSelected.charAt(0).toUpperCase() + whichThingSelected.slice(1);
        $('#categorical_color').val(whichThingSelected);
      }
      t.toggleClass('selected_swatch');
      my.submitAJAX();
  });
  
  //Reset filters
  $('.reset').live('click', function(){
      if (my.loading_indicator_state.disable) return false;
      my.ajaxcall('/',{landing:'true'});
      return false;
  });
  
  /* End of LiveInit Functions */
  return my;
})(optemo_module || {});