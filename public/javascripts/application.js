/* Application-specific Javascript.
   This is for the grid & list views (Optemo Assist & Optemo Direct) only.
   If you add a function and don't add it to the table of contents, prepare to be punished by your god of choice.
   Functions marked ** are public functions that can be called from outside the optemo_module declaration.

   ---- Show Page Pre-loader & Helpers ----
    parse_bb_json(fn)  -  recursive function to parse the returned JSON into a reasonable object
    resize_silkscreen  -  called internally to put a silkscreen where appropriate
    ** preloadSpecsAndReviews(sku)  -  Does 2 AJAX requests for data relating to sku and puts the results in $('body').data() for instant retrieval later

   ---- UI Manipulation ----
    ** removeSilkScreen()
    ** applySilkScreen(url, data, width, height)  -  Puts up fading boxes
    ** saveProductForComparison(id, sku, imgurl, name)  -  Puts comparison items in #savebar_content and stores them in a cookie. SKU is optional.
    ** renderComparisonProducts(id, sku, imgurl, name)  -  Does actual insertion of UI elements
    ** getIdAndSkuFromProductimg(img)  -  Returns the ID from the image. Only used for drag-and-drop at the moment.
    removeFromComparison(id)  -  Removes comparison items from #savebar_content
    removeBrand(str)   -  Removes brand filter (or other categorical filter)
    submitCategorical()  -  Submits a categorical filter (no longer does tracking)
    submitsearch()  -  Submits a search via the main search field in the filter bar
    histogram(element, norange)  -  draws histogram
    ** disableInterfaceElements()  -  Disables filters, so that the UI is only fielding one request at a time.
    ** loadFilterBarSilkScreen()  -  Puts fade over filter bar (for longer loading times).

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
    ** ajaxsend(hash,myurl,mydata,timeoutlength)  -  Does AJAX call through jquery, returns through ajaxhandler(data)
    ** ajaxhandler(data)  -  Splits up data from the ajax call according to [BRK] tokens. See app/views/compare/ajax.html.erb
    ** ajaxerror() - Displays error message if the ajax send call fails
    ** ajaxcall(myurl,mydata) - adds a hash with the number of searches to the history path
    ** quickajaxcall(element_name, myurl, fn)  -  This ajax request is slim compared to ajaxcall; just load some plain data into an element.
    ** flashError(str)  -  Puts an error message on a specific part of the screen

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
    if (embedded)  -  If we are in embedded view, some functions have to be changed. For more on this see the document in the Optemo wiki.
    if ($('#opt_discovery')) statement  -  This gets evaluated as soon as the ajaxsend function is ready (slight savings over document.ready()).
    if (jQuery)  -  Bootstrap jquery if it's not available. In embedded view, we might or might not have jquery loaded already.
*/

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
    my.MODEL_NAME = $("#modelname").html();
    var VERSION = $("#version").html();
    my.DIRECT_LAYOUT = ($('#directLayout').html() == "true");
    var SESSION_ID = parseInt($('#seshid').html());
    var AB_TESTING_TYPE = parseInt($('#ab_testing_type').html());

    //--------------------------------------//
    //    Show Page Pre-loader & Helpers    //
    //--------------------------------------//

    var parse_bb_json = (function spec_recurse(p) {
        var props = "";
        for (var i in p) {
            if (p[i] == "") continue;
            if (typeof(p[i]) == "object") props += "<li>" + i + ": <ul>" + spec_recurse(p[i]) + "</ul>";
            else props += "<li>" + i + ": " + p[i] + "\n";
        }
        return props;
    });

    var resize_silkscreen = (function () {
        var height = jQuery('#tabbed_content').height() + jQuery('#tabbed_content').offset().top + 40;
        if (height < 760) height = 760;
        jQuery('#silkscreen').css('height', height);
        jQuery('#outsidecontainer').css('height', '');
    });
    
    // This is temporary and should be refactored as soon as convenient. The hard-coded "25" is probably
    // because we are measuring the wrong thing. There are floating elements which confuse proper measurement.
    my.resize_silkscreen_for_compare = (function () {
        var height = jQuery('#info').height() + jQuery('#info').offset().top + 25;
        if (height < 760) height = 760;
        jQuery('#silkscreen').css('height', height);
        jQuery('#outsidecontainer').css('height', '');           
    });

    // The spec loader works to do a couple AJAX calls when the show page initially loads.
    // The results are stored in $('body').data for instant retrieval when the 
    // specs, reviews, or product info buttons are clicked.
    my.loadspecs = function (sku) {
        // The jQuery AJAX request will add ?callback=? as appropriate. Best Buy API v.2 supports this.
        var baseurl = "http://www.bestbuy.ca/api/v2/json/product/" + sku;
        if (!(jQuery('body').data('bestbuy_specs_' + sku))) {
            $.ajax({
                url: baseurl,
                type: "GET",
                dataType: "jsonp",
                success: function (data) {
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
                    jQuery('body').data('bestbuy_specs_' + sku, processed_specs);
                }
            });
        }        
    };

    my.preloadSpecsAndReviews = function(sku) {
        my.loadspecs(sku);
        if (!(jQuery('body').data('bestbuy_reviews_' + sku))) {
            baseurl = "http://www.bestbuy.ca/api/v2/json/reviews/" + sku;
            $.ajax({
                url: baseurl,
    	        type: "GET",
    	        dataType: "jsonp",
                success: function (reviews) {
                    var prop_list = parse_bb_json(reviews["reviews"]);

                    var to_tabbed_content = "";
                    var attributes = reviews["customerRatingAttributes"];
                    // This next section deals specifically with the styling of the rating bars.
                    // They are hard-coded because the inside yellow section grows pixel by pixel to match
                    // the rating, so there needs to be a mathematical relationship between a rating 2.47 and
                    // the number of pixels of yellow to draw. That relationship right now is:
                    // 1
                    var width = parseInt(18 + 41 * reviews["customerRating"]);
                    if (width < 29) width = 29;
                    if (width >= 182) width = 198;
                    to_tabbed_content += "<span style=\"font-weight: bold; font-size: 1.1em;\">Overall Rating:</span> " + "<div class=\"bestbuy_rating_bar\" style=\"width: "+ width +"px;\">" + reviews["customerRating"] + "<div class=\"bestbuy_rating_bar_inside\"></div></div><br>";
                    for (var i in attributes) {
                        // This math is based on the width of the box, see bestbuy_rating_bar_small in CSS declarations
                        var width = parseInt(9 + 20 * (attributes[i] - 0.8));
                        if (width < 14) width = 14;
                        if (width >= 91) width = 99;
                        to_tabbed_content += i.replace(/_x0020_/g, " ") + "<div class=\"bestbuy_rating_bar_small\" style=\"width: "+ width +"px;\"><div class=\"bestbuy_rating_bar_inside_small\">" + attributes[i] + "</div></div>"
                    }
                    to_tabbed_content += 'Review Count: '+ reviews['customerRatingCount'] + "<br><ul>" + prop_list + '</ul>';
                    $('body').data('bestbuy_reviews_' + sku, to_tabbed_content);
                },
                error: function(x, xhr) {
                    console.log("Error in json ajax");
                    console.log(x);
                    console.log(xhr);
                }
            });
	    }
    }

    //--------------------------------------//
    //           UI Manipulation            //
    //--------------------------------------//

    my.removeSilkScreen = function() {
        $('.selectboxfilter').css('visibility', 'visible');
        $('.selectboxfilter').removeAttr('disabled');
        $('#silkscreen').css({'display' : 'none', 'top' : '', 'left' : '', 'width' : ''}).hide();
        $('#outsidecontainer').css({'display' : 'none'});
        $('#outsidecontainer').unbind('click');
        $('#filter_bar_loading').css({'display' : 'none'});
    };

    my.applySilkScreen = function(url,data,width,height) {
    	//IE Compatibility
    	var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body, 
    	dsoctop=document.all? iebody.scrollTop : pageYOffset;
    	$('#info').html("").css('height', '566px');
    	$('#inside_of_outsidecontainer').css('height', '566px');
    	$('#outsidecontainer').css({'left' : ((document.body.clientWidth-(width||560))/2)+'px',
    								'top' : (dsoctop+5)+'px',
    								'width' : width||560,
    								'height' : height||770,
    								'display' : 'inline' });

        /* This is used to get the document height for doing layout properly. */
        /*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
        var current_height = (function() {
            var D = document;
            return Math.max(
                Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
                Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
                Math.max(D.body.clientHeight, D.documentElement.clientHeight)
            );
        })();
        
        // reenabled because slikscreen clicking is disabled when doing the filter "loading" panel
    	$("#silkscreen").unbind('click').click(function() { 
    	   my.removeSilkScreen();
	    });
    	$('#silkscreen').css({'height' : current_height+'px', 'display' : 'inline'});    	
    	$('.selectboxfilter').css('visibility', 'hidden');
    	if (data) {
    		$('#info').html(data)
    		$('#info').css('height','');
    	} else {
    	    my.quickajaxcall('#info', url, function(){
    	        if (url.match(/\/product/)) {
                    // Initialize Galleria
                    jQuery('#galleria').galleria();
                    // The livequery function is used so that this function fires on DOM element creation. jQuery live() doesn't support this as far as I can tell.
                    $('.galleria-thumbnails-list').livequery(function() {
                        var g = $('#galleria').find('.galleria-thumbnails-list');
                        g.children().css('float', 'left');
                        g.append($('#bestbuy_sibling_images').css({'display':'', 'float':'right'}));
                    });
                    
                    if (!($.browser.msie && $.browser.version == "7.0")) {
                        // This is an unsightly hack, and unfortunately seems to be the only easy way to make it work.
                        $('#tab_header li a').hover(function() {
                            if (!($(this).parent().attr('id') == 'tab_selected')) {
                                $(this).css('background', '#ddf');
                            }
                        }, function() {
                            if (!($(this).parent().attr('id') == 'tab_selected')) {
                                $(this).css('background', '#ddd');
                            }
                        });
                    }
        	        my.DBinit();
        	        my.preloadSpecsAndReviews(jQuery('#tab_header').find('ul').attr('data-sku'));
    	        } else {
    	            my.DBinit();
    	            $('#outsidecontainer').css('width','');
                }
    	        $('#outsidecontainer').css('height', ''); // Take height off - it was useful for loading so that we'd see a box, but now the element can auto-size
    	        $('#inside_of_outsidecontainer').css('height', '');
                $('#info').css('height', '');
            });
        }
    };

    // When products get dropped into the save box
    my.saveProductForComparison = function(id, sku, imgurl, name) {
    	/* We need to store the entire thing for Flooring. Eventually this will probably not be an issue
    	since we won't be pulling images directly from another website. Keep original code below
    	imgurlToSaveArray = imgurl.split('/');

    	imgurlToSaveArray[imgurlToSaveArray.length - 1] = id + "_s.jpg";
    	productType = imgurlToSaveArray[(imgurlToSaveArray.length - 2)];
    	productType = productType.substring(0, productType.length-1);
    	imgurlToSave = imgurlToSaveArray.join("/");
    */
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

        		my.renderComparisonProducts(id, sku, imgurl, name);
        		addValueToCookie('optemo_SavedProductIDs', [id, sku, imgurl, name, my.MODEL_NAME]);
        		// Hide the drag-and-drop message
        		$('#savesome').hide();
        	}

        	// There should be at least 1 saved item, so...
        	// 1. show compare button
        	$("#compare_button").css("display", "block");
    	}
    };

    my.renderComparisonProducts = function(id, sku, imgurl, name) {
    	// Create an empty slot for product
    	$('#opt_savedproducts').append("<div class='saveditem' id='c" + id + "' data-sku='"+sku+"'> </div>");

    	// The best is to just leave the medium URL in place, because that image is already loaded in case of comparison, the common case.
    	// For the uncommon case of page reload, it's fine to load a larger image.
    	smallProductImageAndDetail = "<img class=\"draganddropimage\" src=" + // used to have width=\"45\" height=\"50\" in there, but I think it just works for printers...
    	imgurl + " data-id=\""+id+"\" data-sku=\""+sku+"\" alt=\""+id+"_s\"><div class=\"smalldesc\"";
    	// It looks so much better in Firefox et al, so if there's no MSIE, go ahead with special styling.
    	//if ($.browser.msie) smallProductImageAndDetail = smallProductImageAndDetail + " style=\"position:absolute; bottom:5px;\"";
    	smallProductImageAndDetail = smallProductImageAndDetail + ">" +
    	"<a class=\"easylink\" data-id=\""+id+"\" data-sku=\""+sku+"\" href=\"\">" +
    	((name) ? optemo_module.getShortProductName(name) : 0) +
    	"</a></div>" +
    	"<a class=\"deleteX\" data-name=\""+id+"\" href=\"#\">" +
    	"<img src=\"" +
    	(typeof(REMOTE) != 'undefined' ? REMOTE : "") +
    	"/images/close.png\" alt=\"Close\"/></a>";
    	var element = $('#c'+id);
    	element.append($(smallProductImageAndDetail));
    	var image = element.find('.draganddropimage');
    	image.hide();
    	image.load(function() { // This function runs after the DOM has loaded the image, to avoid race conditions
    	    if (image.height() * 1.12 > image.width()) { // This is because we want 45 height and 50 width, plus a 0.01 fudge factor
    	        image.css('height', '45px');
	        } else { // Limit by width
	            image.css('width', '50px');
            }
            $(this).show();
	    });
    	my.DBinit();

    	$("#already_added_msg").css("display", "none");
    	$("#too_many_saved").css("display", "none");
    	if ($.browser.msie) // If it's IE, clear the height element.
    		$("#opt_savedproducts").css({"height" : ''});
    	$("#opt_savedproducts img").each(function() {
    	    $(this).removeClass("productimg");
        });
    };

	my.getIdAndSkuFromProductimg = function(img) {
        var res, sku=0;
    	if (my.DIRECT_LAYOUT) {
    		res = img.parent().siblings('.itemfeatures').find('.easylink')
    		if (res.length > 0) {
    		    res = res.attr('href').match(/\d+$/);
    	    } else {
    	        res = img.parent().siblings('.groupby_title').find('.easylink').attr('href').match(/\d+$/);
            }
    	} else {
    		var el = img.parent().siblings('.productinfo').children('.easylink');
    		res = el.attr('href').match(/\d+$/);
    		sku = el.attr('data-sku');
    	}
    	return Array(res, sku);
	}

    // When you click the X on a saved product:
    function removeFromComparison(id)
    {
    	$('#c'+id).remove();
    	my.trackPage('goals/remove', {'filter_type' : 'remove_from_comparison', 'product_picked' : id});

    	$("#already_added_msg").css("display", "none");
    	$("#too_many_saved").css("display", "none");

    	removeValueFromCookie('optemo_SavedProductIDs', id);
    	if ($('#opt_savedproducts').children().length == 0)
    	{
    	    $('#savesome').show();
    		$("#compare_button").css("display", "none");
	    }
    	return false;
    }

    function removeBrand(str)
    {
    	$('#myfilter_Xbrand').attr('value', str);
    	my.ajaxcall("/compare?ajax=true", $("#filter_form").serialize());
    }

    function submitCategorical(){
        var arguments_to_send = [];
        arguments = $("#filter_form").serialize().split("&");
        for (i=0; i<arguments.length; i++)
        {
            if (!(arguments[i].match(/^superfluous/)))
                arguments_to_send.push(arguments[i]);
        }
    	my.ajaxcall("/compare?ajax=true", arguments_to_send.join("&"));
    	return false;
    }

    function submitsearch() {
    	my.trackPage('goals/search', {'filter_type' : 'search', 'search_text' : $("#myfilter_search").attr('value'), 'previous_search_text' : $("#previous_search_word").attr('value')});
    	var arguments_to_send = [];
        arguments = $("#filter_form").serialize().split("&");
        for (i=0; i<arguments.length; i++)
        {
            if (!(arguments[i].match(/^superfluous/)))
                arguments_to_send.push(arguments[i]);
        }
        my.loading_indicator_state.sidebar = true;
    	my.ajaxcall("/compare?ajax=true", arguments_to_send.join("&"));
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
    	var peak = 0, trans = 3, length = 170, height = 15, init = 4;
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

    my.disableInterfaceElements = function() {
        // Disable interface elements.
        $('.slider').each(function() {
            $(this).slider("option", "disabled", true);
        });

        $('.selectboxfilter').attr("disabled", true);
        $('.groupby').unbind('click');
        $('.removefilter').unbind('click').click(function() {return false;}); // There is a default link there that shouldn't be followed.
        $('.binary_filter').attr('disabled', true);
        $('#myfilter_search').unbind('keydown');
        $('#submit_button').unbind('click');
    }

    my.loadFilterBarSilkScreen = function() {
        // This will turn on the fade for the left area
        elementToShadow = $('#filterbar');
        var pos = elementToShadow.offset();
        var width = elementToShadow.innerWidth() + 2; // Extra pixels are for the border.
        var height = elementToShadow.innerHeight() + 2;
        $('#silkscreen').css({'position' : 'absolute', 'display' : 'inline', 'left' : pos.left + "px", 'top' : pos.top + 27 + "px", 'height' : height - 27 + "px", 'width' : width + "px"}).fadeTo(0,0.2); // The 27 is arbitrary - equal to the top of the filter bar (title, reset button)
        $("#silkscreen").unbind('click'); // We need this so that the user can't clear the silkscreen by clicking on it.
        $('#filter_bar_loading').css({'display' : 'inline', 'left' : (pos.left + (width-126)/2) + "px", 'top' : pos.top + (height - 46)/2 + "px"});
    };

    //--------------------------------------//
    //       Piwik Tracking Functions       //
    //--------------------------------------//

    my.trackPage = function(page_title, extra_data){
    	try {
    	    if (!extra_data) extra_data = {}; // If this argument didn't get sent, set an empty hash
    		extra_data['optemo_session'] = SESSION_ID;
    		extra_data['version'] = VERSION;
    		extra_data['interface_view'] = (my.DIRECT_LAYOUT ? 'direct' : 'assist');
    		extra_data['ab_testing_type'] = AB_TESTING_TYPE;
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
    				    // Store the fact that it went too far using data()
    				    leftsliderknob.data('toofar', true);
    			    }
    				// Prevent the right slider knob from going too far to the left (past all the current data)
    			    if ((realvalue < datasetmin && sliderno == 1) || ui.values[1] == 0) {
    			        realvalue = datasetmin;
    				    rightsliderknob.css('left', ((datasetmin - rangemin) * 100.1 / (rangemax - rangemin)) + "%"); // was 100.1
    				    rightsliderknob.data('toofar', true);
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
    				var rightslidervalue;

    				if ((ui.values[1] * (rangemax - rangemin) / 100.0) + rangemin < datasetmin) {
    				    rightslidervalue = datasetmin;
    				    $(this).siblings('.max').attr('value', rightslidervalue);
				    }
				    else
                        rightslidervalue = ui.values[1];
    				var diff = rightslidervalue - ui.values[0];
    				if (diff > threshold)
    				{
    					leftsliderknob.removeClass("valabove").addClass("valbelow");
    					rightsliderknob.removeClass("valabove").addClass("valbelow");
    				}
    				var sliderinfo = {'slider_min' : parseFloat(ui.values[0]) * rangemin / 100.0, 'slider_max' : parseFloat(rightslidervalue) * rangemax / 100.0,
                	            'slider_name' : $(this).attr('data-label'), 'filter_type' : 'slider', 'data_min' : datasetmin, 'data_max' : datasetmax, 'ui_position' : $(this).parent().find('.label').attr('data-position')};
    				my.trackPage('goals/filter/slider', sliderinfo);
    				var arguments_to_send = [];
                    arguments = $("#filter_form").serialize().split("&");
                    for (i=0; i<arguments.length; i++)
                    {
                        if (!(arguments[i].match(/^superfluous/)))
                            arguments_to_send.push(arguments[i]);
                    }
                    if (leftsliderknob.data('toofar') || rightsliderknob.data('toofar')) {
                        sliderinfo['filter_type'] = 'forced_stop';
        				my.trackPage('goals/filter/forcedstop', sliderinfo);
    				    leftsliderknob.removeData('toofar');
    				    rightsliderknob.removeData('toofar');
                    }
                    my.loading_indicator_state.sidebar = true;
                	my.ajaxcall("/compare?ajax=true", arguments_to_send.join("&"));
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
		// The livequery function is used so that this function fires on DOM element creation. jQuery live() doesn't support this as far as I can tell.
        $('.galleria-thumbnails-list').livequery(function() {
            var g = $('#galleria').find('.galleria-thumbnails-list');
            g.children().css('float', 'left');
            g.append($('#bestbuy_sibling_images').css({'display':'', 'float':'right'}));
        });

    	//Search submit
    	$('#submit_button').live('click', function(){
    		return submitsearch();
    	});

    	//Search submit
    	$('#myfilter_search').live('keydown', function (e) {
    		if (e.which==13)
    			return submitsearch();
    	});

    	// Add a dropdownbox selection -- submit
    	$('.selectboxfilter').live('change', function(){
		    var whichThingSelected = $(this).val().replace(/ \(.*\)$/,'');
			var whichSelector = $(this).attr('name');
		    var categorical_filter_name = whichSelector.substring(whichSelector.indexOf("[")+1, whichSelector.indexOf("]"));
    		$('#myfilter_'+categorical_filter_name).val(opt_appendStringWithToken($('#myfilter_'+categorical_filter_name).val(), whichThingSelected, '*'));
    		var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : categorical_filter_name, 'filter_type' : 'categorical'};
    		my.loading_indicator_state.sidebar = true;
        	my.trackPage('goals/filter/categorical', info);
    		submitCategorical();
    		return false;
    	});

    	// Change sort method
    	$('#sorting_method').live('change', function() {
    	    var whichSortingMethodSelected = $(this).val();
    	    var info = {'chosen_sorting_method' : whichSortingMethodSelected, 'filter_type' : 'sorting_method'};
			my.trackPage('goals/filter/sorting_method', info);
    	    my.loading_indicator_state.sidebar = true;
            my.ajaxcall("/compare?ajax=true&sortby=" + whichSortingMethodSelected);
	    });

    	//Show and Hide Descriptions
    	$('.label a, .desc .deleteX').live('click', function(){
    		if($(this).parent().attr('class') == "desc")
    			{var obj = $(this).parent();}
    		else
    			{var obj = $(this).siblings('.desc');}
            // I think this is just toggling. Just on the off chance that something weird is happening here, I'll leave this code for now. ZAT 2010-08
            obj.toggle();
            if( obj.is(':visible') ) {
        		my.trackPage('goals/label', {'filter_type' : 'description', 'ui_position' : obj.parent().attr('data-position')});
    		}
    		return false;
    	});

		// Add a color selection -- submit
    	$('.swatch').live('click', function(){
			my.loading_indicator_state.sidebar = true;
		    var whichThingSelected = $(this).attr("style").replace(/background-color: (\w+);?/i,'$1');
		    // Fix up the case issues for Internet Explorer (always pass in color value as "Red")
		    whichThingSelected = whichThingSelected.toLowerCase();
		    whichThingSelected = whichThingSelected.charAt(0).toUpperCase() + whichThingSelected.slice(1);
			if ($(this).hasClass("selected_swatch"))
			{ //Removed selected color
				$('#myfilter_color').val(opt_removeStringWithToken($('#myfilter_color').val(), whichThingSelected, '*'));
	    		var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : 'color', 'filter_type' : 'categorical_removed'};
				my.trackPage('goals/filter/categorical_removed', info);
			}
			else
			{ //Added selected color
    			$('#myfilter_color').val(opt_appendStringWithToken($('#myfilter_color').val(), whichThingSelected, '*'));
    			var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : 'color', 'filter_type' : 'categorical'};
				my.trackPage('goals/filter/categorical', info);
			}
    		submitCategorical();
    		return false;
    	});

    	// Remove a brand -- submit
    	$('.removefilter').live('click', function(){
    		var whichRemoved = $(this).attr('data-id');
    		var whichCat = $(this).attr('data-cat');
    		$('#myfilter_'+whichCat).val(opt_removeStringWithToken($('#myfilter_'+whichCat).val(), whichRemoved, '*'));
    		var info = {'chosen_categorical' : whichRemoved, 'slider_name' : whichCat, 'filter_type' : 'categorical_removed'};
    		my.loading_indicator_state.sidebar = true;
        	my.trackPage('goals/filter/categorical_removed', info);
    		submitCategorical();
    		return false;
    	});

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

        // The next few functions were written to be Best Buy-specific, but they can be extended
        // for any tabbed quickview page. The content is loaded ahead of time by preloadSpecsAndReviews() on popup load.
        function quickview_tasks(el, content) {
            // NB: This is locally scoped to LiveInit only
    	    if (!($.browser.msie && $.browser.version == "7.0")) el.css('background','');
    	    if (!($('body').data('bestbuy_product_info')))
    	        $('body').data('bestbuy_product_info', $('#tabbed_content').html());
            $('#tabbed_content').html(content);
            $('#tab_selected').removeAttr('id');
    	    el.parent().attr('id', 'tab_selected');
            resize_silkscreen();
        }

    	$('.fetch_bestbuy_info').live('click', function() {
    	    var t = $(this);
    	    if (!(t.parent().attr('id') == "tab_selected"))
        	    quickview_tasks(t,$('body').data('bestbuy_product_info'));
	        return false;
	    });

    	$('.fetch_bestbuy_specs').live('click', function () {
    	    // Must send sku in (bestbuy_specs_110742 for example)
    	    var prop_list_node = jQuery('<ul>' + parse_bb_json($('body').data('bestbuy_specs_' + $(this).parent().parent().attr('data-sku'))) + "</ul>");
            quickview_tasks($(this), prop_list_node);
            return false;
	    });
    
	    $('.fetch_bestbuy_reviews').live('click', function () {
    	    // Must send sku in (bestbuy_specs_110742 for example)
            quickview_tasks($(this), $('body').data('bestbuy_reviews_' + $(this).parent().parent().attr('data-sku')));
            return false;
        });

        $('.fetch_compare_specs').live('click', function () {
            var t = $(this);
            var content = [];
            $('#opt_savedproducts').children().each(function() {
    			// it's a saved item if the CSS class is set as such. This allows for other children later if we feel like it.
    			if ($(this).attr('class').indexOf('saveditem') != -1)
    			{
    				var sku = $(this).attr('data-sku');
    				optemo_module.loadspecs(sku);
    				t.parent().before("<br><div class='column' style='width:189px;'>" + "<ul>" + parse_bb_json($('body').data('bestbuy_specs_' + sku)) + "</ul>" + "</div>");
    				t.remove();
    				my.resize_silkscreen_for_compare();
    			}
    		});
            return false;
        });

        $('.saveditem .deleteX').live('click', function() {
         removeFromComparison($(this).attr('data-name'));
         return false;
        });

    	// from DBInit

        $(".productimg, .easylink").live("click", function (){
			var href = $(this).attr('href') || $(this).parent().siblings('.productinfo').children('.easylink').attr('href') || $(this).parent().parent().find('.easylink').attr('href'),
        	ignored_ids = getAllShownProductIds(),
			currentelementid = $(this).attr('data-id') || href.match(/\d+$/),
        	product_title = $(this).find('img.productimg').attr('title');
        	my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids});
			my.applySilkScreen((href || '/product/_/' + currentelementid) +'?plain=true',null, 560, 580);
        	return false;
        });

        //Ajax call for simlinks
    	$('.simlinks').live("click", function() {
    		var ignored_ids = getAllShownProductIds();
    	    my.loading_indicator_state.main = true;
    		my.ajaxcall($(this).attr('href')+'?ajax=true');
    		my.trackPage('goals/browse_similar', {'filter_type' : 'browse_similar', 'product_picked' : $(this).attr('data-id') , 'product_ignored' : ignored_ids, 'picked_cluster_layer' : $(this).attr('data-layer'), 'picked_cluster_size' : $(this).attr('data-size')});
    		return false;
    	});

    	//Pagination links
        // This convoluted line takes the second-last element in the list: "<< prev 1 2 3 4 next >>" and takes its numerical page value.
    	var total_pages = parseInt($('.pagination').children().last().prev().html());
    	$('.pagination a').live("click", function(){
    		var url = $(this).attr('href')
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

    	// Add to cart buy link
    	$('.buylink, .buyimg').live("click", function(){
    		var buyme_id = $(this).attr('product');
    		my.trackPage('goals/addtocart', {'product_picked' : buyme_id, 'filter_type' : 'addtocart'});
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
                my.ajaxcall("/compare?ajax=true", arguments_to_send.join("&"));
        	}
    	});

    	//Show Additional Features
    	$('#morefilters').live('click', function(){
    		$('.extra').show("slide",{direction: "up"},100);
    		$(this).css('display','none');
    		$('#lessfilters').css('display','block');
    		return false;
    	});

    	$('.removesearch').live('click', function(){
    		$('#previous_search_word').val('');
			$("#myfilter_search").val("");
    		$(this).parent().remove();
			submitCategorical();
        	return false;
     	});

    	//Hide Additional Features
    	$('#lessfilters').live('click', function(){
    		$('.extra').hide("slide",{direction: "up"},100);
    		$(this).css('display','none');
    		$('#morefilters').css('display','block');
    		return false;
    	});

    	// Checkboxes -- submit
    	$('.binary_filter').live('click', function() {
    		var whichbox = $(this).attr('id');
    		var box_value = $(this).attr('checked') ? 100 : 0;
    		my.loading_indicator_state.sidebar = true;
    		my.trackPage('goals/filter/checkbox', {'feature_name' : whichbox});
    		submitCategorical();
    	});

    	$(".close, .bb_quickview_close").live('click', function(){
    		my.removeSilkScreen();
    		return false;
    	});

		$(".popup").live('click', function(){
			window.open($(this).attr('href'));
			return false;
		});

		$(".demo_selector select").live('change', function(){
			var url = "http://"+$(".demo_selector select:last").val()+"."+$(".demo_selector select:first").val()+".demo.optemo.com";
			window.location = url;
		});

		$(".swatch").live('click', function(){
			$(this).toggleClass('selected_swatch');
		});
		
		//Reset filters
		$('.reset').live('click', function(){
			trackPage('goals/reset', {'filter_type' : 'reset'});
			optemo_module.loading_indicator_state.sidebar = true;
			optemo_module.ajaxcall($(this).attr('href')+'?ajax=true');
			return false;
		});
    }

    function ErrorInit() {
        //Link from popup (used for error messages)
        $('#silkscreen').css({'display' : 'none', 'top' : '', 'left' : '', 'width' : ''})
        $('#outsidecontainer').unbind('click').click(function(){
        	my.FilterAndSearchInit(); my.DBinit();
        	return false;
        });
    };

    my.DBinit = function() {
        var model = "";
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
    	if (typeof(my.MODEL_NAME) != undefined && my.MODEL_NAME != null) // This check is needed for embedding; different checks for different browsers
    	    model = my.MODEL_NAME.toLowerCase();
    	// Now, evaluate the string to get the actual array, defined in autocomplete_terms.js and auto-built by the rake task autocomplete:fetch
    	if (typeof(model + "_searchterms") != undefined) { // It could happen for one reason or another. This way, it doesn't break the rest of the script
    	    var terms = window[model + "_searchterms"]; // terms now = ["waterproof", "digital", ... ] using square bracket notation
        	$("#myfilter_search").autocomplete({
        	    source: terms
        	});
    	}
    	$('.selectboxfilter').removeAttr("disabled");
    	$('.binary_filter').each(function(){
			if($(this).attr('data-disabled') != 'true') {
				$(this).removeAttr('disabled');
			}
		});

    	// In simple view, select an aspect to create viewable groups
    	$('.groupby').unbind('click').click(function(){
			feat = $(this).attr('data-feat');
			my.loading_indicator_state.sidebar = true;
    		my.trackPage('goals/showgroups', {'filter_type' : 'groupby', 'feature_name': feat, 'ui_position': $(this).attr('data-position')});
			my.ajaxcall("/groupby/"+feat+"?ajax=true");
    	});
    };

    //--------------------------------------//
    //                AJAX                  //
    //--------------------------------------//

    myspinner = new spinner("myspinner", 11, 20, 9, 5, "#000");
    my.loading_indicator_state = {sidebar : false, sidebar_timer : null, main : false, main_timer : null, socket_error_timer : null};

    /* Does a relatively generic ajax call and returns data to the handler below */
    my.ajaxsend = function (hash,myurl,mydata,timeoutlength) {
        var lis = my.loading_indicator_state;
        if (lis.main && !(lis.main_timer)) lis.main_timer = setTimeout("myspinner.begin()", timeoutlength || 1000);
        if (lis.sidebar) lis.sidebar_timer = setTimeout("optemo_module.loadFilterBarSilkScreen()", timeoutlength || 1000);
    	if (myurl != null) {
        	$.ajax({
        		type: (mydata==null)?"GET":"POST",
        		data: (mydata==null)?"":mydata,
        		url: (hash==null)?myurl:myurl+"&hist="+hash,
        		success: my.ajaxhandler,
        		error: my.ajaxerror
        	});
    	} else if (typeof(hash) != "undefined" && hash != null) {
			/* Used by back button */
    		$.ajax({
    			type: "GET",
    			url: "/compare/?ajax=true&hist="+hash,
    			success: my.ajaxhandler,
    			error: my.ajaxerror
    		});
    	}
    };

    /* The ajax handler takes data from the ajax call and processes it according to some (unknown) rules. */
    // This needs to be a public function now
    my.ajaxhandler = function(data) {
        var lis = my.loading_indicator_state;
        lis.main = lis.sidebar = false;
        clearTimeout(lis.sidebar_timer); // clearTimeout can run on "null" without error
        clearTimeout(lis.main_timer);
        clearTimeout(lis.socket_error_timer); // We need to clear the timeout error here
        lis.sidebar_timer = lis.main_timer = lis.socket_error_timer = null;

    	if (data.indexOf('[ERR]') != -1) {
    		var parts = data.split('[BRK]');
    		if (parts[1] != null) {
    			$('#ajaxfilter').html(parts[1]);
    		}
    		optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
    		my.flashError(parts[0].substr(5,parts[0].length));
    		return -1;
    	} else {
    		var parts = data.split('[BRK]');
    		$('#ajaxfilter').html(parts[1]);
    		$('#main').html(parts[0]);
    		$('#myfilter_search').attr('value',parts[2]);
    		myspinner.end();
    		optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
    		return 0;
    	}
    }

    my.ajaxerror = function() {
    	//if (language=="fr")
    	//	my.flashError('<div class="poptitle">&nbsp;</div><p class="error">Désolé! Une erreur s’est produite sur le serveur.</p><p>Vous pouvez <a href="" class="popuplink">réinitialiser</a> l’outil et constater si le problème persiste.</p>');
    	//else
        var lis = my.loading_indicator_state;
        lis.main = lis.sidebar = false;
        clearTimeout(lis.sidebar_timer); // clearTimeout can run on "null" without error
        clearTimeout(lis.main_timer);
        clearTimeout(lis.socket_error_timer); // We need to clear the timeout error here
    	my.flashError('<div class="bb_poptitle">Error<a class="bb_quickview_close" href="close">Close Window</a></div><p class="error">Sorry! An error has occurred on the server.</p><p>You can <a href="/compare/">reset</a> the tool and see if the problem is resolved.</p>');
    	my.trackPage('goals/error');
    }

    my.ajaxcall = function(myurl,mydata) {
        my.disableInterfaceElements();
    	numactions = parseInt($("#actioncount").html()) + 1;
    	$.history.load(numactions.toString(),myurl,mydata);
    };

    my.quickajaxcall = function(element_name, myurl, fn) { // The purpose of this is to do an ajax load without having to go through the relatively heavy ajaxcall().
        $(element_name).load(myurl, fn);
    }

    /* Puts an ajax-related error message in a specific part of the screen */
    my.flashError = function(str) {
    	var errtype = 'other';

    	if (/search/.test(str)==true) {
    	  errtype = "search";
    	  $('#myfilter_search').attr('value',"");
    	}
    	else {
    	    if (/filter/.test(str)==true) errtype = "filters";
	  	}
    	my.trackPage('goals/error', {'filter_type' : 'error - ' + errtype});
    	myspinner.end();
    	ErrorInit();
    	my.applySilkScreen(null,str,600,107);
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
})(optemo_module || {});


