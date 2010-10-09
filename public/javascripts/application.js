// The reorganization of this file should be into private and public parts. By and large, these are private functions.

/* Application-specific Javascript. 
   This is for the grid & list views (Optemo Assist & Optemo Direct) only.
   
   If you add a function and don't add it to the table of contents, prepare to be punished by your god of choice.
 
   ---- UI Manipulation ----
    removeSilkScreen()
    applySilkScreen(url, data, width, height)  -  Puts up fading boxes
    saveProductForComparison(id, imgurl, name)  -  Puts comparison items in #savebar_content and stores them in a cookie
    renderComparisonProducts(id, imgurl, name)  -  Does actual insertion of UI elements
    removeFromComparison(id)  -  Removes comparison items from #savebar_content
    removeBrand(str)   -  Removes brand filter (or other categorical filter)
    submitCategorical()  -  Submits a categorical filter (no longer does tracking)
    submitsearch()  -  Submits a search via the main search field in the filter bar
    histogram(element, norange)  -  draws histogram
    disableFiltersAndGroups()  -  Disables filters, so that the UI is only fielding one request at a time.

   ---- Data Manipulation ----
    findBetter(id, feat) - Checks if a better product exists for that feature. PROBABLY DEPRECATED
  
   ---- Piwik Tracking Functions ----
    trackPage(page_title, extra_data)  -  Piwik tracking per page. Extra data is in JSON format, with keys for ready parsing by Piwik into piwik_log_preferences. 
                                       -  For more on this, see the Preferences plugin in the Piwik code base.
                -- these next two functions are probably deprecated --
    trackCategorical(name, val, type)  -  Piwik tracking per category (old function for sliders also)
    trackSlider(slider_name, current_min, current_max, data_min, data_max, ui_position)  -  Track slider usage
 
   ---- JQuery Initialization Routines ----
    FilterAndSearchInit()  -  Search and filter areas.
 	CompareInit()  -   Compare Products screen
	ErrorInit()  -  Error pages
    DBinit()  -   UI elements from the _discoverybrowser partial, also known as <div id="main">.
	ShowInit()  -  Single product page (the compare#show action)
	
   ---- document.ready() ----
    document.ready()  -  The jquery call that gets everything started.

*/

var optemo_module;

