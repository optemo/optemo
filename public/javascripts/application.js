/* Application-specific Javascript. 
   This is for the grid & list views (Optemo Assist & Optemo Direct) only.
   If you add a function and don't add it to the table of contents, prepare to be punished by your god of choice.
   Functions marked ** are public functions that can be called from outside the optemo_module declaration.
 
   ---- UI Manipulation ----
    ** removeSilkScreen()
    ** applySilkScreen(url, data, width, height)  -  Puts up fading boxes
    ** saveProductForComparison(id, imgurl, name)  -  Puts comparison items in #savebar_content and stores them in a cookie
    ** renderComparisonProducts(id, imgurl, name)  -  Does actual insertion of UI elements
    removeFromComparison(id)  -  Removes comparison items from #savebar_content
    removeBrand(str)   -  Removes brand filter (or other categorical filter)
    submitCategorical()  -  Submits a categorical filter (no longer does tracking)
    submitsearch()  -  Submits a search via the main search field in the filter bar
    histogram(element, norange)  -  draws histogram
    ** disableFiltersAndGroups()  -  Disables filters, so that the UI is only fielding one request at a time.

   ---- Data Manipulation ----
    ** findBetter(id, feat) - Checks if a better product exists for that feature. PROBABLY DEPRECATED
  
   ---- Piwik Tracking Functions ----
    ** trackPage(page_title, extra_data)  -  Piwik tracking per page. Extra data is in JSON format, with keys for ready parsing by Piwik into piwik_log_preferences. 
                                       -  For more on this, see the Preferences plugin in the Piwik code base.
 
   ---- JQuery Initialization Routines ----
    ** FilterAndSearchInit()  -  Search and filter areas.
 	** LiveInit()  -   All the events that can be handled appropriately with jquery live
	ErrorInit()  -  Error pages
    ** DBinit()  -   UI elements from the _discoverybrowser partial, also known as <div id="main">.
	
   ######  Formerly from helpers.js ######
   
   -------- AJAX ---------
    ** ajaxsend(hash,myurl,mydata)  -  Does AJAX call through jquery, returns through ajaxhandler(data)
    ajaxhandler(data)  -  Splits up data from the ajax call according to [BRK] tokens. See app/views/compare/ajax.html.erb
    ajaxerror() - Displays error message if the ajax send call fails
    **ajaxcall(myurl,mydata) - adds a hash with the number of searches to the history path
    flashError(str)  -  Puts an error message on a specific part of the screen

   -------- Layout -------
    ** clearStyles()  -  Removes inline styles and named styles from a group of IDs.

   -------- Data -------
    getAllShownProductIds()  -  Returns currently displayed product IDs.
    ** getShortProductName(name)  -  Returns the shorter product name for printers. This should be extended in future.

   ------- Spinner -------
    spinner(holderid, R1, R2, count, stroke_width, colour)  -  returns a spinner object

   -------- Cookies -------
    addValueToCookie(name, value)  -  Add a value to the cookie "name" or create a cookie if none exists.
    removeValueFromCookie(name, value)  -  Remove a value from the cookie, and delete the cookie if it's empty.
    ** readAllCookieValues(name)  -  Returns an array of cookie values.

    createCookie(name,value,days)  -  Try not to use this or the two below directly if possible, they are like private methods.
    readCookie(name)  -  Gets raw cookie 'value' data.
    eraseCookie(name)

   ---- document.ready() ----
    document.ready()  -  The jquery call that gets everything started.
   
   ----- Page Loader -----
    if statement  -  This gets evaluated as soon as the ajaxsend function is ready (slight savings over document.ready()).
*/