//--------------------------------------//
//          document.ready()            //
//--------------------------------------//

jQuery.noConflict();
jQuery(document).ready(function($){
    $.history.init(optemo_module.ajaxsend);
    trackPage = optemo_module.trackPage;
    var tokenizedArrayID = 0, savedproducts = null; /* Must initialize savedproducts here for IE */
    savedproducts = optemo_module.readAllCookieValues('optemo_SavedProductIDs');
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
            // These arguments are (id, sku, imgurl, name, product_type). 
            // We just ignore product type for now since the websites only have one product type each.
			optemo_module.renderComparisonProducts(tokenizedArray[0], tokenizedArray[1], tokenizedArray[2], tokenizedArray[3]);
		}
		// There should be at least 1 saved item, so...
		// 1. show compare button
		$("#compare_button").css("display", "block");
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
				        var id_and_sku = optemo_module.getIdAndSkuFromProductimg(realImgObj);
    					optemo_module.saveProductForComparison(id_and_sku[0], id_and_sku[1], realImgObj.attr('src'), realImgObj.attr('alt'));
				    }
				    else { // This is an image object; behave as normal
				        var id_and_sku = optemo_module.getIdAndSkuFromProductimg(imgObj);
    					optemo_module.saveProductForComparison(id_and_sku[0], id_and_sku[1], imgObj.attr('src'), imgObj.attr('alt'));
					}
				}
			 });
		});
	}

	//Call overlay for product comparison
	$("#compare_button").click(function(){
		var productIDs = '', width = 560, number_of_saved_products = 0;
		// For each saved product, get the ID out of the id=#opt_savedproducts children.
		$('#opt_savedproducts').children().each(function() {
			// it's a saved item if the CSS class is set as such. This allows for other children later if we feel like it.
			if ($(this).attr('class').indexOf('saveditem') != -1)
			{
				// Build a list of product IDs to send to the AJAX call
				var p_id = $(this).attr('id').substring(1);
				var sku = $(this).attr('data-sku');
				productIDs = productIDs + p_id + ',';
				number_of_saved_products++;
				optemo_module.loadspecs(sku)
			}
		});

        // To figure out the width that we need, start with $('#opt_savedproducts').length probably
        // 560 minimum (width is the first of the two parameters)
        // 2, 3, 4 ==>  513, 704, 895  (191 each)
        switch(number_of_saved_products) {
            case 3:
                width = 751;
                break;
            case 4:
                width = 942;
                break;
            default:
                width = 560;
        }
		optemo_module.applySilkScreen('/comparison/' + productIDs, null, width, 580);
		trackPage('goals/compare', {'filter_type' : 'direct_comparison'});
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
	
	// Load the classic theme
    Galleria.loadTheme('/javascripts/galleria.classic.js');
});

