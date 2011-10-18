/* Product Comparison */

var optemo_module;
optemo_module = (function (my){
  //Hardcode the cookie name
  my.cmpcookie = 'bestbuy_compare_skus';
  //****Public Functions****
  
  //Check the cookie for comparisons, and the check the appropriate boxes
  my.load_comparisons = function() {
    var skus = my.readAllCookieValues(my.cmpcookie);
    $.each(skus, function(index,sku) {
       $('.optemo_compare_checkbox[data-sku="'+sku+'"]').each(function() {
          $(this).attr('checked', 'checked');
          loadspecs(sku);
       });
    });
    changeNavigatorCompareBtn(skus.length);
  }
  
  
  //****Private Functions****
  //Uncheck box and remove from Compariosn
  function removeFromComparison(sku) {
      $(".optemo_compare_checkbox").each( function (index) {
          if ($(this).attr('data-sku') == sku) {
              $(this).attr('checked', '');
              return;
          }
      });
      remove_comparison_from_skus(sku);
  }
  //Remove from comparison cookie and update comparison count
  function remove_comparison_from_skus(prod_sku) {
    my.removeValueFromCookie(my.cmpcookie, prod_sku+","+$('#main').attr('data-product_type'), 1);
    //Update comparison number
    var skus = my.readAllCookieValues(my.cmpcookie);
    changeNavigatorCompareBtn(skus.length);   
  }
  
  //Check or uncheck a comparison box
  function comparison_checkbox_change(){
      var sku_size = my.readAllCookieValues(my.cmpcookie).length;
      //Differentiate between the checkbox and text link, which passes in the checkbox
      var t = (arguments[0].jquery == undefined) ? $(this) : arguments[0];
      if (t.is(':checked')) { // save the comparison item
          if (sku_size < 5) {
            loadspecs(t.attr('data-sku'));
            my.addValueToCookie(my.cmpcookie, t.attr('data-sku')+','+$('#main').attr('data-product_type'), 1);
          }
          else {
              if (!(typeof(optemo_french) == "undefined") && optemo_french)
                  alert("Le nombre maximum de produits que vous pouvez comparer est de 5. Veuillez réessayer.");
              else
                  alert("The maximum number of products you can compare is 5. Please try again.");
              t.attr('checked', '');
          }
      } else {
        remove_comparison_from_skus(t.attr('data-sku'));
      }
      sku_size = my.readAllCookieValues(my.cmpcookie).length;
      changeNavigatorCompareBtn(sku_size);
  }
  
  //Update the UI depending on how many comparison items are selected
  function changeNavigatorCompareBtn(selected) {
      if (selected > 0) {
          $('.nav-compare-btn').each ( function(index) {
              $(this).removeClass('awesome_reset_grey');
              $(this).removeClass('global_btn_grey');
              $(this).addClass('awesome_reset');
              $(this).addClass('global_btn');
              $(this).text($(this).text().replace(/\d+/, selected));
          });
      } else {
          $('.nav-compare-btn').each ( function(index) {
              $(this).removeClass('awesome_reset');
              $(this).removeClass('global_btn');
              $(this).addClass('awesome_reset_grey');
              $(this).addClass('global_btn_grey');
              $(this).text($(this).text().replace(/\d+/, 0));
          });
      }
  };
  
  function show_comparison_window() {
      var skus = my.readAllCookieValues(my.cmpcookie), width;
      if (skus.length < 1)
        return false;

      // To figure out the width that we need, start with $('#opt_savedproducts').length probably
      // 560 minimum (width is the first of the two parameters)
      // 2, 3, 4 ==>  513, 704, 895  (191 each)
      if (skus.length > 2)
          width = 211 * (skus.length - 2) + 566;
      else {
          width = 566;
      }

      my.applySilkScreen('/comparison/' + skus.join(","), null, width, 580,function(){
          // Jquery 1.5 would finish all the requests before building the comparison matrix once
          // With 1.4.2 we can't do that. Keep code for later.
          // $.when.apply(this,reqs).done();
          buildComparisonMatrix();
      });
      return false;
  };
  
  function row_height(length,isLabel)
  {
      var h;
      if (isLabel) {
          if (length >= 55) h = 4;
          else if (length >= 37) h = 3;
          else if (length >= 19) h = 2;
          else h = 1;
      }
      else {
          if (length >= 85) h = 4;
          else if (length >= 57) h = 3;
          else if (length >= 29) h = 2;
          else h = 1;
      }
      return h;
  }
  
  function row_class(row_h) {
      //Assign row_class
      var row_class;
      if (row_h == 4) row_class = 'quadruple_height_compare_row';
      else if (row_h == 3) row_class = 'triple_height_compare_row';
      else if (row_h == 2) row_class = 'double_height_compare_row';
      else row_class = 'compare_row'; // row_class was 1
      return row_class;
  }
  
  //Collapse some of the cells for large tables
  function addtoggle(item){
      var closed = item.click(function() {
          $(this).toggleClass("closed").toggleClass("open").parent('.cell').parent().next('div.contentholder').toggle();
          return false;
      }).hasClass("closed");
      if (closed) {item.siblings('div').hide();}
  }
  
  //Data manipulation for the BB API Interface
  function merge_bb_json() {
      var merged = {};
      var index = 0;
      for (var p = 0; p < arguments.length; p++) {
          for (var heading in arguments[p]) {
              for (var spec in arguments[p][heading]) {
              if (typeof(merged[heading]) == "undefined")
                      merged[heading] = {};
                  if (typeof(merged[heading][spec]) == "undefined")
                      merged[heading][spec] = [];
                  merged[heading][spec][index] = arguments[p][heading][spec];
              
              }
          }
          index++;
      }
      return merged;
  }
  
  //Build spec matrix from API data
  function buildComparisonMatrix() {
      var skus = $('#basic_matrix').attr('data-skus').split(','), anchor = $('#hideable_matrix');
      // Build up the direct comparison table. Similar method to views/direct_comparison/index.html.erb
      var array = [];
      $.each(skus, function(index,value) {
        array.push($('body').data('bestbuy_specs_'+value));
      });
      var grouped_specs = merge_bb_json.apply(null,array);
      //Set up Headers
      
      for (var i = 0; i < skus.length; i++) {
          anchor.append('<div class="columntitle spec_column_'+i+' spec-capt">&nbsp;</div>');
      }
      var result = "";
      var whitebg = true;
      var divContentHolderTag = '<div class="contentholder">';
      var divContentHolderTagEnd = '</div>';
      
      for (var heading in grouped_specs) {
          if (heading != "") {
              //Add Heading
              result += '<div class="'+row_class(row_height(heading.length,true))+'"><div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + ' leftcolumntext" style="font-style: italic;"><a class="togglable closed title_link" style="font-style: italic;" href="#">' + heading.replace('&','&amp;') + '</a></div>';
              
              for (var i = 0; i < skus.length; i++) {
                  result += '<div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + ' spec_column_'+i+'">&nbsp;</div>';
              }
              
              result += "</div>";
              result += divContentHolderTag;
              whitebg = !whitebg;
          }
          for (var spec in grouped_specs[heading]) {
              //Row Height calculation
              array = [];
              for(var i = 0; i < grouped_specs[heading][spec].length; i++) {
                  if (grouped_specs[heading][spec][i])
                      array.push(grouped_specs[heading][spec][i].length);    
              }
              //Assign row_class
              result += '<div class="'+row_class(Math.max(row_height(Math.max.apply(null,array)),row_height(spec.length,true))) + '">';
              
              //Row heading
              result += '<div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + ' leftcolumntext">' + spec.replace('&','&amp;') + ":</div>";
              //Data
              for (var i = 0; i < skus.length; i++) {
                  var spec_value = grouped_specs[heading][spec][i];
                  if (spec_value) {
                      if (spec_value == "No" || spec_value == "Non") spec_value = "-";
                      result += '<div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + " " + "spec_column_"+ i + '">' + spec_value.replace(/&/g,'&amp;') + "</div>";
                  } else {
                      //Blank Cell
                      result += '<div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + " " + "spec_column_"+ i + '">-</div>';
                  }
              }
              result += "</div>";
              
              whitebg = !whitebg;
          }
          if (heading != "") {
              result += divContentHolderTagEnd;
          }
      }
      anchor.append(result);

      // Put the thumbnails and such at the bottom of the compare area too (in the hideable matrix)
      var remove_row = $('#basic_matrix .compare_row:first');
      anchor.append(
          remove_row.clone(),
          remove_row.next().clone(),
          remove_row.next().next().clone().find('.leftmostcolumntitle').empty().end()
      );
      $('.togglable').each(function(){addtoggle($(this));});
      if ($.browser.msie && $.browser.version.substr(0,1)<7) {// IE6 comparison page close button margin space issue

          if (skus.length <= 2){ 
              $('#optemo_embedder #IE .bb_quickview_close').css("margin-right",'-68px');
          }
      }

  };
  
  // The spec loader works to do a couple AJAX calls when the show page initially loads.
  // The results are stored in $('body').data for instant retrieval when the
  // specs, reviews, or product info buttons are clicked.
  
  // Consider refactoring this code to solve the race condition:
  //   - get the loading code to chain back to the insertion code
  //   - "specs" or "more specs" links just show/hide the table element rather than building it up; the ajax return below does that
  // The disadvantage would be that the specs wouldn't be stored for later retrieval. This probably isn't a big deal.

  // For the bundle products, get the first product from bundle spec and show its specs
  function loadspecs(sku, bundle_sku) {
      // The jQuery AJAX request will add ?callback=? as appropriate. Best Buy API v.2 supports this.
      var baseurl = "http://www.bestbuy.ca/api/v2/json/product/" + sku;
      if (!(typeof(optemo_french) == "undefined") && optemo_french) baseurl = baseurl+"?lang=fr";
      // Do the AJAX request only once
      if (!($('body').data('bestbuy_specs_' + sku))) {
          $.ajax({
              url: baseurl,
              type: "GET",
              dataType: "jsonp",
              success: function (data) {
                  // If it is a bundle, get the first sku
                  var bundle = data["bundle"];

                  if (bundle.length > 0) {
                      loadspecs(bundle[0]["sku"], sku);
                  }
                  else {
                      var raw_specs = data["specs"];
                      // rebuild prop_list so that we can get the specs back out.
                      // We might need to do this regardless, due to the fact that
                      // the property list doesn't have to be sent in order.
                      var processed_specs = function (my) {
                          for (var i = 0; i < raw_specs.length; i++) {
                              var spec = raw_specs[i];
                              if (typeof(my[spec.group]) == "undefined") my[spec.group] = {};
                              my[spec.group][spec.name] = spec.value;
                          }
                          return my;
                      }({});
                      var sku_to_register = sku;
                      if (bundle_sku)
                          sku_to_register = bundle_sku;
                      jQuery('body').data('bestbuy_specs_' + sku_to_register, processed_specs);
                  }
              }
          });
      }
  };
  
  /* LiveInit functions */
  //Remove buttons on compare
  $('.remove').live('click', function(){
      removeFromComparison($(this).attr('data-sku'));
      var class_name = $(this).attr('class').split(' ').slice(-1); // spec_column_0, for example

      $("." + class_name).each(function () {
          $(this).remove();
      });

      // If this is the last one, take the comparison screen down too
      var skus = my.readAllCookieValues(my.cmpcookie);
      if (skus.length == 0) {
          my.removeSilkScreen();
      }

      return false;
  });
  
  //Show/Hide API specs
  $('.toggle_specs').live('click', function () {
      // Once we have the additional specs loaded and rendered, we can simply show and hide that table
      var t = $(this);
      t.toggleClass("lessspecs");
      t.find(".lesstext").toggle();
      t.find(".moretext").toggle();
      $('#hideable_matrix').toggle();
      cHeight = my.current_height();
      $('#silkscreen').css({'height' : cHeight+'px', 'display' : 'inline'});
      return false;
  });
  
  //Add to comparison from navbox
  $('.optemo_compare_checkbox').live('click', comparison_checkbox_change);
  $('.optemo_compare_button').live('click', function(){
	  var my_checkbox = $(this).parent().find('.optemo_compare_checkbox');
	  if (!my_checkbox.attr('checked')) {
	    my_checkbox.attr('checked','checked');
      comparison_checkbox_change(my_checkbox);
    }
    if (my_checkbox.is(':checked'))
      show_comparison_window();
    return false;
  });
  
  //Comparison btn on navigation page
  $('#optemo_embedder .nav-compare-btn').live("click", show_comparison_window);
  
  /* End of LiveInit Functions */
  
  return my;
})(optemo_module || {});