/* LazyLoad courtesy of http://github.com/rgrove/lazyload/ already minified */
LazyLoad=function(){var f=document,g,b={},e={css:[],js:[]},a;function j(l,k){var m=f.createElement(l),d;for(d in k){if(k.hasOwnProperty(d)){m.setAttribute(d,k[d])}}return m}function h(d){var l=b[d];if(!l){return}var m=l.callback,k=l.urls;k.shift();if(!k.length){if(m){m.call(l.scope||window,l.obj)}b[d]=null;if(e[d].length){i(d)}}}function c(){if(a){return}var k=navigator.userAgent,l=parseFloat,d;a={gecko:0,ie:0,opera:0,webkit:0};d=k.match(/AppleWebKit\/(\S*)/);if(d&&d[1]){a.webkit=l(d[1])}else{d=k.match(/MSIE\s([^;]*)/);if(d&&d[1]){a.ie=l(d[1])}else{if((/Gecko\/(\S*)/).test(k)){a.gecko=1;d=k.match(/rv:([^\s\)]*)/);if(d&&d[1]){a.gecko=l(d[1])}}else{if(d=k.match(/Opera\/(\S*)/)){a.opera=l(d[1])}}}}}function i(r,q,s,m,t){var n,o,l,k,d;c();if(q){q=q.constructor===Array?q:[q];if(r==="css"||a.gecko||a.opera){e[r].push({urls:[].concat(q),callback:s,obj:m,scope:t})}else{for(n=0,o=q.length;n<o;++n){e[r].push({urls:[q[n]],callback:n===o-1?s:null,obj:m,scope:t})}}}if(b[r]||!(k=b[r]=e[r].shift())){return}g=g||f.getElementsByTagName("head")[0];q=k.urls;for(n=0,o=q.length;n<o;++n){d=q[n];if(r==="css"){l=j("link",{href:d,rel:"stylesheet",type:"text/css"})}else{l=j("script",{src:d})}if(a.ie){l.onreadystatechange=function(){var p=this.readyState;if(p==="loaded"||p==="complete"){this.onreadystatechange=null;h(r)}}}else{if(r==="css"&&(a.gecko||a.webkit)){setTimeout(function(){h(r)},50*o)}else{l.onload=l.onerror=function(){h(r)}}}g.appendChild(l)}}return{css:function(l,m,k,d){i("css",l,m,k,d)},js:function(l,m,k,d){i("js",l,m,k,d)}}}();

// These global variables must be declared explicitly for proper scope (see setTimeout)
var optemo_module;
var myspinner;
var optemo_module_activator;