if (window.embedding_flag) {
    // On embed, we need to redefine the ajaxcall / ajaxsend duo so that they point at the remote server as appropriate.
    // The data will come back through the same ajaxhandler function as before, getting pushed there by the
    // remote socket when it's ready.
    optemo_module.ajaxcall = function (myurl, mydata) {
        optemo_module.disableInterfaceElements();
    	numactions = parseInt($("#actioncount").html()) + 1;
    	$.history.load(numactions.toString(),myurl,mydata);
	};

	optemo_module.ajaxsend = function(hash,myurl,mydata,timeoutlength) {
        optemo_module.disableInterfaceElements();
        var lis = optemo_module.loading_indicator_state;
        if (lis.main) lis.main_timer = setTimeout("myspinner.begin()", timeoutlength || 1000);
        if (lis.sidebar) lis.sidebar_timer = setTimeout("optemo_module.loadFilterBarSilkScreen()", timeoutlength || 1000);
        lis.socket_error_timer = setTimeout("optemo_module.clearSocketError()", 15000);
        // Hopefully we can just send the arguments as-is. It's probably bad style not to sanity-check them though.
        remote.iframecall(hash, myurl, mydata);
    };
    $.history.init(optemo_module.ajaxsend); // re-init with the new ajaxsend module here, after it's been redefined

    optemo_module.clearSocketError = function() {
        // if ajaxhandler never gets called, here we are.
		optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
    	optemo_module.flashError('<div class="bb_poptitle">Error<a class="bb_quickview_close" href="close"><img src="/images/closepopup_white.gif"></a></div><p class="error">Sorry! An error has occurred on the server.</p><p>You can <a href="/compare/">reset</a> the tool and see if the problem is resolved.</p>');
    }

    optemo_module.quickajaxcall = function (element_name, mydata, fn) { // for the show page
        remote.quickiframecall(element_name, mydata, fn);
    }
}

// This should be able to go ahead before document.ready for a slight time savings.
// NB: Cannot use "$" because of jQuery.noConflict()
// This works for embedded also, because by now the ajaxsend function has been redefined, and the history init has been called.
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
} else {
    var script_element = document.createElement("script");
    script_element.setAttribute("type", "text/javascript");
    if (script_element.readyState){  //IE
        script_element.onreadystatechange = function(){
            if (script_element.readyState == "loaded" ||
                    script_element.readyState == "complete"){
                script_element.onreadystatechange = null;
                optemo_socket_activator(window["jQuery"]); // Using square bracket notation because the jquery object won't be initialized until later
            }
        };
    } else {  //Others
        script_element.onload = function(){
            optemo_socket_activator(window["jQuery"]);
        };
    }
    script_element.setAttribute("src", 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js');
    document.getElementsByTagName("head")[0].appendChild(script_element);
}