(function ($) { // See bottom, this is for jquery noconflict
optemo_module = (function (my){
    // Language support disabled for now
    //var language;
    // The following is pulled from optemo.html.erb
    var IS_DRAG_DROP_ENABLED = ($("#dragDropEnabled").html() === 'true');
    var MODEL_NAME = $("#modelname").html();
    var VERSION = $("#version").html();
    var DIRECT_LAYOUT = ($('#directLayout').html() === 'true');
    var SESSION_ID = parseInt($('#seshid').attr('session-id'));

    //--------------------------------------//
    //           UI Manipulation            //
    //--------------------------------------//

    my.removeSilkScreen = function() {
        $('.selectboxfilter').css('visibility', 'visible');
        $('#fade').css({'display' : 'none', 'top' : '', 'left' : '', 'width' : '', 'opacity' : ''});
        $('#outsidecontainer').css({'display' : 'none'});
        $('#outsidecontainer').unbind('click');
        $('#filter_bar_loading').css({'display' : 'none'});
    };

    my.applySilkScreen = function(url,data,width,height) {
    	//IE Compatibility
    	var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body
    	var dsoctop=document.all? iebody.scrollTop : pageYOffset
    	$('#info').html("");
    	$('#outsidecontainer').css({'left' : ((document.body.clientWidth-(width||800))/2)+'px',
    								'top' : (dsoctop+5)+'px',
    								'width' : width||800,
    								'height' : height||770,
    								'display' : 'inline' });
    	
        /* This is used to get the document height for doing layout properly. */
        /*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
        current_height = (function() {
            var D = document;
            return Math.max(
                Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
                Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
                Math.max(D.body.clientHeight, D.documentElement.clientHeight)
            );
        })();
            	
    	$('#fade').css({'height' : current_height+'px', 'display' : 'inline'});
    	$('.selectboxfilter').css('visibility', 'hidden');
    	if (data)
    		$('#info').html(data);
    	else
    		$('#info').load(url,function(){CompareInit(); my.DBinit();});	
    };

    // When you click the Save button:
    my.saveProductForComparison = function(id, imgurl, name) {
    	/* We need to store the entire thing for Flooring. Eventually this will probably not be an issue 
    	since we won't be pulling images directly from another website. Keep original code below 
    	imgurlToSaveArray = imgurl.split('/');
	
    	imgurlToSaveArray[imgurlToSaveArray.length - 1] = id + "_s.jpg";
    	productType = imgurlToSaveArray[(imgurlToSaveArray.length - 2)];
    	productType = productType.substring(0, productType.length-1);
    	imgurlToSave = imgurlToSaveArray.join("/");
    */
    	productType = MODEL_NAME;
    	imgurlToSave = imgurl;
    	if($(".saveditem").length == 4)
    	{
    		$("#too_many_saved").css("display", "block");
    	}
    	else
    	{
    	//Check if this id has already been added.
    	if(null != document.getElementById('c'+id)){
    		$("#already_added_msg").css("display", "block");
    	} else {
    	    ignored_ids = my.getAllShownProductIds();
            my.trackPage('goals/save', {'filter_type' : 'save', 'product_picked' : id, 'product_ignored' : ignored_ids});
        
    		my.renderComparisonProducts(id, imgurl, name);
    		addValueToCookie('savedProductIDs', [id, imgurlToSave, name, productType]);
    	}

    	// There should be at least 1 saved item, so...
    	// 1. show compare button	
    	$("#compare_button").css("display", "block");
    	// 2. hide 'add stuff here' message
    	$("#deleteme").css("display", "none");
    	}
    };

    my.renderComparisonProducts = function(id, imgurl, name) {
    	// Create an empty slot for product
    	$('#opt_savedproducts').append("<div class='saveditem' id='c" + id + "'> </div>");

    	// The best is to just leave the medium URL in place, because that image is already loaded in case of comparison, the common case.
    	// For the uncommon case of page reload, it's fine to load a larger image.
    	//	imgurl.replace(/_m/g, "_s")
    	smallProductImageAndDetail = "<img class=\"productimg\" src=" + // used to have width=\"45\" height=\"50\" in there, but I think it just works for printers...
    	imgurl + 
    	" data-id=\""+id+"\" alt=\""+id+"_s\"/ width=\"50\">" + 
    	"<div class=\"smalldesc\"";
    	// It looks so much better in Firefox et al, so if there's no MSIE, go ahead with special styling.
    	//if ($.browser.msie) smallProductImageAndDetail = smallProductImageAndDetail + " style=\"position:absolute; bottom:5px;\"";
    	smallProductImageAndDetail = smallProductImageAndDetail + ">" +
    	"<a class=\"easylink\" data-id=\""+id+"\" href=\"#\">" + 
    	((name) ? getShortProductName(name) : 0) +
    	"</a></div>" + 
    	"<a class=\"deleteX\" data-name=\""+id+"\" href=\"#\" onClick=\"javascript:removeFromComparison("+id+");return false;\">" + 
    	"<img src=\"/images/close.png\" alt=\"Close\"/></a>";
    	$(smallProductImageAndDetail).appendTo('#c'+id);
    	my.DBinit();

    	$("#already_added_msg").css("display", "none");
    	$("#too_many_saved").css("display", "none");
    	if ($.browser.msie) // If it's any browser other than IE, clear the height element.
    		$("#opt_savedproducts").css({"height" : ''});
    	$("#opt_savedproducts img").each(function() {
    	    $(this).removeClass("productimg");
        });
    };

    // When you click the X on a saved product:
    function removeFromComparison(id)
    {
    	$('#c'+id).remove();
    	my.trackPage('goals/remove', {'filter_type' : 'remove_from_comparison', 'product_picked' : id});

    	$("#already_added_msg").css("display", "none");
    	$("#too_many_saved").css("display", "none");
	
    	removeValueFromCookie('savedProductIDs', id);
    	if($('.saveditem').length == 0){
    		$("#compare_button").css("display", "none");
    		$("#deleteme").css("display", "block");
    	}
    	return false;
    }

    function removeBrand(str)
    {
    	$('#myfilter_Xbrand').attr('value', str);
    	my.ajaxcall("/compare/filter", $("#filter_form").serialize());
    }

    function submitCategorical(){
        var arguments_to_send = [];
        arguments = $("#filter_form").serialize().split("&");
        for (i=0; i<arguments.length; i++)
        {
            if (!(arguments[i].match(/^superfluous/) || arguments[i].match(/authenticity_token/)))
                arguments_to_send.push(arguments[i]);
        }
    	my.ajaxcall("/compare/filter?ajax=true", $("#search_form").serialize() + "&" + arguments_to_send.join("&"));
    	// Everything that calls submitCategorical() should have already called trackPage uniquely
    	// my.trackPage('goals/filter/autosubmit');
    	return false;
    }

    function submitsearch() {
    	my.trackPage('goals/search', {'filter_type' : 'search', 'search_text' : $("#search_form input#search").attr('value'), 'previous_search_text' : $("#previous_search_word").attr('value')});
    	var arguments_to_send = [];
        arguments = $("#filter_form").serialize().split("&");
        for (i=0; i<arguments.length; i++)
        {
            if (!(arguments[i].match(/^superfluous/) || arguments[i].match(/authenticity_token/))) 
                arguments_to_send.push(arguments[i]);
        }
    	my.ajaxcall("/compare/filter?ajax=true", $("#search_form").serialize() + "&" + arguments_to_send.join("&"));
    	return false;
    }

    // Draw slider histogram, called for each slider above
    function histogram(element, norange) {
    	var raw = $(element).attr('data-data');
    	if (raw)
    		var data = raw.split(',');
    	else
    		var data = [0.5,0.7,0.1,0,0.3,0.8,0.6,0.4,0.3,0.3];
    	//Data is assumed to be 10 normalized elements in an array
    	var peak = 0,
    	trans = 4,
    	step = peak + 2*trans,
    	height = 20,
    	length = 174,
    	shapelayer = Raphael(element,length,height),
    	h = height - 1;
    	if (MODEL_NAME == "flooring_builddirect") {
    	    t = shapelayer.path({fill: "#ffca44", stroke: "#83571d", opacity: 0.75});
        }
        else {
    	    t = shapelayer.path({fill: "#bad0f2", stroke: "#039", opacity: 0.75});
        }
    	t.moveTo(0,height);

    	init = 4;
    	for (var i = 0; i < data.length; i++)
    	{
    	t.cplineTo(init+i*step+trans,h*(1-data[i])+1,5);
    	t.lineTo(init+i*step+trans+peak,h*(1-data[i])+1);	
    	//shapelayer.text(i*step+trans+5, height*0.5, i);
    	}
    	t.cplineTo(init+(data.length)*step+4,height,5);
    	t.andClose();
    }

    my.disableFiltersAndGroups = function() {
        // This will turn on the fade for the left area
        elementToShadow = $('#leftbar');
        var pos = elementToShadow.offset();  
        var width = elementToShadow.width();
        var height = elementToShadow.height();
        $('#fade').css({'display' : 'inline', 'left' : pos.left + "px", 'top' : pos.top + "px", 'height' : height, 'width' : width, 'opacity' : 0.2});
        document.getElementById('fade').onclick = undefined;     // Cannot use jquery for this since the onclick event is put in the HTML
        $('#filter_bar_loading').css({'display' : 'inline', 'left' : (pos.left + (width-100)/2.0) + "px"});
    };

    //--------------------------------------//
    //          Data Manipulation           //
    //--------------------------------------//

    my.findBetter = function(id, feat) {
           // Check if better product exists for that feature using /compare/better Rails me
           // Query.get( url, [data], [callback], [type] )
           $.get("/direct_comparison/better?original=" + id + "&feature=" + feat, 
                   function(data){
                           if (data == "-1")
                           {
                                   $('#betternotfoundmsg').css('visibility', 'visible');
                           }
                           else
                           {
                                   // found better printer (with id stored in data)
                                   window.location = "/direct_comparison/index/" + id + "-" + data;
                           }
                   }, "text");
    };

    //--------------------------------------//
    //       Piwik Tracking Functions       //
    //--------------------------------------//

    my.trackPage = function(page_title, extra_data){ 
    	try {
    	    if (!extra_data) extra_data = {}; // If this argument didn't get sent, set an empty hash
    		extra_data['optemo_session'] = SESSION_ID;
    		extra_data['version'] = VERSION;
    		extra_data['interface_view'] = (DIRECT_LAYOUT ? 'direct' : 'assist');
    		piwikTracker.setDocumentTitle(page_title);
    		piwikTracker.setCustomData(extra_data);
    		piwikTracker.trackPageView();
    		// I'm not sure what emptying the title and data do, but it seems like a standard pattern.
    		piwikTracker.setDocumentTitle('');
    		piwikTracker.setCustomData({});
    	} catch( err ) {  } // Do nothing, in order to not stop execution of the script. In testing, though, use this line: console.log("Something happened: " + err);
    };

    // Pretty sure these two can be deprecated now.
    /* function trackCategorical(name, val, type){
    	piwikTracker.setCustomData(info);
    	piwikTracker.trackPageView();
    	piwikTracker.setCustomData({});
    } 

    function trackSlider(slider_name, current_min, current_max, data_min, data_max, ui_position){
    	var info = {'slider_min' : current_min, 'slider_max' : current_max, 
    	            'slider_name' : slider_name, 'optemo_session' : SESSION_ID, 'version' : VERSION, 'filter_type' : 'slider', 'ui_position' : ui_position};
    	piwikTracker.setCustomData(info);
    	piwikTracker.trackPageView();
    	piwikTracker.setCustomData({});
    } */


    //--------------------------------------//
    //       Initialization Routines        //
    //--------------------------------------//

    my.FilterAndSearchInit = function() {
        my.removeSilkScreen();
    
    	//Show and Hide Descriptions
    	$('.feature .label a, .catlabel a, .desc .deleteX').unbind('click').click(function(){
    		if($(this).parent().attr('class') == "desc")
    			{var obj = $(this).parent();}
    		else
    			{var obj = $(this).siblings('.desc');}
            // I think this is just toggling. Just on the off chance that something weird is happening here, I'll leave this code for now. ZAT 2010-08
            obj.toggle();
    //		var flip=parseInt(obj.attr('name-flip'));
    //		if (isNaN(flip)){flip = 0;}
    //		obj.toggle(flip++ % 2 == 0);
    //		obj.attr('name-flip',flip);
            if( obj.is(':visible') ) {
        		my.trackPage('goals/label', {'filter_type' : 'description', 'ui_position' : obj.parent().attr('data-position')});
    		}
    		return false;
    	});
	
    	//Search submit
    	$('#submit_button').unbind('click').click(function(){
    		return submitsearch();
    	});
	
    	//Search submit
    	$('#search').keypress(function (e) {
    		if (e.which==13)
    			return submitsearch();
    	});
	
    	// Initialize Sliders
    	$('.slider').each(function() {
    		threshold = 20;							// The parameter that identifies that 2 sliders are too close to each other
    		force_int = $(this).attr('force-int');
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
    					curmin = parseFloat($(this).attr('data-startmin'));
    					curmax = parseFloat($(this).attr('data-startmax'));
    				}
    				else
    				{
    					curmin = parseInt($(this).attr('data-startmin'));
    					curmax = parseInt($(this).attr('data-startmax'));
    				}
    				var diff = ui.values[1] - ui.values[0];
    				if (diff < threshold)
    				{
    					if(ui.value == ui.values[0])	// Left slider
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
    					if ((increment * 1.1) < acceptableincrements[i])  // The fudge factor here is required.
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
    				if (realvalue > datasetmax && sliderno == 0) {
    				    realvalue = datasetmax;
    				    leftsliderknob.css('left', (datasetmax * 99.9 / rangemax) + "%");
    				    // Store the fact that it went too far using data()
    				    leftsliderknob.data('toofar', true);
    			    }
    				// Prevent the right slider knob from going too far to the left (past all the current data)
    			    if (realvalue < datasetmin && sliderno == 1) {
    			        realvalue = datasetmin;
    				    rightsliderknob.css('left', (datasetmin * 100.1 / rangemax) + "%");
    				    rightsliderknob.data('toofar', true);
    			    }
    				if (increment < 1) { 
    					// floating point division has problems; avoid it 
    					tempinc = parseInt(1.0 / increment);
    					realvalue = parseInt(realvalue * tempinc) / tempinc;
    				}
    				else
    					realvalue = parseInt(realvalue / increment) * increment;
				
    				// This makes sure that when sliding to the extremes, you get back to the real starting points
    				if (sliderno == 1 && ui.values[1] == 100)
    					realvalue = rangemax;
    				else if (sliderno == 0 && ui.values[0] == 0)
    					realvalue = rangemin;
					
    				if (sliderno == 0 && ui.values[0] != ui.values[1])						// First slider is not identified correctly by sliderno for the case
    					leftsliderknob.html(realvalue).addClass("valabove");			// when rightslider = left slider, hence the second condition
    				else if (ui.values[0] != ui.values[1])
    					rightsliderknob.html(realvalue).addClass("valabove");
					
    				if(sliderno == 0)
    				{
    					$(this).siblings('.min').attr('value',realvalue);
    					$(this).siblings('.max').attr('value',curmax);
    				}
    				else
    				{
    					$(this).siblings('.min').attr('value',curmin);
    					$(this).siblings('.max').attr('value',realvalue);
    				}
					
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
    				var diff = ui.values[1] - ui.values[0];
    				if (diff > threshold)
    				{
    					leftsliderknob.removeClass("valabove").addClass("valbelow");
    					rightsliderknob.removeClass("valabove").addClass("valbelow");
    				}
    				var sliderinfo = {'slider_min' : parseFloat(ui.values[0]) * rangemin / 100.0, 'slider_max' : parseFloat(ui.values[1]) * rangemax / 100.0, 
                	            'slider_name' : $(this).attr('data-label'), 'filter_type' : 'slider', 'data_min' : datasetmin, 'data_max' : datasetmax, 'ui_position' : $(this).parent().find('.label').attr('data-position')};
    				my.trackPage('goals/filter/slider', sliderinfo);
    				var arguments_to_send = [];
                    arguments = $("#filter_form").serialize().split("&");
                    for (i=0; i<arguments.length; i++)
                    {
                        if (!(arguments[i].match(/^superfluous/) || arguments[i].match(/authenticity_token/)))
                            arguments_to_send.push(arguments[i]);
                    }
                    if (leftsliderknob.data('toofar') || rightsliderknob.data('toofar')) {
                        sliderinfo['filter_type'] = 'forced_stop';
        				my.trackPage('goals/filter/forcedstop', sliderinfo);
    				    leftsliderknob.removeData('toofar');
    				    rightsliderknob.removeData('toofar');
                    }
                    my.loading_indicator_state.main = true;
                	my.ajaxcall("/compare/filter?ajax=true", $("#search_form").serialize() + "&" + arguments_to_send.join("&"));
    			}
    		});
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
    	});
    	// Add a brand -- submit
    	$('.selectboxfilter').each(function(){
    	    $(this).unbind('change').change(function(){
    	        $(this).unbind();
    		    var whichThingSelected = $(this).val();
    			var whichSelector = $(this).attr('name');
    		    var categorical_filter_name = whichSelector.substring(whichSelector.indexOf("[")+1, whichSelector.indexOf("]"));
        		$('#myfilter_'+categorical_filter_name).val(appendStringWithToken($('#myfilter_'+categorical_filter_name).val(), whichThingSelected, '*'));
        		var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : categorical_filter_name, 'filter_type' : 'categorical'};
            	my.trackPage('goals/filter/categorical', info);
        		submitCategorical();
        		return false;
        	});
    	});
	
    	// Remove a brand -- submit
    	$('.removefilter').each(function(){
    		$(this).unbind('click').click(function(){
    			var whichRemoved = $(this).attr('data-id');
    			var whichCat = $(this).attr('data-cat');
    			$('#myfilter_'+whichCat).val(removeStringWithToken($('#myfilter_'+whichCat).val(), whichRemoved, '*'));
        		var info = {'chosen_categorical' : whichRemoved, 'slider_name' : whichCat, 'filter_type' : 'categorical_removed'};
            	my.trackPage('goals/filter/categorical_removed', info);
    			submitCategorical();
    			return false;
    		});
    	});
	
    	// In simple view, select an aspect to create viewable groups
    	$('.groupby').each(function(){
    		$(this).unbind('click').click(function(){
    			feat = $(this).attr('data-feat');
        		my.trackPage('goals/showgroups', {'filter_type' : 'groupby', 'feature_name': feat, 'ui_position': $(this).attr('data-position')});
    			my.ajaxcall("/compare/groupby/?feat="+feat);
    		});
    	});
	
        // Choose a grouping via group button rather than drop-down (effect is the same as the select boxes)
    	$('.title').each(function(){
    		$(this).unbind('click').click(function(){
    		    $(this).unbind();
    		    if ($(this).find('.choose_group').length) { // This is a categorical feature
        		    group_element = $(this).find('.choose_group');
                	var whichThingSelected = group_element.attr('data-min');
                	var categorical_filter_name = group_element.attr('data-grouping');
                	if($('#myfilter_'+categorical_filter_name).val().match(whichThingSelected) === null)
                    	$('#myfilter_'+categorical_filter_name).val(appendStringWithToken($('#myfilter_'+categorical_filter_name).val(), whichThingSelected, '*'));
                	var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : categorical_filter_name, 'filter_type' : 'categorical_from_groups'};
                	my.trackPage('goals/filter/categorical_from_groups', info);
                	submitCategorical();
                    return false;
            	}
            	else { // This is a continuous feature
            	    group_element = $(this).find('.choose_cont_range');
            	    feat = group_element.attr('data-grouping');
        	        lowerbound = group_element.attr('data-min');
        	        upperbound = group_element.attr('data-max');
        	        var arguments_to_send = [];
        	        arguments = $("#filter_form").serialize().split("&");
        	        for (i=0; i<arguments.length; i++)
                    {
                        if (arguments[i].match(feat)) {
                            split_arguments = arguments[i].split("=")
                            if (arguments[i].match(/min/))
                                split_arguments[1] = lowerbound;
                            else
                                split_arguments[1] = upperbound;
                            arguments[i] = split_arguments.join("=");
                        }
                        if (!(arguments[i].match(/^superfluous/)))
                            arguments_to_send.push(arguments[i]);
                    }
            		my.trackPage('goals/filter/continuous_from_groups', {'filter_type' : 'continuous_from_groups', 'feature_name': group_element.attr('data-grouping'), 'selected_continuous_min' : lowerbound, 'selected_continuous_max' : upperbound});
                    my.ajaxcall("/compare/filter/?ajax=true&" + arguments_to_send.join("&"));
        	    }
    		});
    	});

    	//Show Additional Features
    	$('#morefilters').unbind('click').click(function(){
    		$('.extra').show("slide",{direction: "up"},100);
    		$(this).css('display','none');
    		$('#lessfilters').css('display','block');
    		return false;
    	});

    	$('#removeSearch').unbind('click').click(function(){
    		$('#previous_search_word').val('');
    		$('#previous_search_container').remove();
        	return false;
     	});
	
    	//Hide Additional Features
    	$('#lessfilters').unbind('click').click(function(){
    		$('.extra').hide("slide",{direction: "up"},100);
    		$(this).css('display','none');
    		$('#morefilters').css('display','block');
    		return false;
    	});
	
    	// Sliders -- submit
    	$('.autosubmit').unbind('change').change(function() {
    	    my.trackPage('goals/filter/autosubmit', {'filter_type' : 'autosubmit'});
    		submitCategorical();
    	});
	
    	// Checkboxes -- submit
    	$('.autosubmitbool').unbind('click').click(function() {
    		var whichbox = $(this).attr('id');
    		var box_value = $(this).attr('checked') ? 100 : 0;
    		my.trackPage('goals/filter/checkbox', {'feature_name' : whichbox});
    		submitCategorical();
    	});
    	if ($.browser.msie) 
    	{
    	    // If it's any version of IE, the transparency for the hands doesn't get done properly on page load - redo it here.
    		$('.dragHand').each(function() {
    			$(this).fadeTo("fast", 0.35);
    		});
            // Fix the slider position
        	$('.hist').each(function() {
               $(this).css('left', '7px');
            });
    	}
    };

    function CompareInit() {
    	//-------Info Popup--------//
    	// This isn't being used at the moment in any layout, as far as I can tell. ZAT 2010-03
        //	$("#comparisonTable").tableDnD({
        //		onDragClass: "rowBeingDragged",
        //		onDrop: function(table, row) {		
        //			newPreferencesString = $.tableDnD.serialize();
        //		}
        //	});
    	//Remove buttons on compare
    	$('.remove').unbind('click').click(function(){
    		removeFromComparison($(this).attr('data-name'));
    		$(this).parents('.column').remove();
		
    		// If this is the last one, take the comparison screen down too
    		if ($('#comparisonmatrix .column').length == 1) {
    			my.removeSilkScreen();
    		}
    		return false;
    	});
    }

    my.ErrorInit = function() {
        //Link from popup (used for error messages)
        $('#outsidecontainer').unbind('click').click(function(){
        	my.removeSilkScreen();
        	return false;
        });
    };

    my.DBinit = function() {
    	showpage = (function(currentelementid) {
            my.applySilkScreen('/compare/show/'+currentelementid+'?plain=true',null, 800, 800);
     		ShowInit();
     		// There is tracking being done below, so take this out probably
    // 		trackPage('products/show/'+currentelementid); 
        });
        if (DIRECT_LAYOUT) { // in Optemo Direct, a click anywhere on the product box goes to the show page
            $('.nbsingle').unbind("click").click(function(){ 
         		currentelementid = $(this).find('.productinfo').attr('data-id');
         		ignored_ids = my.getAllShownProductIds();
         		product_title = $(this).find('img.productimg').attr('title');
        		my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids});
         		showpage(currentelementid);
         		return false;
        	});
        	// In addition, set up the images on the "show groups" page to be clickable.
        	$(".productimg").unbind("click").click(function (){
                currentelementid = $(this).attr('data-id');
                if(currentelementid === undefined) { currentelementid = $(this).find('.productimg').attr('data-id'); }
        		ignored_ids = my.getAllShownProductIds();
         		product_title = $(this).find('img.productimg').attr('title');
        		my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids});
         		showpage(currentelementid);
         		return false;            
            });
        } else { // in Optemo Assist, a click only on the picture or .easylink product name will trigger the show page
            $(".productimg, .easylink").unbind("click").click(function (){
                currentelementid = $(this).attr('data-id');
        		ignored_ids = my.getAllShownProductIds();
         		product_title = $(this).find('img.productimg').attr('title');
        		my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids});
         		showpage(currentelementid);
         		return false;            
            });  
        }
    	if (optemo_module.IS_DRAG_DROP_ENABLED)
    	{
    		// Make item boxes draggable. This is a jquery UI builtin.		
    		$(".image_boundingbox img, .image_boundingbox_line img, img.productimg").each(function() {
    			$(this).draggable({ 
    				revert: 'invalid', 
    				cursor: "move", 
    				// The following defines the drag distance before a "drag" event is actually initiated. Helps for people who click while the mouse is slightly moving.
    				distance:2,
    				helper: 'clone',
    				zIndex: 1000,
    				start: function(e, ui) { 
    					if ($.browser.msie) // Internet Explorer sucks and cannot do transparency
    					    $(this).css({'opacity':'0.4'});
    				},
    				stop: function (e, ui) {
    					if ($.browser.msie)
    						$(this).css({'opacity':'1'});
    				}
    			});
                $(this).hover(function() {
    	                $(this).find('.dragHand').stop().animate({ opacity: 1.0 }, 150);
    			    },
    		        function() {
    	            	$(this).find('.dragHand').stop().animate({ opacity: 0.35 }, 450);
               });
    	    });
    	    $(".dragHand").each(function() {
    	        $(this).draggable({
    	            revert : 'invalid',
    	            cursor: 'move',
    	            distance: 2,
    	            helper: 'clone',
    	            zIndex: 1000
    	        });
    	    });
    	}
	
    	//Ajax call for simlinks
    	$('.simlinks').unbind("click").click(function(){ 
    		my.ajaxcall($(this).attr('href')+'?ajax=true');
    		ignored_ids = my.getAllShownProductIds(); 
    		my.trackPage('goals/browse_similar', {'filter_type' : 'browse_similar', 'product_picked' : $(this).attr('data-id') , 'product_ignored' : ignored_ids, 'picked_cluster_layer' : $(this).attr('data-layer'), 'picked_cluster_size' : $(this).attr('data-size')});
    		return false;
    	});

    	//Pagination links
        // This convoluted line takes the second-last element in the list: "<< prev 1 2 3 4 next >>" and takes its numerical page value. 
    	total_pages = parseInt($('.pagination').children().last().prev().html());
    	$('.pagination a').unbind("click").click(function(){
    		url = $(this).attr('href')
    		if (url.match(/\?/))
    			url +='&ajax=true'
    		else
    			url +='?ajax=true'
    		if ($(this).hasClass('next_page'))
        		my.trackPage('goals/next', {'filter_type' : 'next' , 'page_number' : parseInt($('.pagination .current').html()), 'total_number_of_pages' : total_pages});
    		else
    		    my.trackPage('goals/next', {'filter_type' : 'next_number' , 'page_number' : parseInt($(this).html()), 'total_number_of_pages' : total_pages});		
    		my.ajaxcall(url);
    		return false;
    	});
    	//Autocomplete for searchterms
    	model = MODEL_NAME.toLowerCase();
    	// Now, evaluate the string to get the actual array, defined in autocomplete_terms.js and auto-built by the rake task autocomplete:fetch
    	terms = eval(model + "_searchterms"); // terms now = ["waterproof", "digital", ... ]
    	$("#search").autocomplete(terms, {
    		minChars: 1,
    		max: 10,
    		autoFill: false,
    		mustMatch: false,
    		matchContains: true,
    		scrollHeight: 220
    	});
	
    	$('#surveysubmit').click(function(){
    		my.trackPage('survey/submit');
    		$('#feedback').css('display','none');
    		my.applySilkScreen('/survey/submit?' + $("#surveyform").serialize(), null, 300, 70);
    		return false;
    	});
    	$('#yesdecisionsubmit').click(function(){
    		my.trackPage('survey/yes');
    		my.applySilkScreen('/survey/index', null, 600, 835);
    		return false;
    	});
    	$('#nodecisionsubmit').click(function(){
    		my.removeSilkScreen();
    		my.trackPage('survey/no');
    		return false;
    	});
    };

    function ShowInit() {
    	$('.buylink, .buyimg').unbind("click").click(function(){
    		var buyme_id = $(this).attr('product');
    		my.trackPage('goals/addtocart', {'picked_product' : buyme_id});
    	});
    }
    return my;
})(optemo_module || {});
})(jQuery);