optemo_module_activator = (function($) { // See bottom, this is for jquery noconflict
optemo_module = (function (my){
    // Language support disabled for now
    //var language;
    // The following is pulled from optemo.html.erb
    my.IS_DRAG_DROP_ENABLED = ($("#dragDropEnabled").html() === 'true');
    var MODEL_NAME = $("#modelname").html();
    var VERSION = $("#version").html();
    var DIRECT_LAYOUT = ($('#directLayout').html() === 'true');
    var SESSION_ID = parseInt($('#seshid').attr('session-id'));

    //--------------------------------------//
    //           UI Manipulation            //
    //--------------------------------------//

    my.removeSilkScreen = function() {
        $('.selectboxfilter').css('visibility', 'visible');
        $('#silkscreen').css({'display' : 'none', 'top' : '', 'left' : '', 'width' : ''}).fadeTo(0, 0).hide();
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
            	
    	$('#silkscreen').css({'height' : current_height+'px', 'display' : 'inline'}).fadeTo(0, 0.5);
    	$('.selectboxfilter').css('visibility', 'hidden');
    	if (data)
    		$('#info').html(data);
    	else
    		$('#info').load(url,function(){my.DBinit();});	
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
    	    ignored_ids = getAllShownProductIds();
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
    	((name) ? optemo_module.getShortProductName(name) : 0) +
    	"</a></div>" + 
    	"<a class=\"deleteX\" data-name=\""+id+"\" href=\"#\">" + 
    	"<img src=\"/images/close.png\" alt=\"Close\"/></a>";
    	$(smallProductImageAndDetail).appendTo('#c'+id);
    	my.DBinit();

    	$("#already_added_msg").css("display", "none");
    	$("#too_many_saved").css("display", "none");
    	if ($.browser.msie) // If it's IE, clear the height element.
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
        my.loading_indicator_state.sidebar = true;
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
        elementToShadow = $('#filterbar');
        var pos = elementToShadow.offset();  
        var width = elementToShadow.innerWidth() + 2; // Extra pixels are for the border.
        var height = elementToShadow.innerHeight() + 2;
        $('#silkscreen').css({'display' : 'inline', 'left' : pos.left + "px", 'top' : pos.top + 27 + "px", 'height' : height - 27 + "px", 'width' : width + "px"}).fadeTo(0,0.2); // The 27 is arbitrary - equal to the top of the filter bar (title, reset button)
        $("#silkscreen").unbind('click'); // We need this so that the user can't clear the silkscreen by clicking on it.
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

    //--------------------------------------//
    //       Initialization Routines        //
    //--------------------------------------//

    my.FilterAndSearchInit = function() {
        my.removeSilkScreen();
        $("#silkscreen").unbind('click').click(function() { // reenabled because slikscreen clicking is disabled when doing the filter "loading" panel
    	   my.removeSilkScreen(); 
	    });
    
    	//Show and Hide Descriptions
    	$('.feature .label a, .catlabel a, .desc .deleteX').live('click', function(){
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
    	$('#search').unbind('keydown').keydown(function (e) {
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
                    my.loading_indicator_state.sidebar = true;
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


    	// Remove a brand -- submit
    	$('.removefilter').unbind('click').click(function(){
    		var whichRemoved = $(this).attr('data-id');
    		var whichCat = $(this).attr('data-cat');
    		$('#myfilter_'+whichCat).val(opt_removeStringWithToken($('#myfilter_'+whichCat).val(), whichRemoved, '*'));
    		var info = {'chosen_categorical' : whichRemoved, 'slider_name' : whichCat, 'filter_type' : 'categorical_removed'};
    		my.loading_indicator_state.sidebar = true;
        	my.trackPage('goals/filter/categorical_removed', info);
    		submitCategorical();
    		return false;
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

    my.LiveInit = function() { // This stuff only needs to be called once per full page load. 
    	// From Compare
    	//Remove buttons on compare
    	$('.remove').live('click', function(){
    		removeFromComparison($(this).attr('data-name'));
    		$(this).parents('.column').remove();
		
    		// If this is the last one, take the comparison screen down too
    		if ($('#comparisonmatrix .column').length == 1) {
    			my.removeSilkScreen();
    		}
    		return false;
    	});
    	
    	 $('.saveditem .deleteX').live('click', function() {
    	     removeFromComparison($(this).attr('data-name'));
    	     return false;
	     });
    	
    	// from DBInit
    	if (DIRECT_LAYOUT) { // in Optemo Direct, a click anywhere on the product box goes to the show page
            $('.nbsingle').live("click", function(){ 
         		currentelementid = $(this).find('.productinfo').attr('data-id');
         		ignored_ids = getAllShownProductIds();
         		product_title = $(this).find('img.productimg').attr('title');
        		my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids});
         		showpage(currentelementid);
         		return false;
        	});
        	// In addition, set up the images on the "show groups" page to be clickable.
        	$(".productimg").live("click", function (){
                currentelementid = $(this).attr('data-id');
                if(currentelementid === undefined) { currentelementid = $(this).find('.productimg').attr('data-id'); }
        		ignored_ids = getAllShownProductIds();
         		product_title = $(this).find('img.productimg').attr('title');
        		my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids});
         		showpage(currentelementid);
         		return false;            
            });
        } else { // in Optemo Assist, a click only on the picture or .easylink product name will trigger the show page
            $(".productimg, .easylink").live("click", function (){
                currentelementid = $(this).attr('data-id');
        		ignored_ids = getAllShownProductIds();
         		product_title = $(this).find('img.productimg').attr('title');
        		my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids});
         		showpage(currentelementid);
         		return false;            
            });  
        }
        
        //Ajax call for simlinks
    	$('.simlinks').live("click", function() {
    	    my.loading_indicator_state.main = true;
    		my.ajaxcall($(this).attr('href')+'?ajax=true');
    		ignored_ids = getAllShownProductIds(); 
    		my.trackPage('goals/browse_similar', {'filter_type' : 'browse_similar', 'product_picked' : $(this).attr('data-id') , 'product_ignored' : ignored_ids, 'picked_cluster_layer' : $(this).attr('data-layer'), 'picked_cluster_size' : $(this).attr('data-size')});
    		return false;
    	});

    	//Pagination links
        // This convoluted line takes the second-last element in the list: "<< prev 1 2 3 4 next >>" and takes its numerical page value. 
    	total_pages = parseInt($('.pagination').children().last().prev().html());
    	$('.pagination a').live("click", function(){
    		url = $(this).attr('href')
    		if (url.match(/\?/))
    			url +='&ajax=true'
    		else
    			url +='?ajax=true'
    		if ($(this).hasClass('next_page'))
        		my.trackPage('goals/next', {'filter_type' : 'next' , 'page_number' : parseInt($('.pagination .current').html()), 'total_number_of_pages' : total_pages});
    		else
    		    my.trackPage('goals/next', {'filter_type' : 'next_number' , 'page_number' : parseInt($(this).html()), 'total_number_of_pages' : total_pages});		
		    my.loading_indicator_state.main = true;
    		my.ajaxcall(url);
    		return false;
    	});
    	// Survey
    	$('#surveysubmit').live('click', function(){
    		my.trackPage('survey/submit');
    		$('#feedback').css('display','none');
    		my.applySilkScreen('/survey/submit?' + $("#surveyform").serialize(), null, 300, 70);
    		return false;
    	});
    	$('#yesdecisionsubmit').live('click', function(){
    		my.trackPage('survey/yes');
    		my.applySilkScreen('/survey/index', null, 600, 835);
    		return false;
    	});
    	$('#nodecisionsubmit').live('click', function(){
    		my.removeSilkScreen();
    		my.trackPage('survey/no');
    		return false;
    	});
    	// Add to cart buy link
    	$('.buylink, .buyimg').live("click", function(){
    		var buyme_id = $(this).attr('product');
    		my.trackPage('goals/addtocart', {'picked_product' : buyme_id});
    	});
    	
    	// From FilterAndSearchInit
    	// Add a brand -- submit
    	$('.selectboxfilter').live('change', function(){
		    var whichThingSelected = $(this).val();
			var whichSelector = $(this).attr('name');
		    var categorical_filter_name = whichSelector.substring(whichSelector.indexOf("[")+1, whichSelector.indexOf("]"));
    		$('#myfilter_'+categorical_filter_name).val(opt_appendStringWithToken($('#myfilter_'+categorical_filter_name).val(), whichThingSelected, '*'));
    		var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : categorical_filter_name, 'filter_type' : 'categorical'};
    		my.loading_indicator_state.sidebar = true;
        	my.trackPage('goals/filter/categorical', info);
    		submitCategorical();
    		return false;
    	});
	
        // Choose a grouping via group button rather than drop-down (effect is the same as the select boxes)
    	$('.title').live('click', function(){
    		if ($(this).find('.choose_group').length) { // This is a categorical feature
        	    group_element = $(this).find('.choose_group');
            	var whichThingSelected = group_element.attr('data-min');
            	var categorical_filter_name = group_element.attr('data-grouping');
            	if($('#myfilter_'+categorical_filter_name).val().match(whichThingSelected) === null)
                	$('#myfilter_'+categorical_filter_name).val(opt_appendStringWithToken($('#myfilter_'+categorical_filter_name).val(), whichThingSelected, '*'));
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

    	//Show Additional Features
    	$('#morefilters').live('click', function(){
    		$('.extra').show("slide",{direction: "up"},100);
    		$(this).css('display','none');
    		$('#lessfilters').css('display','block');
    		return false;
    	});

    	$('#removeSearch').live('click', function(){
    		$('#previous_search_word').val('');
    		$('#previous_search_container').remove();
        	return false;
     	});
	
    	//Hide Additional Features
    	$('#lessfilters').live('click', function(){
    		$('.extra').hide("slide",{direction: "up"},100);
    		$(this).css('display','none');
    		$('#morefilters').css('display','block');
    		return false;
    	});
	
    	// Sliders -- submit
    	$('.autosubmit').live('change', function() {
    	    my.trackPage('goals/filter/autosubmit', {'filter_type' : 'autosubmit'});
    		submitCategorical();
    	});
	
    	// Checkboxes -- submit
    	$('.binary_filter').live('click', function() {
    		var whichbox = $(this).attr('id');
    		var box_value = $(this).attr('checked') ? 100 : 0;
    		my.loading_indicator_state.sidebar = true;
    		my.trackPage('goals/filter/checkbox', {'feature_name' : whichbox});
    		submitCategorical();
    	});
    	
    	$(".close").live('click', function(){
    		my.removeSilkScreen();
    		return false;
    	});
    }

    function ErrorInit() {
        //Link from popup (used for error messages)
        $('#outsidecontainer').unbind('click').click(function(){
        	my.removeSilkScreen();
        	return false;
        });
    };

    my.DBinit = function() {
    	showpage = (function(currentelementid) {
            my.applySilkScreen('/compare/show/'+currentelementid+'?plain=true',null, 800, 800);
     		// There is tracking being done below, so take this out probably
    // 		trackPage('products/show/'+currentelementid); 
        });
    	if (my.IS_DRAG_DROP_ENABLED)
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

    	//Autocomplete for searchterms
    	model = MODEL_NAME.toLowerCase();
    	// Now, evaluate the string to get the actual array, defined in autocomplete_terms.js and auto-built by the rake task autocomplete:fetch
    	if (typeof(model + "_searchterms") != undefined) { // It could happen for one reason or another. This way, it doesn't break the rest of the script
    	    terms = eval(model + "_searchterms"); // terms now = ["waterproof", "digital", ... ]
        	$("#search").autocomplete({
        	    source: terms
        	});
    	}
    	$('.selectboxfilter').removeAttr("disabled");
    	$('.binary_filter').removeAttr('disabled');
        
    	// In simple view, select an aspect to create viewable groups
    	$('.groupby').unbind('click').click(function(){
			feat = $(this).attr('data-feat');
			my.loading_indicator_state.sidebar = true;
    		my.trackPage('goals/showgroups', {'filter_type' : 'groupby', 'feature_name': feat, 'ui_position': $(this).attr('data-position')});
			my.ajaxcall("/compare/groupby/?feat="+feat);
    	});
    };

    //--------------------------------------//
    //                AJAX                  //
    //--------------------------------------//

    myspinner = new spinner("myspinner", 11, 20, 9, 5, "#000");
    my.loading_indicator_state = {sidebar : false, sidebar_timer : null, main : false, main_timer : null};
    
    /* Does a relatively generic ajax call and returns data to the handler below */
    my.ajaxsend = function (hash,myurl,mydata,hidespinner) {
        var lis = my.loading_indicator_state;
        if (lis.main) lis.main_timer = setTimeout("myspinner.begin()", 1000);
        if (lis.sidebar) lis.sidebar_timer = setTimeout("optemo_module.disableFiltersAndGroups()", 1000);
    	if (myurl != null) {
        	$.ajax({
        		type: (mydata==null)?"GET":"POST",
        		data: (mydata==null)?"":mydata,
        		url: myurl,
        		success: ajaxhandler,
        		error: ajaxerror
        	});
    	} else if (typeof(hash) != "undefined" && hash != null) {
    		$.ajax({
    			type: "GET",
    			url: "/compare/compare/?ajax=true&hist="+hash,
    			success: ajaxhandler,
    			error: ajaxerror
    		});
    	}
    };

    /* The ajax handler takes data from the ajax call and processes it according to some (unknown) rules. */
    function ajaxhandler(data) {
        var lis = my.loading_indicator_state;
        lis.main = lis.sidebar = false;
        clearTimeout(lis.sidebar_timer); // clearTimeout can run on "null" without error
        clearTimeout(lis.main_timer);
        lis.sidebar_timer = lis.main_timer = null;
            
    	if (data.indexOf('[ERR]') != -1) {	
    		var parts = data.split('[BRK]');
    		if (parts[1] != null) {
    			$('#ajaxfilter').html(parts[1]);
    		}
    		flashError(parts[0].substr(5,parts[0].length));
    		optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
    		return -1;
    	} else {
    		var parts = data.split('[BRK]');
    		$('#ajaxfilter').html(parts[0]);
    		$('#main').html(parts[1]);
    		$('#search').attr('value',parts[2]);
    		myspinner.end();
    		optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
    		return 0;
    	}
    }

    function ajaxerror() {
    	//if (language=="fr")
    	//	flashError('<div class="poptitle">&nbsp;</div><p class="error">Désolé! Une erreur s’est produite sur le serveur.</p><p>Vous pouvez <a href="" class="popuplink">réinitialiser</a> l’outil et constater si le problème persiste.</p>');
    	//else
    	flashError('<div class="poptitle">&nbsp;</div><p class="error">Sorry! An error has occured on the server.</p><p>You can <a href="/compare/">reset</a> the tool and see if the problem is resolved.</p>');
    	my.trackPage('goals/error');
    }

    my.ajaxcall = function(myurl,mydata) {
        // Disable interface elements.
        $('.slider').each(function() {
            $(this).slider("option", "disabled", true);
        });
        
        $('.selectboxfilter').attr("disabled", true);
        $('.groupby').unbind('click');
        $('.removefilter').unbind('click').click(function() {return false;}); // There is a default link there that shouldn't be followed.
        $('.binary_filter').attr('disabled', true);
        $('#search').unbind('keydown');
        $('#submit_button').unbind('click');
        
    	numactions = parseInt($("#actioncount").html()) + 1;
    	$.history.load(numactions.toString(),myurl,mydata);
    };

    /* Puts an ajax-related error message in a specific part of the screen */
    function flashError(str) {
    	var errtype = 'other';
	
    	if (/search/.test(str)==true) {
    	  errtype = "search";
    	  $('#search').attr('value',"");
    	}
    	else { 
    	    if (/filter/.test(str)==true) errtype = "filters";
	  	}
    	my.trackPage('goals/error', {'filter_type' : 'error - ' + errtype});
    	myspinner.end();
    	my.applySilkScreen(null,str,600,100);
    	ErrorInit();
    }

    //--------------------------------------//
    //               Layout                 //
    //--------------------------------------//

    // Takes an array of div IDs and removes either inline styles or a named class style from all of them.
    my.clearStyles = function(nameArray, styleclassname) {
    	if (nameArray.constructor == Array) {
    		if (styleclassname != '') { // We have a style name, so remove it from each div id that was passed in
    			for (i in nameArray) { // iterate over all elements of array
    				if ($('#' + nameArray[i]).length) { // the element exists
    					$("#" + nameArray[i]).removeClass(styleclassname);
    				}
    			}
    		} else { // No style name. Take out inline styles.
    			for (i in nameArray) { // iterate over all elements of array
    				if ($('#' + nameArray[i]).length) { // the element exists
    					$("#" + nameArray[i]).removeAttr('style');
    				}
    			}
    		}
    	} else if (nameArray != '') { // there could be a single string passed also
    		if ($('#' + nameArray).length) { // the element exists
    			if (styleclassname != '') { // There is a style name for a single element.
    				$('#' + nameArray).removeClass(styleclassname);
                } else {// Remove the inline styling by default
    				$('#' + nameArray).removeAttr('style');
    			}
    		}
    		// If the element doesn't exist, don't try to access it via jquery, just do nothing.
    	}
    	else { } // There is no array or string passed. Do nothing.
    };

    //--------------------------------------//
    //                Data                  //
    //--------------------------------------//

    /* This gets the currently displayed product ids client-side from the text beneath the product images. */
    function getAllShownProductIds() {
    	var currentIds = [];
    	$('#main .easylink').each(function() {
    		currentIds.push($(this).attr('data-id'));
    	});
    	if (currentIds == '') { // This is for Direct view
            $('#main .productinfo').each(function() {
                currentIds.push($(this).attr('data-id'));
            });
        }
    	return currentIds.join(",");
    }

    my.getShortProductName = function(name) {
    	// This is the corresponding Ruby function.
    	// I modified it slightly, since word breaks are a bit too arbitrary.
    	// [brand.gsub("Hewlett-Packard","HP"),model.split(' ')[0]].join(' ')
    	name = name.replace("Hewlett-Packard", "HP");
    	var shortname = name.substring(0,16);
    	if (name != shortname)
    		return shortname + "...";
    	else
    		return shortname;
    };
    
    //--------------------------------------//
    //              Spinner                 //
    //--------------------------------------//

    /* This sets up a spinning wheel, typically used for sections of the webpage that are loading */
    function spinner(holderid, R1, R2, count, stroke_width, colour) {
    	var sectorsCount = count || 12,
    	    color = colour || "#fff",
    	    width = stroke_width || 15,
    	    r1 = Math.min(R1, R2) || 35,
    	    r2 = Math.max(R1, R2) || 60,
    	    cx = r2 + width,
    	    cy = r2 + width,
    	    r = Raphael(holderid, r2 * 2 + width * 2, r2 * 2 + width * 2),
    
    	    sectors = [],
    	    opacity = [],
    	    beta = 2 * Math.PI / sectorsCount,

    	    pathParams = {stroke: color, "stroke-width": width, "stroke-linecap": "round"};
        Raphael.getColor.reset();
    	for (var i = 0; i < sectorsCount; i++) {
    	    var alpha = beta * i - Math.PI / 2,
    	        cos = Math.cos(alpha),
    	        sin = Math.sin(alpha);
    	    opacity[i] = 1 / sectorsCount * i;
    	    sectors[i] = r.path(pathParams)
    	                    .moveTo(cx + r1 * cos, cy + r1 * sin)
    	                    .lineTo(cx + r2 * cos, cy + r2 * sin);
    	    if (color == "rainbow") {
    	        sectors[i].attr("stroke", Raphael.getColor());
    	    }
    	}
    	this.runspinner = false;
    	this.begin = function() {
    		this.runspinner = true;
    		setTimeout(ticker, 1000 / sectorsCount);
    		$('#loading').css('display', 'inline');
    	};
    	this.end = function() {
    		this.runspinner = false;
    		$('#loading').css('display', 'none');
    	};
    	function ticker() {
    	    opacity.unshift(opacity.pop());
    	    for (var i = 0; i < sectorsCount; i++) {
    	        sectors[i].attr("opacity", opacity[i]);
    	    }
    	    r.safari();
    		if (myspinner.runspinner) // This might be my.runspinner?
    	    	setTimeout(ticker, 1000 / sectorsCount);
    	};
    }

    //--------------------------------------//
    //              Cookies                 //
    //--------------------------------------//

    function addValueToCookie(name, value) {
    	var savedData = readCookie(name), numDays = 30;
    	if (savedData) {
    		// Cookie exists, add additional values with * as the token.
    		savedData = opt_appendStringWithToken(savedData, value, '*');
    		createCookie(name, savedData, numDays);
    	} else {
    		// Cookie does not exist, so just create with the bare value
    		createCookie(name, value, numDays);
    	}
    }

    function removeValueFromCookie(name, value) {
    	var savedData = readCookie(name), numDays = 30;
    	if (savedData) {
    		savedData = opt_removeStringWithToken(savedData, value, '*')
    		if (savedData == "") { // No values left to store 
    			eraseCookie(name);
    		} else {
    			createCookie(name, savedData, numDays);	
    		}
    	}
    	// else do nothing
    }
    
    // This should return all cookie values in an array.
    my.readAllCookieValues = function(name) {
    	// Must error check for empty cookie
    	return (readCookie(name) ? readCookie(name).split('*') : 0);
    };

    function createCookie(name,value,days) {  
        if (days) {  
            var date = new Date();  
            date.setTime(date.getTime()+(days*24*60*60*1000));  
            var expires = "; expires="+date.toGMTString();  
        }  
        else var expires = "";  
        document.cookie = name+"="+value+expires+"; path=/";  
    }  
  
    function readCookie(name) {  
        var nameEQ = name + "=";  
        var ca = document.cookie.split(';');  
        for(var i=0;i < ca.length;i++) {  
            var c = ca[i];  
            while (c.charAt(0)==' ') c = c.substring(1,c.length);  
            if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);  
        }  
        return null;  
    }  
  
    function eraseCookie(name) {  
        createCookie(name,"",-1);  
    }

    return my;
})({});


//--------------------------------------//
//          document.ready()            //
//--------------------------------------//

jQuery.noConflict();
jQuery(document).ready(function($){
    $.history.init(optemo_module.ajaxsend);
    trackPage = optemo_module.trackPage;
    var tokenizedArrayID = 0, savedproducts = null; /* Must initialize savedproducts here for IE */
    savedproducts = optemo_module.readAllCookieValues('savedProductIDs');
	if (savedproducts)
	{
		// There are saved products to display
		if ($.browser.msie) {
			fixedheight = ((savedproducts.length > 2) ? 80 : 160) + 'px';
			$("#opt_savedproducts").css({"height" : fixedheight});
		}
		for (tokenizedArrayID = 0; tokenizedArrayID < savedproducts.length; tokenizedArrayID++)
		{	
			tokenizedArray = savedproducts[tokenizedArrayID].split(',');
			// In future, tokenizedArray[3] contains the product type. As of Feb 2010, each website has separate cookies, so it's not necessary to read this data.
			optemo_module.renderComparisonProducts(tokenizedArray[0], tokenizedArray[1], tokenizedArray[2]);
		}
		// There should be at least 1 saved item, so...
		// 1. show compare button	
		$("#compare_button").css("display", "block");
		// 2. hide 'add stuff here' message
		$("#deleteme").css("display", "none");
	}
	
	// Only load DBinit if it will not be loaded by the upcoming ajax call
	// Do LiveInit anyway, since timing is not important
	optemo_module.LiveInit();
	if ($('#opt_discovery').length == 0) {
		// Other init routines get run when they are needed.
		optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
	}
	//Find product language - Not used at the moment ZAT 2010-03
//	language = (/^\s*English/.test($(".languageoptions:first").html())==true)?'en':'fr';

	//Decrypt encrypted links
	$('a.decrypt').each(function () {
		$(this).attr('href',$(this).attr('href').replace(/[a-zA-Z]/g, function(c){
			return String.fromCharCode((c<="Z"?90:122)>=(c=c.charCodeAt(0)+13)?c:c-26);
			}));
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
		optemo_module.loading_indicator_state.sidebar = true;
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
	
/*	// On escape press. Probably not needed anymore.
	$(document).keydown(function(e){
		if(e.keyCode==27){
			$(".popupTour").fadeOut("slow");
			optemo_module.clearStyles(["sim0", "filterbar", "savebar"], 'tourDrawAttention');
			if ($.browser.msie && $.browser.version == "7.0") $("#sim0").parent().removeClass('tourDrawAttention');
    		trackPage('goals/tourclose');
		}
	});
*/
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

// This should be able to go ahead before document.ready for a slight time savings. NB: Cannot use "$" because of jQuery.noConflict()
if (jQuery('#opt_discovery').length) {
    if (location.hash) {
    	optemo_module.ajaxsend(location.hash.replace(/^#/, ''),'/?ajax=true',null);
	} else {
		optemo_module.ajaxsend(null,'/?ajax=true',null);
	}
}
});

// Load jQuery if it's not already loaded.
// The purpose of using a try/catch loop is to avoid Internet Explorer 8 from crashing when assigning an undefined variable.
try {
    var jqueryIsLoaded = jQuery;
    jQueryIsLoaded = true;
}
catch(err) {
    var jQueryIsLoaded = false;
}

if(jQueryIsLoaded) {
    optemo_module_activator(jQuery);
} else { // Load jquery first
    LazyLoad.js('http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js', (function(){ optemo_module_activator(jQuery) }));
}
