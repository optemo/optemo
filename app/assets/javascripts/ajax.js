/* AJAX Functionality */

var optemo_module;
optemo_module = (function (my){
  //This variable is used to determine wether the code is embedded or not
  if (typeof OPT_REMOTE == "undefined") OPT_REMOTE = false;
  //Set up the AJAX send function for use with the back button
  $(document).ready(function(){$.history.init(my.ajaxsend,{unescape: true})});
  //****Public Functions****
  // Submit a categorical filter, e.g. brand.
  my.whenDOMready = function(){
    my.getRealtimePrices();
    my.load_comparisons();
    my.SliderInit();
  } 
  my.submitAJAX = function(){
      var selections = $("#filter_form").serializeObject();
      $.each(selections, function(k,v){
          if(v == "" || v == "-" || v == ";") {
            delete selections[k];
          }
          /* Slider values shouldn't get sent unless specifically set */
          if(k.match(/superfluous/)) {
            delete selections[k];
          }
      });
      my.ajaxcall("/compare/create", selections);
  }
   my.removeSilkScreen = function() {
        $('#silkscreen, #outsidecontainer').hide();
        // For ie 6, dropdown list has z-index issue. Show dropdown when popup hide.
        if($.browser.msie && $.browser.version.substr<7)        
            $('.jumpmenu').show();
    };
    
    my.current_height = (function() {
    var D = document;
    return Math.max(
        Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
        Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
        Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    );
    });
    
    //Optemo's Lightbox effect
    my.applySilkScreen = function(url,data,width,height,f) {
        // For ie 6, dropdown list has z-index issue. Hide dropdown when popup show.
        if($.browser.msie && $.browser.version.substr<7)
            $('jumpmenu').hide();
                
        //IE Compatibility
        var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body,
        dsoctop=document.all? iebody.scrollTop : window.pageYOffset;
        var outsidecontainer = $('#outsidecontainer');
        if (outsidecontainer.css('display') != 'block') 
            $('#info').html("").css({'height' : "560px", 'width' : (width-46)+'px'});
        outsidecontainer.css({'left' : '100px',
                                    'top' : (dsoctop+5)+'px',
                                    'width' : (width||560)+'px',
                                    'display' : 'inline' });
    var wWidth = $(window).width();
        $('#silkscreen').css({'height' : my.current_height()+'px', 'display' : 'inline', 'width' : wWidth + 'px'});


        if (data) {
            $('#info').html(data).css('height','');
        } else {
            quickajaxcall('#info', url, function(){
                $('#outsidecontainer').css('width','');
                $('#info').css("height",'');
                if (f) {
                    f();
                }
            });
        }
    };
  //--------------------------------------//
  //                AJAX                  //
  //--------------------------------------//

  my.loading_indicator_state = {spinner_timer : null, socket_error_timer : null, disable : false};

  /* Does a relatively generic ajax call and returns data to the handler below */
  my.ajaxsend = function (hash,myurl,mydata) {
      var lis = my.loading_indicator_state;
      //The Optemo category ID should be set in the loader unless this file is loaded non-embedded, then it is set in the opt_discovery section
      mydata = $.extend({'ajax': true, category_id: window.opt_category_id},mydata);
      if (typeof hash != "undefined" && hash != null && hash != "") {
          mydata.hist = hash;}
      else
          mydata.landing = true;
      if (!(lis.spinner_timer)) lis.spinner_timer = setTimeout("optemo_module.start_spinner()", 800);
      var val_timeout = 10000;
      if (/localhost/.test(myurl) || /192\.168/.test(myurl))
          val_timeout = 100000;
      lis.socket_error_timer = setTimeout("optemo_module.ajaxerror()", val_timeout);
      if (OPT_REMOTE) {
          //Embedded Layout
          myurl = (typeof myurl != "undefined" && myurl != null) ? myurl.replace(/http:\/\/[^\/]+/,'') : "/compare"
          // There is a bug in the JSONP implementation. If there is a "?" in the URL, with parameters already on it,
          // this JSONP implementation will add another "?" for the second set of parameters (specified in mydata).
          // For now, just check for a "?" and take those parameters into mydata, 
          // then strip them and the '?' from the URL. -ZAT July 20, 2011
          if (myurl.match(/\?/)) {
              var url_hash_to_merge = {};
              var url_params_to_merge = myurl.slice(myurl.indexOf('?') + 1).split('&');
              for(var i = 0; i < url_params_to_merge.length; i++)
              {
                  var hash = url_params_to_merge[i].split('=');
                  url_hash_to_merge[hash[0]] = hash[1];
              }
              for (i in url_hash_to_merge) {
                  if(!mydata.hasOwnProperty(i)) { // Do not merge properties that already exist.
                      mydata[i] = url_hash_to_merge[i];
                  }
              }                                          
              myurl = myurl.slice(0, myurl.indexOf('?'));
          }                    
          JSONP.get(OPT_REMOTE+myurl,mydata,ajaxhandler);
      } else {
          $.ajax({
              //type: (mydata==null)?"GET":"POST",
              data: (typeof mydata == "undefined" || mydata == null)?"":mydata,
              url: myurl || "/compare",
              success: ajaxhandler,
              error: my.ajaxerror
          });
      }
  };

  my.ajaxerror = function() {
      var lis = my.loading_indicator_state;
      lis.disable = false;
      clearTimeout(lis.spinner_timer); // clearTimeout can run on "null" without error
      my.stop_spinner();
      clearTimeout(lis.socket_error_timer); // We need to clear the timeout error here
      lis.spinner_timer = lis.socket_error_timer = null;
      var errorstr;
      if (!(typeof(optemo_french) == "undefined") && optemo_french)
          errorstr = '<div class="bb_poptitle"><label class="comp-title">Erreur</label><div class="bb_quickview_close"></div></div><p class="error">Désolé! Une erreur est survenue sur le serveur.</p><p>Vous pouvez réinitialiser l\'outil et voir si le problème est résolu.</p>';
      else
          errorstr = '<div class="bb_poptitle"><label class="comp-title">Error</label><div class="bb_quickview_close"></div></div><p class="error">Sorry! An error has occurred on the server.</p><p>You can reload the page and see if the problem is resolved.</p>';
      my.applySilkScreen(null,errorstr,600,107);
      if(typeof(my.lastpage) == "undefined")
        my.lastpage = true; //Loads the first page after the dialog is closed to try and mitigate the problem. and only do it once
  }

  my.ajaxcall = function(myurl,mydata) {
      // Disable interface elements.
      $('.slider').each(function() {
          $(this).slider("disabled", true);
      });
      $('.binary_filter, .cat_filter').attr('disabled', true);
      my.loading_indicator_state.disable = true; //Disables any live click handlers
      
      my.lasthash = window.location.hash.replace(/^#/, ''); //Save the last request hash in case there is an error
      $.history.load($("#actioncount").html(),myurl,mydata);
  };
  
  //--------------------------------------//
  //            Loading Spinner           //
  //--------------------------------------//

  my.start_spinner = function() {
      //Show the spinner up top
      var viewportwidth, viewportheight;
      if (typeof window.innerWidth != 'undefined') {  // (mozilla/netscape/opera/IE7/etc.)
          viewportwidth = window.innerWidth,
          viewportheight = window.innerHeight;
      } else { // IE6 and others
          viewportwidth = document.getElementsByTagName('body')[0].clientWidth,
          viewportheight = document.getElementsByTagName('body')[0].clientHeight;
      }
      $('#loading').css({left: viewportwidth/2 + 'px', top : viewportheight/2 + 'px'}).show();
  }
  
  my.stop_spinner = function() {
      $('#loading').hide();
  }
  
  //****Private Functions****
  function quickajaxcall(element_name, myurl, fn) { // The purpose of this is to do an ajax load without having to go through the relatively heavy ajaxcall().
      if (OPT_REMOTE)
          //Check for absolute urls
          JSONP.get(OPT_REMOTE+myurl.replace(/http:\/\/[^\/]+/,''), {embedding:'true', category_id: window.opt_category_id}, function(data){
              $(element_name).html(data);
              if (fn) fn();
          });
      else
          $(element_name).load(myurl, fn);
  }
  
  /* The ajax handler takes data from the ajax call and inserts the data into the #main part and then the #filtering part. */
  function ajaxhandler(data) {
      var lis = my.loading_indicator_state;
      lis.disable = false;
      clearTimeout(lis.spinner_timer); // clearTimeout can run on "null" without error
      my.stop_spinner();
      clearTimeout(lis.socket_error_timer); // We need to clear the timeout error here
      lis.spinner_timer = lis.socket_error_timer = null;
      
      var parts = data.split('[BRK]');
      if (parts.length == 2) {
        $('#ajaxfilter').empty().append(parts[1]);
        $('#main').html(parts[0]);
        my.whenDOMready();
        return 0;
      }
  };
  
  //Serialize an form into a hash, Warning: duplicate keys are dropped
  $.fn.serializeObject = function(){
      var o = {};
      var a = this.serializeArray();
      $.each(a, function() {
        //So that multiple checkboxes don't get overwritten, if the value exists, turn it into an array
          if (o[this.name] !== undefined) {
              //if (!o[this.name].push) {
              //    o[this.name] = [o[this.name]];
              //}
              //o[this.name].push(this.value || '');
              //Don't use an array - just concatenate with *
              o[this.name] = o[this.name] + "*" + this.value || '';
          } else {
              o[this.name] = this.value || '';
          }
      });
      return o;
  };
  /* LiveInit functions */
  $(".bb_quickview_close, #silkscreen").live('click', function(){
      my.removeSilkScreen();
      if (typeof(my.lastpage) != "undefined" && my.lastpage) {
        //There was an error in the last request
        $("#actioncount").html(my.lasthash); //Undo the last action
        my.ajaxcall("/");
        my.lastpage = false;
      }
  });
  
  //Pagination links
  $('.pagination a').live("click", function(){
      if (my.loading_indicator_state.disable) return false;
      my.ajaxcall($(this).attr('href'));
      return false;
  });
  //See all Products
  $('.seeall').live('click', function() {
      my.ajaxcall('/', {});
      return false;
  });
  // Change sort method
  $('.sortby').live('click', function() {
      if (my.loading_indicator_state.disable) return false;
      my.ajaxcall("/compare", {"sortby" : $(this).attr('data-feat')});
      return false;
  });
  
  /* End of LiveInit Functions */
  return my;
})(optemo_module || {});