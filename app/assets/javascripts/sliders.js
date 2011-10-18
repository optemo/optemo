/* Optemo Sliders */

var optemo_module;
optemo_module = (function (my){
  //****Public Functions****
  my.SliderInit = function() {
      // Initialize Sliders
      $('.slider').each(function() {
          // threshold identifies that 2 sliders are too close to each other
          var curmax, curmin, rangemax, rangemin, threshold = 20, force_int = $(this).attr('force-int');
          if(force_int == 'false')
          {
              curmin = parseFloat($(this).attr('data-startmin'));
              curmax = parseFloat($(this).attr('data-startmax'));
              rangemin = parseFloat($(this).attr('data-min'));
              rangemax = parseFloat($(this).attr('data-max'));
          }
          else
          {
              curmin = parseInt($(this).attr('data-startmin'));
              curmax = parseInt($(this).attr('data-startmax'));
              rangemin = parseInt($(this).attr('data-min'));
              rangemax = parseInt($(this).attr('data-max'));
          }
      
          $(this).slider({
              orientation: 'horizontal',
              range: false,
              min: 0,
              max: 100,
              values: [((curmin-rangemin)/(rangemax-rangemin))*100,((curmax-rangemin)/(rangemax-rangemin))*100],
              start: function(event, ui) {
                  // At the start of sliding, if the two sliders are very close by, then push the value on other slider to the bottom
                  force_int = $(this).attr('force-int');
                  if(force_int == 'false')
                  {
                      curmin = $(this).attr('data-startmin');
                      curmax = $(this).attr('data-startmax');
                  }
                  else
                  {
                      curmin = parseInt($(this).attr('data-startmin'));
                      curmax = parseInt($(this).attr('data-startmax'));
                  }
                  var diff = ui.values[1] - ui.values[0];
                  if (diff < threshold)
                  {
                      if(ui.value == ui.values[0])    // Left slider
                      {
                          $('a:last', this).html(curmax).removeClass("valabove").addClass("valbelow");
                          $('a:first', this).html(curmin).addClass("valabove");
                      }
                      else
                      {
                          $('a:first', this).html(curmin).removeClass("valabove").addClass("valbelow");
                          $('a:last', this).html(curmax).addClass("valabove");
                      }
                  }
              },
              slide: function(event, ui) {
                  force_int = $(this).attr('force-int');
                  if(force_int == 'false')
                  {
                      curmin = parseFloat($(this).attr('data-startmin'));
                      curmax = parseFloat($(this).attr('data-startmax'));
                      rangemin = parseFloat($(this).attr('data-min'));
                      rangemax = parseFloat($(this).attr('data-max'));
                      datasetmin = parseFloat($(this).attr('current-data-min'));
                      datasetmax = parseFloat($(this).attr('current-data-max'));
                  }
                  else
                  {
                      curmin = parseInt($(this).attr('data-startmin'));
                      curmax = parseInt($(this).attr('data-startmax'));
                      rangemin = parseInt($(this).attr('data-min'));
                      rangemax = parseInt($(this).attr('data-max'));
                      datasetmin = parseInt($(this).attr('current-data-min'));
                      datasetmax = parseInt($(this).attr('current-data-max'));
                  }
                  var min = 0;
                  var max = 100;
                  // These acceptable increments can be tweaked as necessary. Multiples of 5 and 10 look cleanest; 20 looks OK but 2 and 0.2 look weird.
                  var acceptableincrements = [1000, 500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01];
                  var increment = (rangemax - rangemin) / 100.0;
                  for (var i = 0; i < acceptableincrements.length; i++) // Just so that it doesn't go off the scale for weird error case (increment == 0)
                  {
                      if ((increment * 1.01) < acceptableincrements[i])  // The fudge factor here is required.
                          continue;
                      else // so, for example, increment is 51 and increment is 100
                          increment = acceptableincrements[i];
                      // could do this with a state machine a bit cleaner but this works fine. After the first time that the increment is in range, stop the loop immediately
                      break;
                  }

                  var realselectmin, realselectmax;
                  var value = ui.value;
                  var sliderno = -1;
                  leftsliderknob = $('a:first', this);
                  rightsliderknob = $('a:last', this);
                  if(ui.value == ui.values[0])
                      sliderno = 0;
                  else
                      sliderno = 1;
                  $(this).slider('values', sliderno, value);
                  realvalue = (parseFloat((ui.values[sliderno]/100))*(rangemax-rangemin))+rangemin;
                  // Prevent the left slider knob from going too far to the right (past all the current data)
                  if ((realvalue > datasetmax && sliderno == 0) || ui.values[0] == 100) {
                      realvalue = datasetmax;
                      leftsliderknob.css('left', ((datasetmax - rangemin) * 99.9 / (rangemax - rangemin)) + "%");
                  }
                  // Prevent the right slider knob from going too far to the left (past all the current data)
                  if ((realvalue < datasetmin && sliderno == 1) || ui.values[1] == 0) {
                      realvalue = datasetmin;
                      rightsliderknob.css('left', ((datasetmin - rangemin) * 100.1 / (rangemax - rangemin)) + "%"); // was 100.1
                  }
                  if (increment < 1) {
                      // floating point division has problems; avoid it
                      tempinc = parseInt(1.0 / increment);
                      realvalue = parseInt(realvalue * tempinc) / tempinc;
                  } else {
                      realvalue = parseInt(realvalue / increment) * increment;
                  }
                  
                  // This makes sure that when sliding to the extremes, you get back to the real starting points
                  if (sliderno == 1 && ui.values[1] == 100)
                      realvalue = rangemax;
                  else if (sliderno == 0 && ui.values[0] == 0)
                      realvalue = rangemin;
                  
                  if (sliderno == 0 && ui.values[0] != ui.values[1])                        // First slider is not identified correctly by sliderno for the case
                      leftsliderknob.html(realvalue).addClass("valabove");            // when rightslider = left slider, hence the second condition
                  else if (ui.values[0] != ui.values[1])
                      rightsliderknob.html(realvalue).addClass("valabove");
                  var range_result = "";
                  if(sliderno == 0)
                  {
                    range_result = realvalue + "-";
                    var previous_value = new RegExp(/[\d.]*-([\d.]*)/).exec($(this).siblings('.range').attr('value'));
                    if (previous_value != null)
                      range_result += previous_value[1];
                  }
                  else
                  {
                    var previous_value = new RegExp(/([\d.]*)-[\d.]*/).exec($(this).siblings('.range').attr('value'));
                    if (previous_value != null)
                      range_result = previous_value[1];
                    range_result += "-" + realvalue;
                  }
                  $(this).siblings('.range').attr('value',range_result);
                  return false;
              },
              stop: function(e,ui)
              {
                  force_int = $(this).attr('force-int');
                  leftsliderknob = $('a:first', this);
                  rightsliderknob = $('a:last', this);
                  if(force_int == 'false')
                  {
                      rangemin = parseFloat($(this).attr('data-min'));
                      rangemax = parseFloat($(this).attr('data-max'));
                      datasetmin = parseFloat($(this).attr('current-data-min'));
                      datasetmax = parseFloat($(this).attr('current-data-max'));
                  }
                  else
                  {
                      rangemin = parseInt($(this).attr('data-min'));
                      rangemax = parseInt($(this).attr('data-max'));
                      datasetmin = parseInt($(this).attr('current-data-min'));
                      datasetmax = parseInt($(this).attr('current-data-max'));
                  }
                  var rightslidervalue;

                  if ((ui.values[1] * (rangemax - rangemin) / 100.0) + rangemin < datasetmin) {
                      rightslidervalue = datasetmin;
                      var leftslidervalue = $(this).siblings('.range').attr('value').match(/[^-]+/).join();
                      $(this).siblings('.range').attr('value', leftslidervalue + "-" + rightslidervalue);
                  }
                  else
                      rightslidervalue = ui.values[1];
                  var diff = rightslidervalue - ui.values[0];
                  if (diff > threshold)
                  {
                      leftsliderknob.removeClass("valabove").addClass("valbelow");
                      rightsliderknob.removeClass("valabove").addClass("valbelow");
                  }
                  my.submitAJAX();
              }
          });
          if ($(this).slider("option", "disabled") == true) {
              $(this).slider("option", "disabled", false);
          }
          $(this).slider('values', 0, ((curmin-rangemin)/(rangemax-rangemin))*100);
          $('a:first', this).html(curmin).addClass("valbelow");
          $(this).slider('values', 1, ((curmax-rangemin)/(rangemax-rangemin))*100);
          var diff = $(this).slider('values', 1) - $(this).slider('values', 0);
          $('a:last', this).html(curmax).addClass("valbelow");
          if (diff < threshold)
              $('a:last', this).html(curmax).addClass("valabove");
          if (!($(this).siblings('.hist').children('svg').length))
          {
              histogram($(this).siblings('.hist')[0]);
          }
          $(this).removeClass('ui-widget').removeClass('ui-widget-content').removeClass('ui-corner-all');
          $(this).find('a').each(function(){
              $(this).removeClass('ui-state-default').removeClass('ui-corner-all');
              $(this).unbind('mouseenter mouseleave');
          });
      // Try to text align center of max handle
      max_handle_text = $(this).children().last().html();
      max_handle_text_len = max_handle_text.length;
      margin_hash = {3:-5, 4:-9, 5:-13, 6:-17, 7:-21, 8:-25, 9: -29};
      
      if (max_handle_text_len >= 3)
      $(this).children().last().html("<span style='margin-left:" + margin_hash[max_handle_text_len] + "px;position:absolute;'>" + max_handle_text + "</span>");
      });
  };
  //****Private Functions****
  // Draw slider histogram, called for each slider above
  function histogram(element, norange) {
      var raw = $(element).attr('data-data');
      if (raw)
          var data = raw.split(',');
      else
          var data = [0.5,0.7,0.1,0,0.3,0.8,0.6,0.4,0.3,0.3];
      //Data is assumed to be 10 normalized elements in an array
      var peak = 0, trans = 3, length = 170, height = 20, init = 4;
      var step = peak + 2*trans, shapelayer = Raphael(element,length,height), h = height - 1,
      t = shapelayer.path({fill: "#bad0f2", stroke: "#039", opacity: 0.75});
      t.moveTo(0,height);
      for (var i = 0; i < data.length; i++) {
          t.cplineTo(init+i*step+trans,h*(1-data[i])+1,5);
          t.lineTo(init+i*step+trans+peak,h*(1-data[i])+1);
          //shapelayer.text(i*step+trans+5, height*0.5, i);
      }
      t.cplineTo(init+(data.length)*step+4,height,5);
      t.andClose();
  }

  return my;
})(optemo_module || {});