//--------------------------------------//
//          document.ready()            //
//--------------------------------------//

jQuery.noConflict();
jQuery(document).ready(function($) {
	// Due to a race condition in IE6, this must be before DBinit().
	
	trackPage = optemo_module.trackPage;
	var tokenizedArrayID = 0;
	if (opt_savedproducts = optemo_module.readAllCookieValues('savedProductIDs'))
	{
		// There are saved products to display
		if ($.browser.msie) {
			fixedheight = ((opt_savedproducts.length > 2) ? 80 : 160) + 'px';
			$("#opt_savedproducts").css({"height" : fixedheight});
		}
		for (tokenizedArrayID = 0; tokenizedArrayID < opt_savedproducts.length; tokenizedArrayID++)
		{	
			tokenizedArray = opt_savedproducts[tokenizedArrayID].split(',');
			// In future, tokenizedArray[3] contains the product type. As of Feb 2010, each website has separate cookies, so it's not necessary to read this data.
			optemo_module.renderComparisonProducts(tokenizedArray[0], tokenizedArray[1], tokenizedArray[2]);
		}
		// There should be at least 1 saved item, so...
		// 1. show compare button	
		$("#compare_button").css("display", "block");
		// 2. hide 'add stuff here' message
		$("#deleteme").css("display", "none");
	}
	
	$.history.init(optemo_module.ajaxsend);
	
	// Only load DBinit if it will not be loaded by the upcoming ajax call
	if ($('#opt_discovery').length == 0) {
		// Other init routines get run when they are needed.
		optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
	}
	// All the initializations in a row.
	
	//Find product language - Not used at the moment ZAT 2010-03
//	language = (/^\s*English/.test($(".languageoptions:first").html())==true)?'en':'fr';

	//Decrypt encrypted links
	$('a.decrypt').each(function () {
		$(this).attr('href',$(this).attr('href').replace(/[a-zA-Z]/g, function(c){
			return String.fromCharCode((c<="Z"?90:122)>=(c=c.charCodeAt(0)+13)?c:c-26);
			}));
	});

	// Global to the entire page - Fadein
	// May want to make this a jquery .live() call; check jquery 1.4 documentation for this later
	$(".close").click(function(){
		optemo_module.removeSilkScreen();
		return false;
	});
    
	if (optemo_module.IS_DRAG_DROP_ENABLED)
	{
		// Make savebar area droppable. jquery UI builtin.
		$("#savebar").each(function() {
			$(this).droppable({ 
				hoverClass: 'drop-box-hover',
				activeClass: 'ui-state-dragging', 
				accept: ".ui-draggable, .dragHand",
				drop: function (e, ui) {
					imgObj = $(ui.helper);
					if (imgObj.hasClass('dragHand')) { // This is a drag hand object
				        realImgObj = imgObj.parent().find('.productimg');
    					optemo_module.saveProductForComparison(realImgObj.attr('data-id'), realImgObj.attr('src'), realImgObj.attr('alt'));
				    }
				    else { // This is an image object; behave as normal
    					optemo_module.saveProductForComparison(imgObj.attr('data-id'), imgObj.attr('src'), imgObj.attr('alt'));
					}
				}
			 });
		});
	}
	
	//Call overlay for product comparison
	$("#compare_button").click(function(){
		var productIDs = '';
		// For each saved product, get the ID out of the id=#opt_savedproducts children.
		$('#opt_savedproducts').children().each(function() {
			// it's a saved item if the CSS class is set as such. This allows for other children later if we feel like it.
			if ($(this).attr('class').indexOf('saveditem') != -1) 
			{
				// Build a list of product IDs to send to the AJAX call
				productIDs = productIDs + $(this).attr('id').substring(1) + ',';
			}
		});
		// The following line could be useful later. Rather than hard-coding, we could use the 'overflow:scroll' CSS property to limit
		// the display window height. But, right now this breaks the layout, so let's fix it later with less time pressure.
		//var viewportHeight = $(window).height();
		optemo_module.applySilkScreen('/direct_comparison/index/' + productIDs, null, 940, 580);/*star-h:580*/
		trackPage('goals/compare', {'filter_type' : 'direct_comparison'});
		return false;
	});
    
	//Static Ajax call
	$('#staticajax_reset').click(function(){
		trackPage('goals/reset', {'filter_type' : 'reset'});
		optemo_module.ajaxcall($(this).attr('href')+'?ajax=true');
		return false;
	});

	//Static feedback box
	$('#feedback').click(function(){
		trackPage('survey/feedback');
		optemo_module.applySilkScreen('/survey/index', null, 600, 480);
		return false;
	});
	
	if (optemo_module.DIRECT_LAYOUT) {
	    //Tour section
    	$('#popupTour1, #popupTour2, #popupTour3, #popupTour4').each(function(){
    		$(this).find('.deleteX').click(function(){
    			$(this).parent().fadeOut("slow");
    			optemo_module.clearStyles(["box0", "filterbar", "savebar", "groupby0"], 'tourDrawAttention');
    			$("#box0").removeClass('tourDrawAttention');
        		trackPage('goals/tourclose');
    			return false;
    		});
    	});
	
    	$('#popupTour1').find('a.popupnextbutton').click(function(){
    		var groupbyoffset = $("#groupby0").offset();
    		$("#popupTour2").css({"position":"absolute", "top" : parseInt(groupbyoffset.top) - 120, "left" : parseInt(groupbyoffset.left) + 220}).fadeIn("slow");
    		$("#popupTour1").fadeOut("slow");
    		$("#groupby0").addClass('tourDrawAttention');
    		$("#box0").removeClass('tourDrawAttention');
    		trackPage('goals/tournext', {'tour_page_number' : 2});
    	});

    	$('#popupTour2').find('a.popupnextbutton').click(function(){
    		var middlefeatureposition = $("#filterbar").find(".feature:eq(3)").offset();
    		$("#popupTour3").css({"position":"absolute", "top" : parseInt(middlefeatureposition.top) - 120, "left" : parseInt(middlefeatureposition.left) + 220}).fadeIn("slow");
    		$("#popupTour2").fadeOut("slow");
    		$("#filterbar").addClass('tourDrawAttention');
    		$("#groupby0").removeClass('tourDrawAttention');
    		trackPage('goals/tournext', {'tour_page_number' : 3});
    	});

    	$('#popupTour3').find('a.popupnextbutton').click(function(){
    		var comparisonposition = $("#savebar").offset();
    		$("#popupTour4").css({"position":"absolute", "top" : parseInt(comparisonposition.top) - 260, "left" : parseInt(comparisonposition.left) + 70}).fadeIn("slow");
    		$("#popupTour3").fadeOut("slow");
    		$("#savebar").addClass('tourDrawAttention');
    		$("#filterbar").removeClass('tourDrawAttention');
    		trackPage('goals/tournext', {'tour_page_number' : 4});
    	});
	
    	$('#popupTour4').find('a.popupnextbutton').click(function(){
    		$("#popupTour4").fadeOut("slow");
    		$("#savebar").removeClass('tourDrawAttention');
    		trackPage('goals/tourclose');
    	});
    } else {
    	//Tour section
    	$('#popupTour1, #popupTour2, #popupTour3').each(function(){
    		$(this).find('.deleteX').click(function(){
    			$(this).parent().fadeOut("slow");
    			optemo_module.clearStyles(["sim0", "filterbar", "savebar"], 'tourDrawAttention');
    			$("#sim0").removeClass('tourDrawAttention');
        		trackPage('goals/tourclose');
    			return false;
    		});
    	});
	
    	$('#popupTour1').find('a.popupnextbutton').click(function(){
    		var middlefeatureposition = $("#filterbar").find(".feature:eq(3)").offset();
    		$("#popupTour2").css({"position":"absolute", "top" : parseInt(middlefeatureposition.top) - 120, "left" : parseInt(middlefeatureposition.left) + 220}).fadeIn("slow");
    		$("#popupTour1").fadeOut("slow");
    		$("#filterbar").addClass('tourDrawAttention');
    		$("#sim0").removeClass('tourDrawAttention');
    		$("#sim0").parent().removeClass('tourDrawAttention');
    		trackPage('goals/tournext', {'tour_page_number' : 2});
    	});

    	$('#popupTour2').find('a.popupnextbutton').click(function(){
    		var comparisonposition = $("#savebar").offset();
    		$("#popupTour3").css({"position":"absolute", "top" : parseInt(comparisonposition.top) - 260, "left" : parseInt(comparisonposition.left) + 70}).fadeIn("slow");
    		$("#popupTour2").fadeOut("slow");
    		$("#savebar").addClass('tourDrawAttention');
    		$("#filterbar").removeClass('tourDrawAttention');
    		trackPage('goals/tournext', {'tour_page_number' : 3});
    	});
	
    	$('#popupTour3').find('a.popupnextbutton').click(function(){
    		$("#popupTour3").fadeOut("slow");
    		$("#savebar").removeClass('tourDrawAttention');
    		trackPage('goals/tourclose');
    	});
	}
	
	// On escape press. Probably not needed anymore.
	$(document).keypress(function(e){
		if(e.keyCode==27){
			$(".popupTour").fadeOut("slow");
			optemo_module.clearStyles(["sim0", "filterbar", "savebar"], 'tourDrawAttention');
			if ($.browser.msie && $.browser.version == "7.0") $("#sim0").parent().removeClass('tourDrawAttention');
    		trackPage('goals/tourclose');
		}
	});

	launchtour = (function () {
	    if (optemo_module.DIRECT_LAYOUT) {
		    var browseposition = $("#box0").offset();
    		$("#box0").addClass('tourDrawAttention');		    
    		$("#popupTour1").css({"position":"absolute", "top" : parseInt(browseposition.top) - 120, "left" : parseInt(browseposition.left) + 165}).fadeIn("slow");
    		trackPage('goals/tournext', {'tour_page_number' : 1});
		} else {
    		var browseposition = $("#sim0").offset();
    		// Position relative to sim0 every time in case of interface changes (it is the first browse similar link)
    		$("#sim0").addClass('tourDrawAttention');
    		$("#popupTour1").css({"position":"absolute", "top" : parseInt(browseposition.top) - 120, "left" : parseInt(browseposition.left) + 165}).fadeIn("slow");
    		trackPage('goals/tournext', {'tour_page_number' : 1});
    	}
		return false;
	});

	if ($('#tourautostart').length) { launchtour; } //Automatically launch tour if appropriate
	$("#tourButton a").click(launchtour); //Launch tour when this is clicked

});

