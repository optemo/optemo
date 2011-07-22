/*global defineClass: false, deserialize: false, gc: false, help: false, load: false, loadClass: false, print: false, quit: false, readFile: false, readUrl: false, runCommand: false, seal: false, serialize: false, spawn: false, sync: false, toint32: false, version: false */
/* Application-specific Javascript.
   This is for the grid & list views (Optemo Assist & Optemo Direct) only.
   If you add a function and don't add it to the table of contents, prepare to be punished by your god of choice.
   Functions marked ** are public functions that can be called from outside the optemo_module declaration.

   ---- Show Page Pre-loader & Helpers ----

    parse_bb_json(obj)  -  recursive function to parse the returned JSON into an html list
    ** loadspecs(sku, f)  -  Does 2 AJAX requests for data relating to sku and puts the results in $('body').data() for later. Runs the callback function f if provided.
    numberofstars(stars)  -  Helper function to turn a number of stars into images
    ** preloadSpecsAndReviews  -  Called on show action, this gets the specs and reviews if necessary for instant tab switching on pop-over window

   ---- UI Manipulation ----
    ** removeSilkScreen()
    ** applySilkScreen(url, data, width, height, f)  -  Puts up fading boxes, calling the callback frunction f if provided.
    ** getIdAndSkuFromProductimg(img)  -  Returns the ID from the image. Only used for drag-and-drop at the moment.
    removeFromComparison(id)  -  Removes comparison items from #savebar_content
    submitCategorical()  -  Submits a categorical filter (no longer does tracking)
    submitsearch()  -  Submits a search via the main search field in the filter bar
    histogram(element, norange)  -  draws histogram
    ** disableInterfaceElements()  -  Disables filters, so that the UI is only fielding one request at a time.

   ---- Piwik Tracking Functions ----
    ** trackPage(page_title, extra_data)  -  Piwik tracking per page. Extra data is in JSON format, with keys for ready parsing by Piwik into piwik_log_preferences.
                                       -  For more on this, see the Preferences plugin in the Piwik code base.

   ---- JQuery Initialization Routines ----
    ** SliderInit()  -  Draw slider historgrams
 	** LiveInit()  -   All the events that can be handled appropriately with jquery live
 	row_height(length,isLabel)  -  Helper function for calculating row height, used only in the next function
 	** buildComparisonMatrix()  -  Builds the HTML used in the product direct comparison screen
	ErrorInit()  -  Error pages
    ** DBinit()  -   UI elements from the _discoverybrowser partial, also known as <div id="main">.

    ------- Spinner -------
     spinner(holderid, R1, R2, count, stroke_width, colour)  -  returns a spinner object

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
    getAllShownProductSkus()  -  Returns currently disoplayed product SKUs.
    ** getShortProductName(name)  -  Returns the shorter product name for printers. This should be extended in future.

   -------- Cookies -------
    addValueToCookie(name, value)  -  Add a value to the cookie "name" or create a cookie if none exists.
    removeValueFromCookie(name, value)  -  Remove a value from the cookie, and delete the cookie if it's readAllCookieValues(name)  -  Returns an array of cookie values.
    createCookie(name,value,days)  -  Try not to use this or the two below directly if possible, they are like private methods.
    readCookie(name)  -  Gets raw cookie 'value' data.
    eraseCookie(name)  -  Erases cookie.

   ---- document.ready() ----
    document.ready()  -  Loads saved products from cookie when DOM is complete, does jquery event handler initialization if the layout is not embedded
    
   ---- Embedding-specific code ----
    if (window.embedded)  -  The AJAX functions need to be redefined to go through the socket. For more on this see the document in the Optemo wiki.

   ----- Page Loader -----
    if ($('#opt_discovery')) statement  -  This gets evaluated as soon as the ajaxsend function is ready (slight savings over document.ready()).
    if (jQuery)  -  Bootstrap jquery if it's not available. In embedded view, we might or might not have jquery loaded already.
*/

// These global variables must be declared explicitly for proper scope (the spinner is because setTimeout has its own scope and needs to set the spinner)
var optemo_module;
var optemo_module_activator;
// jquery noconflict taken out for jquery 1.4.2 Best Buy rollout 04-2011
optemo_module_activator = (function() { // See bottom, this is for jquery noconflict
optemo_module = (function (my){
    // Language support - disabled for now
    // var language;

    //--------------------------------------//
    //    Show Page Pre-loader & Helpers    //
    //--------------------------------------//

    // The following variables are pulled from optemo.html.erb
    // They are in a separate function like this so that the embedder can call them at the appropriate time.
    // Note that those that are locally scoped to the optemo_module must be defined before this function call.
    var VERSION, SESSION_ID, AB_TESTING_TYPE, DOM_ALREADY_RUN;
    if (typeof OPT_REMOTE == "undefined") OPT_REMOTE = false;
    my.initializeVariables = function() {
        my.MODEL_NAME = $("#modelname").html();
        VERSION = $("#version").html();
        my.DIRECT_LAYOUT = ($('#directLayout').html() == "true");
        SESSION_ID = parseInt($('#seshid').html());
        AB_TESTING_TYPE = parseInt($('#ab_testing_type').html());
        my.PIWIK_ID = $('#piwikid').html();
        var category_id_hash = {'digital-cameras' : 20218,
                        'digital-tvs' : 21344, // The URL is probably not quite correct yet; this is a placeholder
                        'harddrives' : 20232};

        my.RAILS_CATEGORY_ID = 0;
        for (var i in category_id_hash) {
            if (window.location.pathname.match(new RegExp(i))) {
                my.RAILS_CATEGORY_ID = category_id_hash[i];
                break;
            }
        }
        // Failsafe just in case nothing seems to match
        if (my.RAILS_CATEGORY_ID == 0) my.RAILS_CATEGORY_ID = 20218;
    }

    // Renders a recursive html list of the specs.
    // This is still used for displaying reviews for the time being.
    // (for/in) loop iterates over all properties of the object.
    // This wouldn't work out if for any reason the Object prototype had changed.
    // In that case, use the following (google "for in javascript hasownproperty" for more information):
    // if (p.hasOwnProperty(i)
    var parse_bb_json = (function spec_recurse2(p) {
		var props = "";
		for (var i in p) {
		    if (p[i] == "") continue;
		    if (typeof(p[i]) == "object") props += "<li>" + i + ": <ul>" + spec_recurse2(p[i]) + "</ul></li>";
		    else props += "<li>" + i + ": " + p[i] + "</li>";
		}
		return props;
    });

	my.merge_bb_json = function () {
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

    // The spec loader works to do a couple AJAX calls when the show page initially loads.
    // The results are stored in $('body').data for instant retrieval when the
    // specs, reviews, or product info buttons are clicked.
    
    // Consider refactoring this code to solve the race condition:
    //   - get the loading code to chain back to the insertion code
    //   - "specs" or "more specs" links just show/hide the table element rather than building it up; the ajax return below does that
    // The disadvantage would be that the specs wouldn't be stored for later retrieval. This probably isn't a big deal.
   
    my.loadspecs = function (sku, f) {
        // The jQuery AJAX request will add ?callback=? as appropriate. Best Buy API v.2 supports this.
       	var baseurl = "http://www.bestbuy.ca/api/v2/json/product/" + sku;
		if (!(typeof(optemo_french) == "undefined") && optemo_french) baseurl = baseurl+"?lang=fr";
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
                    if (f) f();
                }
            });
        }
		else {
		    // specs are already loaded. In jQuery 1.5 this would warrant a promise() call
		    // but we are in jQuery 1.4.2 at the moment. Keep this code for later.
			// var req = $.Deferred().resolve().promise();
			if (f) f();
		}
    };
	function numberofstars(stars) {
		fullstars = parseInt(stars);
		halfstar = (fullstars == stars) ? 0 : 1;
		emptystars = 5 - fullstars - halfstar;
		ret = "";
		for(var i = 0; i < fullstars; i++)
			ret += '<img src="http://bestbuy.ca/images/common/pictures/yellowStar.gif" />';
		for(var i = 0; i < halfstar; i++)
			ret += '<img src="http://bestbuy.ca/images/common/pictures/yellowhalfstar.gif" />';
		for(var i = 0; i < emptystars; i++)
			ret += '<img src="http://bestbuy.ca/images/common/pictures/emptystar.gif" />';
		return ret;
	}
    // This function gets called when a show action gets called.
    my.preloadSpecsAndReviews = function(sku) {
        my.loadspecs(sku, (function() {
			$('#specs_content').html('<ul>' + parse_bb_json($('body').data('bestbuy_specs_' + sku)) + "</ul>");
		}));
        if (!(jQuery('body').data('bestbuy_reviews_' + sku))) {
            baseurl = "http://www.bestbuy.ca/api/v2/json/reviews/" + sku;
 			if (!(typeof(optemo_french) == "undefined") && optemo_french)
 				baseurl = baseurl+"?lang=fr";
            $.ajax({
                url: baseurl,
    	        type: "GET",
    	        dataType: "jsonp",
                success: function (reviews) {
                    var to_tabbed_content = "";
                    var attributes = reviews["customerRatingAttributes"];

					if ((typeof(optemo_french) == "undefined") || !optemo_french)
						to_tabbed_content += "<br><h3>Customer Ratings</h3>";
					else
						to_tabbed_content += "<br><h3>Classement en général</h3>";
					// Featured Ratings
					for (var i in attributes) {
						to_tabbed_content += '<div class="review_feature">\
							<span>'+i.replace(/_x2019_/g, "’").replace(/_x0020_/g, " ")+'</span>\
							<div class="empty"><div class="fill" style="width:'+(attributes[i]*20)+
							'%"></div></div>\
							<span class="nbr">'
							if (!(typeof(optemo_french) == "undefined") && optemo_french)
								to_tabbed_content += attributes[i].toString().replace(/\./g, ",");
							else
								to_tabbed_content += attributes[i].toString();
							to_tabbed_content += '</span>\
						</div>';
					}
					// Overall Rating
                    to_tabbed_content += '<div class="starrating">\
						<span>Overall Rating</span>' + numberofstars(reviews["customerRating"]) +
						'<span class="nbr">'+reviews["customerRating"]+'</span>\
					</div>';
					//Number of Ratings
					if (!(typeof(optemo_french) == "undefined") && optemo_french){
							to_tabbed_content += '<p class="ratingnumbers">('+reviews['customerRatingCount']+' ratings)</p>';
							to_tabbed_content += '<div style="margin-bottom: 5px">'+reviews["reviews"].length + ' notes';
					}
					else{
                    	to_tabbed_content += '<p class="ratingnumbers">('+reviews['customerRatingCount']+' ratings)</p>';
						to_tabbed_content += '<div style="margin-bottom: 5px">'+reviews["reviews"].length + ' Review';
						if (reviews["reviews"].length != 1) to_tabbed_content += 's';
					}	
					if (!(typeof(optemo_french) == "undefined") && optemo_french)
						to_tabbed_content += ' | <a href="http://www.bestbuy.ca/Catalog/ReviewAndRateProduct.aspx?path=639f1c48d001d04869f91aebd7c9aa86fr99&ProductId='+sku+'&pcname=MCCPCatalog">Directives d\'évaluation de produit</a></div>';
					else
						to_tabbed_content += ' | <a href="http://www.bestbuy.ca/Catalog/ReviewAndRateProduct.aspx?path=639f1c48d001d04869f91aebd7c9aa86en99&ProductId='+sku+'&pcname=MCCPCatalog">Rate and review this product</a></div>';
					var m_names = new Array("January", "February", "March", 
					"April", "May", "June", "July", "August", "September", 
					"October", "November", "December");
					
					var m_names_fr = new Array("janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre");
					
					//Written Reviews
					for (var review in reviews["reviews"]) {
						review = reviews["reviews"][review];
						
						to_tabbed_content += '<div class="bbreview">\
						<h3>'+review["title"]+'&nbsp;|&nbsp;';
						date = new Date(review["submissionTime"]);
						if (date.getMonth().toString() == "NaN")
							to_tabbed_content += review["submissionTime"].replace(/T.*$/,'') + '</h3>';
						else{
							if (!(typeof(optemo_french) == "undefined") && optemo_french)
									to_tabbed_content += "le "+date.getDate()+' '+m_names_fr[date.getMonth()]+' '+date.getFullYear()+'</h3>';
							else		
									to_tabbed_content += m_names[date.getMonth()]+' '+date.getDate()+', ' +date.getFullYear()+'</h3>';
						}			
						to_tabbed_content += '<div>'+review["reviewerName"]+'&nbsp;|&nbsp;'+review["reviewerLocation"]+ '</div>\
							<div class="starrating">\
								<span>Overall Rating</span>'+numberofstars(review["rating"])+
								'<span class="nbr">'+review["rating"]+'</span>'+
							'</div>\
							<p>'+review["comment"]+'</p>\
						</div>';
					}
					if (!(typeof(optemo_french) == "undefined") && optemo_french){
						to_tabbed_content=to_tabbed_content.replace(/ratings/g, 'classements');
						to_tabbed_content=to_tabbed_content.replace(/Overall Rating/g, 'Évaluation');
					}
                    $('body').data('bestbuy_reviews_' + sku, to_tabbed_content);
                    $('#reviews_content').html(to_tabbed_content);
                },
                error: function(x, xhr) {
                    console.log("Error in json ajax");
                    console.log(x);
                    console.log(xhr);
                }
            });
	    }
		else {
		    // specs and reviews are already loaded. In jQuery 1.5 this would warrant a promise() call
		    // but we are in jQuery 1.4.2 at the moment. Keep this code for later.
			// var req = $.Deferred().resolve().promise();
		}
    };

    //--------------------------------------//
    //           UI Manipulation            //
    //--------------------------------------//

    my.removeSilkScreen = function() {
        $('#silkscreen, #outsidecontainer').hide();
    };
    
    my.current_height = (function() {
	var D = document;
	return Math.max(
	    Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
	    Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
	    Math.max(D.body.clientHeight, D.documentElement.clientHeight)
	);
    });

    my.applySilkScreen = function(url,data,width,height,f) {
    	//IE Compatibility
    	var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body,
    	dsoctop=document.all? iebody.scrollTop : window.pageYOffset;
		var outsidecontainer = $('#outsidecontainer');
		if (outsidecontainer.css('display') != 'block') 
			$('#info').html("").css({'height' : "560px", 'width' : (width-46)+'px'});
    	outsidecontainer.css({'left' : Math.max(((document.body.clientWidth-(width||560))/2),0)+'px',
    								'top' : (dsoctop+5)+'px',
    								'width' : (width||560)+'px',
    								'display' : 'inline' });
	var wWidth = $(window).width();
    	$('#silkscreen').css({'height' : my.current_height()+'px', 'display' : 'inline', 'width' : wWidth + 'px'});


    	if (data) {
    		$('#info').html(data).css('height','');
    	} else {
    	    my.quickajaxcall('#info', url, function(){
    	        if (url.match(/\/product/)) {
        	        my.preloadSpecsAndReviews($('.poptitle').attr('data-sku'));
					if (!($.browser.msie && $.browser.version == "6.0")) {
                    	// Initialize Galleria
                    	// If you are debugging around this point, be aware that galleria likes to be initialized without debugging pauses.
                    	$('#galleria').galleria({
						    extend: function(options) {
						        // wait until gallaria is loaded
						        this.bind(Galleria.LOADFINISH, function(e) {
						            var g = $('#galleria').find('.galleria-thumbnails-list');
							        g.children().css('float', 'left');
							        g.append($('#bestbuy_sibling_images').css({'display':'', 'float':'right'}));
						        });
						    }
						});
					}
    	        } else {
    	            $('#outsidecontainer').css('width','');
                }
				$('#info').css("height",'');
				if (f) {
					f();
				}
            });
        }
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
    		var el = img.parent().find('.easylink');
    		res = el.attr('data-id');
    		sku = el.attr('data-sku');
    	}
    	return Array(res, sku);
	}

    function removeFromComparison(id) {
		$(".optemo_compare_checkbox").each( function (index) {
		    if ($(this).attr('data-id') == id) {
				$(this).attr('checked', '');
				return;
			}
	    });
	}

    // Submit a categorical filter, e.g. brand.
    function submitCategorical(){
        //Serialize an form into a hash, Warning: duplicate keys are dropped
        $.fn.serializeObject = function(){
            var o = {};
            var a = this.serializeArray();
            $.each(a, function() {
                if (o[this.name] !== undefined) {
                    if (!o[this.name].push) {
                        o[this.name] = [o[this.name]];
                    }
                    o[this.name].push(this.value || '');
                } else {
                    o[this.name] = this.value || '';
                }
            });
            return o;
        };
        var selections = $("#filter_form").serializeObject();
        $.each(selections, function(k,v){
            if(k.match(/(^superfluous)/) || v == "") {
                delete selections[k];
            }
        });
    	my.ajaxcall("/compare/create", selections);
    	return false;
    }

    /* function submitsearch() {
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
    } */

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

    my.disableInterfaceElements = function() {
        // Disable interface elements.
        $('.slider').each(function() {
            $(this).slider("option", "disabled", true);
        });
        $('.binary_filter, .cat_filter').attr('disabled', true);
		my.loading_indicator_state.disable = true; //Disables any live click handlers
    }

    //--------------------------------------//
    //       Piwik Tracking Functions       //
    //--------------------------------------//

    my.trackPage = function(page_title, extra_data){
    	try {
    	    if (!extra_data) extra_data = {}; // If this argument didn't get sent, set an empty hash
    	    // All the following items get sent with every tracking request.
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
                    
                    if (sliderno == 0 && ui.values[0] != ui.values[1])                        // First slider is not identified correctly by sliderno for the case
                        leftsliderknob.html(realvalue).addClass("valabove");            // when rightslider = left slider, hence the second condition
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
    				var sliderinfo = {'slider_min' : parseFloat(ui.values[0]) * rangemin / 100.0, 'slider_max' : parseFloat(rightslidervalue) * rangemax / 100.0, 'slider_name' : $(this).attr('data-label'), 'filter_type' : 'slider', 'data_min' : datasetmin, 'data_max' : datasetmax, 'ui_position' : $(this).parent().find('.label').attr('data-position')};
    				my.trackPage('goals/filter/slider', sliderinfo);
                    if (leftsliderknob.data('toofar') || rightsliderknob.data('toofar')) {
                        sliderinfo['filter_type'] = 'forced_stop';
        				my.trackPage('goals/filter/forcedstop', sliderinfo);
    				    leftsliderknob.removeData('toofar');
    				    rightsliderknob.removeData('toofar');
                    }
                    submitCategorical();
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
	    margin_hash = {3:-5, 4:-6, 5:-7, 6:-8, 7:-9, 8:-10, 9: -11};
	    
	    if (max_handle_text_len >= 3)
		$(this).children().last().html("<span style='margin-left:" + margin_hash[max_handle_text_len] + "px;'>" + max_handle_text + "</span>");
    	});
    };

    my.LiveInit = function() { // This stuff only needs to be called once per full page load.

    	//Search submit
    	//$('#submit_button').live('click', function(){
    	//	return submitsearch();
    	//});
        //
    	////Search submit
    	//$('#myfilter_search').live('keydown', function (e) {
    	//	if (e.which==13)
    	//		return submitsearch();
    	//});

		//// extended navigation action
		//$('.extendednav').live('click', function(){
	    //    arguments = $(this).attr('data-adjustedfilters');
	    //	my.ajaxcall("/extended", arguments);
		//	return false;
		//})
		
		//See all Products
		$('.seeall').live('click', function() {
		    my.ajaxcall('/', {});
		    return false;
		});
		
    	// Change sort method
    	$('.sortby').live('click', function() {
			if (my.loading_indicator_state.disable) return false;
    	    var whichSortingMethodSelected = $(this).attr('data-feat');
    	    var info = {'chosen_sorting_method' : whichSortingMethodSelected, 'filter_type' : 'sorting_method'};
			my.trackPage('goals/filter/sorting_method', info);
            my.ajaxcall("/compare", {"sortby" : whichSortingMethodSelected});
	    $('.sortby').each( function (index) {
		$(this).removeClass('sortby_selected');
		});
	    $(this).addClass('sortby_selected');
			return false;
	    });

	// Reset button clicked to landing page
    $('a.reset').live('click', function(event) {
    	optemo_module.ajaxsend(null,'/', {landing:'true'});
	window.location.hash = '';
     	return false;
    });


    	//Show and Hide Descriptions
    	//$('.label a, .desc .deleteX').live('click', function(){
    	//	if($(this).parent().attr('class') == "desc")
    	//		{var obj = $(this).parent();}
    	//	else
    	//		{var obj = $(this).siblings('.desc');}
        //    // I think this is just toggling. Just on the off chance that something weird is happening here, I'll leave this code for now. ZAT 2010-08
        //    obj.toggle();
        //    if( obj.is(':visible') ) {
        //		my.trackPage('goals/label', {'filter_type' : 'description', 'ui_position' : obj.parent().attr('data-position')});
    	//	}
    	//	return false;
    	//});

		// Add a color selection -- submit
    	$('.swatch').live('click', function(){
			if (my.loading_indicator_state.disable) return false;
			var t = $(this);
		    var whichThingSelected = t.attr("style").replace(/background-color: (\w+);?/i,'$1');
		    // Fix up the case issues for Internet Explorer (always pass in color value as "Red")
		    whichThingSelected = whichThingSelected.toLowerCase();
		    whichThingSelected = whichThingSelected.charAt(0).toUpperCase() + whichThingSelected.slice(1);
			if (t.hasClass("selected_swatch"))
			{ //Removed selected color
				$('#myfilter_color').val(opt_removeStringWithToken($('#myfilter_color').val(), whichThingSelected, '*'));
	    		var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : 'color', 'filter_type' : 'categorical_removed'};
				my.trackPage('goals/filter/categorical_removed', info);
			}
			else
			{ //Added selected color
    			$('#myfilter_color').val(whichThingSelected);
    			var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : 'color', 'filter_type' : 'categorical'};
				my.trackPage('goals/filter/categorical', info);
			}
			t.toggleClass('selected_swatch');
    		submitCategorical();
    	});

    	// Remove a brand -- submit
    	//$('.removefilter').live('click', function(){
    	//	var whichRemoved = $(this).attr('data-id');
    	//	var whichCat = $(this).attr('data-cat');
    	//	$('#myfilter_'+whichCat).val(opt_removeStringWithToken($('#myfilter_'+whichCat).val(), whichRemoved, '*'));
    	//	var info = {'chosen_categorical' : whichRemoved, 'slider_name' : whichCat, 'filter_type' : 'categorical_removed'};
    	//	my.loading_indicator_state.sidebar = true;
        //	my.trackPage('goals/filter/categorical_removed', info);
    	//	submitCategorical();
    	//	return false;
    	//});

    	// From Compare
    	//Remove buttons on compare
    	$('.remove').live('click', function(){

    	    removeFromComparison($(this).attr('data-name'));
    	    var class_name = $(this).attr('class').split(' ').slice(-1); // spec_column_0, for example

            $("." + class_name).each(function () {
                $(this).remove();
            });

	    

    	    // If this is the last one, take the comparison screen down too
    	    if ($('.comparisonmatrix:first .compare_row:first .columntitle').length <= 1) {
		my.changeNavigatorCompareBtn(0);
    		my.removeSilkScreen();
    	    }
	    else
	    {
		my.changeNavigatorCompareBtn($('.comparisonmatrix:first .compare_row:first .columntitle').length -1 );
	    }
    	    return false;
    	});

        // The next few functions were written to be Best Buy-specific, but they can be extended
        // for any tabbed quickview page. The content is loaded ahead of time by preloadSpecsAndReviews() on popup load.
		$('.fetch').live('click', function() {
			var el = $(this);
			//if (!($.browser.msie && $.browser.version == "7.0")) el.css('background','');
			$('#'+$('#tab_selected').attr('data-tab')).hide();
            $('#tab_selected').removeAttr('id');
    	    el.attr('id', 'tab_selected');
			$('#'+el.attr('data-tab')).show();
			my.trackPage('goals/specs_and_reviews', {'filter_type' : 'specs_and_reviews', 'feature_name' : el.attr('data-tab')});
		        $('#silkscreen').css({'height' : my.current_height()+'px', 'display' : 'inline'});

			return false;
		});

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

        // This bridge function adds the product currently shown in the Quickview screen and puts it in the comparison box.
        // If there are at least two products, bring up the comparison pop-up immediately, otherwise go back to browsing.
        $('#add_compare').live('click', function () {
	        var t = $(this);
            var sku = $('.poptitle').attr('data-sku');
            var image = $('#galleria').find('img:first').attr('src');
	        my.removeSilkScreen();

	        $('.optemo_compare_checkbox').each (function (index) {
		        if ($(this).attr('data-sku') == sku) {
		            $(this).attr('checked', 'checked');
		            return false;
		        }
		        return true;
		    });
	        my.compareCheckedProducts();
	        return false;
        });

        $(".productimg, .easylink").live("click", function (){
            // This is the show page
			var t = $(this), href = t.attr('href') || t.parent().find('.easylink').attr('href'),
        	ignored_ids = getAllShownProductSkus(),
			currentelementid = t.attr('data-sku') || href.match(/\d+$/);
			if (!(t.hasClass('productimg'))) t = t.parent().parent().find('img.productimg');
        	var product_title = t.attr('title');
        	if (product_title == undefined) product_title = t.html(); // This is a text link
        	my.trackPage('goals/show', {'filter_type' : 'show', 'product_picked' : currentelementid, 'product_picked_name' : product_title, 'product_ignored' : ignored_ids, 'imgurl' : t.attr('src')});
			//my.applySilkScreen(href + '?plain=true',null, 560, 580);
			window.location = href;
        	return false;
        });

        //Ajax call for simlinks ('browse similar')
    	$('.simlinks').live("click", function() {
			if (my.loading_indicator_state.disable) return false;
    		var ignored_ids = getAllShownProductIds();
    		my.ajaxcall($(this).attr('href'));
    		my.trackPage('goals/browse_similar', {'filter_type' : 'browse_similar', 'product_picked' : $(this).attr('data-id') , 'product_ignored' : ignored_ids, 'picked_cluster_layer' : $(this).attr('data-layer'), 'picked_cluster_size' : $(this).attr('data-size')});
    		return false;
    	});

    	// Add to cart buy link
    	$('.addtocart').live("click", function(){
    		my.trackPage('goals/addtocart', {'product_picked' : $(this).attr('data-sku'), 'filter_type' : 'addtocart', 'product_picked_name' : $(this).attr('data-name')});
    	});

    	$('.bestbuy_pdp').live("click", function(){
    		my.trackPage('goals/bestbuy_pdp', {'product_picked' : $(this).attr('data-sku'), 'filter_type' : 'bestbuy_pdp', 'product_picked_name' : $(this).attr('data-name')});
    	});

    	//Pagination links
        // This convoluted line takes the second-last element in the list: "<< prev 1 2 3 4 next >>" and takes its numerical page value.
    	var total_pages = parseInt($('.pagination').children().last().prev().html());
    	$('.pagination a').live("click", function(){
    	    if (my.loading_indicator_state.disable) return false;
    		var url = $(this).attr('href')
    		//if (url.match(/\?/))
    		//	url +='&ajax=true'
    		//else
    		//	url +='?ajax=true'
    		if ($(this).hasClass('next_page'))
        		my.trackPage('goals/next', {'filter_type' : 'next' , 'page_number' : parseInt($('.pagination .current').html()), 'total_number_of_pages' : total_pages});
    		else
    		    my.trackPage('goals/next', {'filter_type' : 'next_number' , 'page_number' : parseInt($(this).html()), 'total_number_of_pages' : total_pages});
    		my.ajaxcall(url);
    		return false;
    	});

        $('#back-to-top-bottom').live("click", function() {
            $('body,html').animate({scrollTop: 0}, 800);
    	    return false;
        });

        // Choose a grouping via group button rather than drop-down (effect is the same as the select boxes)
    	//$('.title').live('click', function(){
    	//	if ($(this).find('.choose_group').length) { // This is a categorical feature
        //	    group_element = $(this).find('.choose_group');
        //    	var whichThingSelected = group_element.attr('data-min');
        //    	var categorical_filter_name = group_element.attr('data-grouping');
        //    	if($('#myfilter_'+categorical_filter_name).val().match(whichThingSelected) === null)
        //        	$('#myfilter_'+categorical_filter_name).val(opt_appendStringWithToken($('#myfilter_'+categorical_filter_name).val(), whichThingSelected, '*'));
        //    	var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : categorical_filter_name, 'filter_type' : 'categorical_from_groups'};
        //    	my.trackPage('goals/filter/categorical_from_groups', info);
        //    	submitCategorical();
        //        return false;
        //    }
        //    else { // This is a continuous feature
        //        group_element = $(this).find('.choose_cont_range');
        //        feat = group_element.attr('data-grouping');
        //	    lowerbound = group_element.attr('data-min');
        //	    upperbound = group_element.attr('data-max');
        //	    var arguments_to_send = [];
        //	    arguments = $("#filter_form").serialize().split("&");
        //	    for (i=0; i<arguments.length; i++)
        //        {
        //            if (arguments[i].match(feat)) {
        //                split_arguments = arguments[i].split("=")
        //                if (arguments[i].match(/min/))
        //                    split_arguments[1] = lowerbound;
        //                else
        //                    split_arguments[1] = upperbound;
        //                arguments[i] = split_arguments.join("=");
        //            }
        //            if (!(arguments[i].match(/^superfluous/)))
        //                arguments_to_send.push(arguments[i]);
        //        }
        //    	my.trackPage('goals/filter/continuous_from_groups', {'filter_type' : 'continuous_from_groups', 'feature_name': group_element.attr('data-grouping'), 'selected_continuous_min' : lowerbound, 'selected_continuous_max' : upperbound});
        //        my.ajaxcall("/compare?ajax=true", arguments_to_send.join("&"));
        //	}
    	//});

    	//$('.removesearch').live('click', function(){
    	//	$('#previous_search_word').val('');
		//	$("#myfilter_search").val("");
    	//	$(this).parent().remove();
		//	submitCategorical();
        //	return false;
     	//});

		$('.binary_filter_text').live('click', function(){
			if (my.loading_indicator_state.disable) return false;
			var checkbox = $(this).siblings('input');
			if (checkbox.attr('checked'))
				checkbox.removeAttr("checked");
			else
				checkbox.attr("checked", "checked");
			if (checkbox.hasClass("cat_filter"))
				clickCat(checkbox);
			else
    			clickBinary(checkbox);
			return false;
		});
    	// Checkboxes -- submit
    	$('.binary_filter').live('click', clickBinary);
		function clickBinary() {
			var t = (typeof(arguments[0]) != "undefined" && typeof(arguments[0].originalEvent) != "undefined") ? $(this) : arguments[0];
    		var whichbox = t.attr('data-opt'), box_value = t.attr('checked') ? 100 : 0;
    		my.trackPage('goals/filter/checkbox', {'feature_name' : whichbox, 'filter_type': 'checkbox'});
    		submitCategorical();
    	}
		// Checkboxes -- submit
    	$('.cat_filter').live('click', clickCat);
		function clickCat() {
			var t = (typeof(arguments[0]) != "undefined" && typeof(arguments[0].originalEvent) != "undefined") ? $(this) : arguments[0];
    		var whichcat = t.attr('data-feat'), feature_selected = t.attr('data-opt');
    		var feat_obj = $('#myfilter_'+whichcat);
    		if (t.attr('checked')) // It was just checked a moment ago
			{	// Check action
				feat_obj.val(opt_appendStringWithToken(feat_obj.val(), feature_selected, '*'));
			} else { // Uncheck selection
				feat_obj.val(opt_removeStringWithToken(feat_obj.val(), feature_selected, '*'));
        		my.trackPage('goals/filter/checkbox', {'feature_name' : feature_selected, 'filter_type' : 'brand'});
			}
    		submitCategorical();
    	}

    	$(".close, .bb_quickview_close, #silkscreen").live('click', function(){
    		my.removeSilkScreen();
    		return false;
    	});

		$(".popup").live('click', function(){
			window.open($(this).attr('href'));
			return false;
		});

		/* $(".demo_selector select").live('change', function(){
			var url = "http://"+$(".demo_selector select:last").val()+"."+$(".demo_selector select:first").val()+".demo.optemo.com";
			window.location = url;
		}); */

		//Reset filters
		$('.reset').live('click', function(){
			if (my.loading_indicator_state.disable) return false;
			my.trackPage('goals/reset', {'filter_type' : 'reset'});
			my.ajaxcall($(this).attr('href'));
			return false;
		});
		
		//Zoomout filters
		$('.zoomout').live('click', function(){
			my.trackPage('goals/zoomout', {'filter_type' : 'zoomout'});
			my.ajaxcall($(this).attr('href'));
			return false;
		});
		
		// Special Boxes - these are the featured, top rated, and best selling product layouts
		$('.optemo_special_boxes').live('click', function () {
		    var whichSpecialBoxSelected = $(this).attr('data-special-boxes');
		    my.trackPage('goals/special_boxes', {'filter_type' : 'special_boxes'});
		    my.ajaxcall("/compare/create", {"special_boxes" : whichSpecialBoxSelected});
            return false;
        });

		// Showcase Products - the product banner on the landing page is paid advertising
		$('.showcase_banner').live('click', function () {
		    // Right now this function assumes that brand is the only filter category that the showcase banner is filtering on.
		    var whichBrand = $(this).attr('data-brand');
    		var feat_obj = $('#myfilter_brand');
    		// Since it's just on the landing page, we know that there are no filters yet, 
    		// so we can add without checking if it's already there
			feat_obj.val(opt_appendStringWithToken(feat_obj.val(), whichBrand, '*'));
    		my.trackPage('goals/showcase_banner', {'feature_name' : whichBrand, 'filter_type' : 'brand'});
            submitCategorical();
            return false;
        });
    }

	//These should be locally scoped functions, but for jquery 1.4.2 compatibility it is moved outside (specifically for the cookie-loading-to-savebar part)

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
    my.changeCompareTitle = function(len) {
	    comp_title = $("label.comp-title");
	    comp_title_text = comp_title.text().replace(/\([^)]*\)/, '');
	    if (!(typeof(optemo_french) == "undefined") && optemo_french)
	        comp_title.text(comp_title_text + "(" + len + " Sélection)");
	    else
	        comp_title.text(comp_title_text + "(" + len + " Selected)"); 
	};
	
	my.buildComparisonMatrix = function() {
	    var checkedProducts = my.getSelectedComparisons(), anchor = $('#hideable_matrix');
		// Build up the direct comparison table. Similar method to views/direct_comparison/index.html.erb
		var array = [];
	    my.changeCompareTitle(checkedProducts.length);
	    $.each(checkedProducts, function (index, value) {
		var product = value.split(',');
		array.push($('body').data('bestbuy_specs_'+product[1]));
		});

		var grouped_specs = optemo_module.merge_bb_json.apply(null,array);
		//Set up Headers
	    
		for (var i = 0; i < checkedProducts.length; i++) {
			anchor.append('<div class="columntitle spec_column_'+i+' spec-capt">&nbsp;</div>');
		}
		var result = "";
		var whitebg = true;
		var divContentHolderTag = '<div class="contentholder">';
		var divContentHolderTagEnd = '</div>';
        
		for (var heading in grouped_specs) {
			//Add Heading
			result += '<div class="'+row_class(row_height(heading.length,true))+'"><div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + ' leftcolumntext" style="font-style: italic;"><a class="togglable closed title_link" style="font-style: italic;" href="#">' + heading.replace('&','&amp;') + '</a></div>';

			for (var i = 0; i < checkedProducts.length; i++) {
				result += '<div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + ' spec_column_'+i+'">&nbsp;</div>';
			}
			
			result += "</div>";
			result += divContentHolderTag;
			whitebg = !whitebg;
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
				for (var i = 0; i < checkedProducts.length; i++) {
					if (grouped_specs[heading][spec][i])
						result += '<div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + " " + "spec_column_"+ i + '">' + grouped_specs[heading][spec][i].replace(/&/g,'&amp;') + "</div>";
					else
						//Blank Cell
						result += '<div class="cell ' + ((whitebg) ? 'whitebg' : 'graybg') + " " + "spec_column_"+ i + '">&nbsp;</div>';
				}
				result += "</div>";
				
				whitebg = !whitebg;
			}
			result += divContentHolderTagEnd;
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
	};
	
	function addtoggle(item){
		var closed = item.click(function() {
			$(this).toggleClass("closed").toggleClass("open").parent('.cell').parent().next('div.contentholder').toggle();
			return false;
		}).hasClass("closed");
		if (closed) {item.siblings('div').hide();}
	}

    function ErrorInit() {
        //Link from popup (used for error messages)
        $('#silkscreen').css({'display' : 'none', 'top' : '', 'left' : '', 'width' : ''})
    };

    my.DBinit = function() {
		//Load star ratings
		$(".stars").each(function(){
			var t = $(this);
			t.append(numberofstars(t.attr('data-stars')));
		});
		
		//Infinite Scroll
		//$('#main').infinitescroll({
        //    navSelector  : "div.pagination",            
        //                   // selector for the paged navigation (it will be hidden)
        //    nextSelector : "div.pagination a.next_page",    
        //                   // selector for the NEXT link (to page 2)
        //    itemSelector : "#main div.navbox",          
        //                   // selector for all items you'll retrieve
        //    loadingText : "Loading more products...",
        //    dataType : "jsonp",
        //    donetext : "<em>These are all the products with this selection <a href='#'>here</a></em>"
        //});
		
	    //var model = "";
    	////Autocomplete for searchterms
    	//if (typeof(my.MODEL_NAME) != undefined && my.MODEL_NAME != null) // This check is needed for embedding; different checks for different browsers
    	//    model = my.MODEL_NAME.toLowerCase();
    	//// Now, evaluate the string to get the actual array, defined in autocomplete_terms.js and auto-built by the rake task autocomplete:fetch
    	//if (typeof(model + "_searchterms") != undefined) { // It could happen for one reason or another. This way, it doesn't break the rest of the script
    	//    var terms = window[model + "_searchterms"]; // terms now = ["waterproof", "digital", ... ] using square bracket notation
        //	$("#myfilter_search").autocomplete({
        //	    source: terms
        //	});
    	//}

    	// In simple view, select an aspect to create viewable groups
    	//$('.groupby').unbind('click').click(function(){
		//	feat = $(this).attr('data-feat');
		//	my.loading_indicator_state.sidebar = true;
    	//	my.trackPage('goals/showgroups', {'filter_type' : 'groupby', 'feature_name': feat, 'ui_position': $(this).attr('data-position')});
		//	my.ajaxcall("/groupby/"+feat+"?ajax=true");
    	//});
    };

    //--------------------------------------//
    //                AJAX                  //
    //--------------------------------------//

    my.loading_indicator_state = {spinner_timer : null, socket_error_timer : null, disable : false};

    /* Does a relatively generic ajax call and returns data to the handler below */
    my.ajaxsend = function (hash,myurl,mydata,timeoutlength) {
        var lis = my.loading_indicator_state;
        mydata = $.extend({'ajax': true, category_id: my.RAILS_CATEGORY_ID},mydata);
        if (typeof hash != "undefined" && hash != null && hash != "") {
            mydata.hist = hash;}
        else
            mydata.landing = true;
        if (!(lis.spinner_timer)) lis.spinner_timer = setTimeout("optemo_module.start_spinner()", timeoutlength || 50);
        if (OPT_REMOTE) {
            //Embedded Layout
            myurl = (myurl != null) ? myurl.replace(/http:\/\/[^\/]+/,'') : "/compare"
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
            JSONP.get(OPT_REMOTE+myurl,mydata,my.ajaxhandler);
        } else {
            $.ajax({
            	//type: (mydata==null)?"GET":"POST",
            	data: (mydata==null)?"":mydata,
            	url: myurl || "/compare",
            	success: my.ajaxhandler,
            	error: my.ajaxerror
            });
	    }
    };

    /* The ajax handler takes data from the ajax call and processes it according to some (unknown) rules. */
    // This needs to be a public function now
    my.ajaxhandler = function(data) {

        var lis = my.loading_indicator_state;
        lis.disable = false;
        clearTimeout(lis.spinner_timer); // clearTimeout can run on "null" without error
        clearTimeout(lis.socket_error_timer); // We need to clear the timeout error here
        lis.spinner_timer = lis.socket_error_timer = null;

    	if (data.indexOf('[ERR]') != -1) {
    		var parts = data.split('[BRK]');
    		if (parts[1] != null) {
    			$('#ajaxfilter').empty().append(parts[1]);
    		}
    		my.flashError(parts[0].substr(5,parts[0].length));
    		return -1;
    	} else if (data.indexOf('[PAGE]') != -1){
    	    $('#main #product_content').html(data);
    	    my.stop_spinner();
	    // TODO: Maybe DBInit need to be called here
    	    return 0;
    	} else {
    		var parts = data.split('[BRK]');
    		$('#ajaxfilter').empty().append(parts[1]);
    		$('#main').html(parts[0]);
    		$('#myfilter_search').attr('value',parts[2]);
    		//Reset Infinite Scroll Counter
    		var ifc = $('#main').data('infinitescroll');
    		if (ifc)
    		    ifc.restart();
    		my.stop_spinner();
    		my.SliderInit();
	        my.DBinit();
    		return 0;
    	}
    };

    my.ajaxerror = function() {
        var lis = my.loading_indicator_state;
        lis.disable = false;
        clearTimeout(lis.spinner_timer); // clearTimeout can run on "null" without error
        clearTimeout(lis.socket_error_timer); // We need to clear the timeout error here
		if (!(typeof(optemo_french) == "undefined") && optemo_french)
			my.flashError('<div class="bb_poptitle">Erreur<a class="bb_quickview_close" href="close" style="float:right;">Fermer fenêtre</a></div><p class="error">Désolé! Une erreur est survenue sur le serveur.</p><p>Vous pouvez réinitialiser l\'outil et voir si le problème est résolu.</p>');
		else
    		my.flashError('<div class="bb_poptitle">Error<a class="bb_quickview_close" href="close" style="float:right;">Close Window</a></div><p class="error">Sorry! An error has occurred on the server.</p><p>You can reload the page and see if the problem is resolved.</p>');
    	my.trackPage('goals/error');
    }

    my.ajaxcall = function(myurl,mydata) {
        my.disableInterfaceElements();
    	$.history.load($("#actioncount").html(),myurl,mydata);
    };
    
    my.quickajaxcall = function(element_name, myurl, fn) { // The purpose of this is to do an ajax load without having to go through the relatively heavy ajaxcall().
        if (OPT_REMOTE)
            //Check for absolute urls
            JSONP.get(OPT_REMOTE+myurl.replace(/http:\/\/[^\/]+/,''), {embedding:'true', category_id: my.RAILS_CATEGORY_ID}, function(data){
                $(element_name).html(data);
                if (fn) fn();
            });
        else
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
    	my.stop_spinner();
    	ErrorInit();
    	my.applySilkScreen(null,str,600,107);
    }

    //--------------------------------------//
    //               Layout                 //
    //--------------------------------------//

    // Takes an array of div IDs and removes either inline styles or a named class style from all of them.
    /* my.clearStyles = function(nameArray, styleclassname) {
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
    }; */

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

    /* This gets the currently displayed product ids client-side from the text beneath the product images. */
    function getAllShownProductSkus() {
    	var currentIds = [];
    	$('#main .easylink').each(function() {
    		currentIds.push($(this).attr('data-sku'));
    	});
    	if (currentIds == '') { // This is for Direct view
            $('#main .productinfo').each(function() {
                currentIds.push($(this).attr('data-sku'));
            });
        }
    	return currentIds.join(",");
    }

    my.getShortProductName = function(name) {
    	// This is the corresponding Ruby function.
    	// I modified it slightly, since word breaks are a bit too arbitrary.
    	// [brand.gsub("Hewlett-Packard","HP"),model.split(' ')[0]].join(' ')
    	name = name.replace("Hewlett-Packard", "HP");
		if (name.length > 21)
    		return name.substring(0,20) + "...";
    	else
    		return name;
    };

	//--------------------------------------//
    //              Spinner                 //
    //--------------------------------------//

	my.start_spinner = function() {
		// This will turn on the fade for the left area
        elementToShadow = $('#filterbar');
        var pos = elementToShadow.offset();
        var width = elementToShadow.innerWidth() + 2; // Extra pixels are for the border.
        var height = elementToShadow.innerHeight() + 2; // and padding bottom
        $('#filter_silkscreen').css({'display' : 'inline', 'left' : pos.left + "px", 'top' : pos.top + "px", 'height' : height + "px", 'width' : width + "px"}).fadeTo(0,0.2);

		//Show the spinner up top
		t = $('#loading');
        var viewportwidth, viewportheight;
        if (typeof window.innerWidth != 'undefined') {  // (mozilla/netscape/opera/IE7/etc.)
            viewportwidth = window.innerWidth,
            viewportheight = window.innerHeight;
        } else { // IE6 and others
            viewportwidth = document.getElementsByTagName('body')[0].clientWidth,
            viewportheight = document.getElementsByTagName('body')[0].clientHeight;
        }
        if (height < 100) height = document.body.clientHeight / 2;
		t.css({left: viewportwidth/2 + 'px', top : viewportheight/2 + 'px'}).show();
	}
	
	my.stop_spinner = function() {
		$('#loading, #filter_silkscreen').hide();
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

    // The functions below should not be used; treat them as private, to be called by the two cookie interface functions above
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
    
    my.domready = function(){
        if (typeof DOM_ALREADY_RUN == "undefined") {
            DOM_ALREADY_RUN = true;
            my.initializeVariables();
            // This initializes the jquery history plugin. Note that the plugin was modified for use with our application javascript (details in jquery.history.js)
            $.history.init(optemo_module.ajaxsend);

    	    // Only load DBinit if it will not be loaded by the upcoming ajax call
    	    // Do LiveInit anyway, since timing is not important
    	    my.LiveInit();
    	    if ($('#opt_discovery').length == 0) {
    	    	// Other init routines get run when they are needed.
    	    	my.SliderInit(); optemo_module.DBinit();
    	    }
            
    	    //Decrypt encrypted links
    	    //$('a.decrypt').each(function () {
    	    //	$(this).attr('href',$(this).attr('href').replace(/[a-zA-Z]/g, function(c){
    	    //		return String.fromCharCode((c<="Z"?90:122)>=(c=c.charCodeAt(0)+13)?c:c-26);
    	    //		}));
    	    //});
            
    	    //if (optemo_module.DIRECT_LAYOUT) {
    	    //    //Tour section
    	    //    // There is some code duplication going on here that would be good to condense.
    	    //    // The only real differences here are where the tour goes and what is drawn attention to, 
    	    //    // so this should be possible to condense into about half the amount of code or less
            //	$('#popupTour1, #popupTour2, #popupTour3, #popupTour4').each(function(){
            //		$(this).find('.deleteX').click(function(){
            //			$(this).parent().fadeOut("slow");
            //			optemo_module.clearStyles(["box0", "filterbar", "savebar", "groupby0"], 'tourDrawAttention');
            //			$("#box0").removeClass('tourDrawAttention');
            //    		trackPage('goals/tourclose');
            //			return false;
            //		});
            //	});
            //
            //	$('#popupTour1').find('a.popupnextbutton').click(function(){
            //		var groupbyoffset = $("#groupby0").offset();
            //		$("#popupTour2").css({"position":"absolute", "top" : parseInt(groupbyoffset.top) - 120, "left" : parseInt(groupbyoffset.left) + 220}).fadeIn("slow");
            //		$("#popupTour1").fadeOut("slow");
            //		$("#groupby0").addClass('tourDrawAttention');
            //		$("#box0").removeClass('tourDrawAttention');
            //		trackPage('goals/tournext', {'tour_page_number' : 2});
            //	});
            //
            //	$('#popupTour2').find('a.popupnextbutton').click(function(){
            //		var middlefeatureposition = $("#filterbar").find(".feature:eq(3)").offset();
            //		$("#popupTour3").css({"position":"absolute", "top" : parseInt(middlefeatureposition.top) - 120, "left" : parseInt(middlefeatureposition.left) + 220}).fadeIn("slow");
            //		$("#popupTour2").fadeOut("slow");
            //		$("#filterbar").addClass('tourDrawAttention');
            //		$("#groupby0").removeClass('tourDrawAttention');
            //		trackPage('goals/tournext', {'tour_page_number' : 3});
            //	});
            //
            //	$('#popupTour3').find('a.popupnextbutton').click(function(){
            //		var comparisonposition = $("#savebar").offset();
            //		$("#popupTour4").css({"position":"absolute", "top" : parseInt(comparisonposition.top) - 260, "left" : parseInt(comparisonposition.left) + 70}).fadeIn("slow");
            //		$("#popupTour3").fadeOut("slow");
            //		$("#savebar").addClass('tourDrawAttention');
            //		$("#filterbar").removeClass('tourDrawAttention');
            //		trackPage('goals/tournext', {'tour_page_number' : 4});
            //	});
            //
            //	$('#popupTour4').find('a.popupnextbutton').click(function(){
            //		$("#popupTour4").fadeOut("slow");
            //		$("#savebar").removeClass('tourDrawAttention');
            //		trackPage('goals/tourclose');
            //	});
            //} else {
            //	//Tour section
            //	$('#popupTour1, #popupTour2, #popupTour3').each(function(){
            //		$(this).find('.deleteX').click(function(){
            //			$(this).parent().fadeOut("slow");
            //			optemo_module.clearStyles(["sim0", "filterbar", "savebar"], 'tourDrawAttention');
            //			$("#sim0").removeClass('tourDrawAttention');
            //    		trackPage('goals/tourclose');
            //			return false;
            //		});
            //	});
            //
            //	$('#popupTour1').find('a.popupnextbutton').click(function(){
            //		var middlefeatureposition = $("#filterbar").find(".feature:eq(3)").offset();
            //		$("#popupTour2").css({"position":"absolute", "top" : parseInt(middlefeatureposition.top) - 120, "left" : parseInt(middlefeatureposition.left) + 220}).fadeIn("slow");
            //		$("#popupTour1").fadeOut("slow");
            //		$("#filterbar").addClass('tourDrawAttention');
            //		$("#sim0").removeClass('tourDrawAttention');
            //		$("#sim0").parent().removeClass('tourDrawAttention');
            //		trackPage('goals/tournext', {'tour_page_number' : 2});
            //	});
            //
            //	$('#popupTour2').find('a.popupnextbutton').click(function(){
            //		var comparisonposition = $("#savebar").offset();
            //		$("#popupTour3").css({"position":"absolute", "top" : parseInt(comparisonposition.top) - 260, "left" : parseInt(comparisonposition.left) + 70}).fadeIn("slow");
            //		$("#popupTour2").fadeOut("slow");
            //		$("#savebar").addClass('tourDrawAttention');
            //		$("#filterbar").removeClass('tourDrawAttention');
            //		trackPage('goals/tournext', {'tour_page_number' : 3});
            //	});
            //
            //	$('#popupTour3').find('a.popupnextbutton').click(function(){
            //		$("#popupTour3").fadeOut("slow");
            //		$("#savebar").removeClass('tourDrawAttention');
            //		trackPage('goals/tourclose');
            //	});
    	    //}
            
    /*	    // On escape press. This is used for exiting the tour but would interfere with other uses of escape (canceling the autocomplete box for example)
    	    $(document).keydown(function(e){
    	    	if(e.keyCode==27){
    	    		$(".popupTour").fadeOut("slow");
    	    		optemo_module.clearStyles(["sim0", "filterbar", "savebar"], 'tourDrawAttention');
    	    		if ($.browser.msie && $.browser.version == "7.0") $("#sim0").parent().removeClass('tourDrawAttention');
            		trackPage('goals/tourclose');
    	    	}
    	    });
    */      
    	    //launchtour = (function () {
    	    //    if (optemo_module.DIRECT_LAYOUT) {
    	    //        // Right now the position of the tour pop-up is hard-coded based on a particular element name.
    	    //	    var browseposition = $("#box0").offset();
            //		$("#box0").addClass('tourDrawAttention');
            //		$("#popupTour1").css({"position":"absolute", "top" : parseInt(browseposition.top) - 120, "left" : parseInt(browseposition.left) + 165}).fadeIn("slow");
            //		trackPage('goals/tournext', {'tour_page_number' : 1});
    	    //	} else {
            //		var browseposition = $("#sim0").offset();
            //		// Position relative to sim0 every time in case of interface changes (it is the first browse similar link)
            //		$("#sim0").addClass('tourDrawAttention');
            //		$("#popupTour1").css({"position":"absolute", "top" : parseInt(browseposition.top) - 120, "left" : parseInt(browseposition.left) + 165}).fadeIn("slow");
            //		trackPage('goals/tournext', {'tour_page_number' : 1});
            //	}
    	    //	return false;
    	    //});
    	    //if ($('#tourautostart').length) { launchtour; } //Automatically launch tour if appropriate
    	    //$("#tourButton a").click(launchtour); //Launch tour when this is clicked
            
    	    // Load the classic theme for galleria, the jquery image slideshow plugin we're using (jquery.galleria.js)
            //    Galleria.loadTheme('/javascripts/galleria.classic.js');
            /* Piwik Code */
            var pkBaseURL = (("https:" == document.location.protocol) ? "https://analytics.optemo.com/" : "http://analytics.optemo.com/");
            var piwik_script_tag = document.createElement("script");
            piwik_script_tag.setAttribute("src", pkBaseURL + 'piwik.js');
            piwik_script_tag.setAttribute("type", "text/javascript");
            document.getElementsByTagName("head")[0].appendChild(piwik_script_tag);

            if (piwik_script_tag.readyState){  //IE
                piwik_script_tag.onreadystatechange = function(){
                    if (piwik_script_tag.readyState == "loaded" ||
                            piwik_script_tag.readyState == "complete"){
                        piwik_script_tag.onreadystatechange = null;
                        piwik_ready(); // Using square bracket notation because the jquery object won't be initialized until later
                    }
                };
            } else {  //Others
                piwik_script_tag.onload = function(){
                    piwik_ready();
                };
            }

            function piwik_ready() {
                // The try/catch block here was put in specifically to avoid piwik errors from percolating into
                // the main page. I don't know why it was taken out. ZAT
            //    try {
                    window.piwikTracker = Piwik.getTracker(pkBaseURL + "piwik.php", my.PIWIK_ID); // idsite is here
            		piwikTracker.setDocumentTitle('Index');
            		piwikTracker.setCustomData({'optemo_session': SESSION_ID, 'filter_type' : "index"});
            		piwikTracker.trackPageView();
            		// I'm not sure what emptying the title and data do, but it seems like a standard pattern.
            		piwikTracker.setDocumentTitle('');
            		piwikTracker.setCustomData({});
                    piwikTracker.enableLinkTracking();
            //    } catch( err ) {}
            }
        }
    };
    
    $('.optemo_compare_checkbox').live('click', function(){
        var selectedComps = my.getSelectedComparisons().length;
    	if (selectedComps <= 5) {
            if ($(this).attr('checked')) { // save the comparison item
        	    my.loadspecs($(this).attr('data-sku'));
            }
    	    my.changeNavigatorCompareBtn(selectedComps);
	    } else {
	        if (typeof(optemo_french) == "undefined")
    	        alert("The maximum number of products you can compare is 5. Please try again.");
	        else
    	        alert("Le nombre maximum de produits que vous pouvez comparer est de 5. Veuillez réessayer.");
    	    $(this).attr('checked', '');
        }
	});

    my.getSelectedComparisons = function () {
    	var checkedproducts = [];
    	$('.optemo_compare_checkbox').each( function(index) {
    	    if ($(this).attr('checked')) {
        		checkedproducts.push($(this).attr('data-id') + ',' +  $(this).attr('data-sku'));
    		}
	    });
    	return checkedproducts;
	};

    my.compareCheckedProducts = function () {
    	var checkedProducts = my.getSelectedComparisons();
    	if (checkedProducts.length >= 1) {
    	    var productIDs = '', width = 560, number_of_saved_products = 0;
    	    $.each(checkedProducts, function(index, value) {
        		var product = value.split(',');
        		productIDs = productIDs + product[0] + ',';
        		number_of_saved_products++;
    		});
        }
        // This code has a strange structure and should be cleaned up? Or at least commented?
	    else
	        return false;
        // To figure out the width that we need, start with $('#opt_savedproducts').length probably
        // 560 minimum (width is the first of the two parameters)
        // 2, 3, 4 ==>  513, 704, 895  (191 each)
    	if (number_of_saved_products >= 2)
    	    width = 211 * (number_of_saved_products - 2) + 566;
    	else
    	    width = 566;

    	my.applySilkScreen('/comparison/' + productIDs, null, width, 580,function(){
    	    // Jquery 1.5 would finish all the requests before building the comparison matrix once
    	    // With 1.4.2 we can't do that. Keep code for later.
    	    // $.when.apply(this,reqs).done();
    	    my.buildComparisonMatrix();
	    
        });
	    return false;
	};
    $('#optemo_embedder .nav-compare-btn').live("click", function(e) {
        e.preventDefault();
        my.compareCheckedProducts();
    });

    my.changeNavigatorCompareBtn = function (selected) {
    	if (selected > 0) {
    	    $('.nav-compare-btn').each ( function(index) {
        		$(this).removeClass('awesome_reset_grey');
        		$(this).removeClass('global_btn_grey');
        		$(this).addClass('awesome_reset');
        		$(this).addClass('global_btn');
        		$(this).text($(this).text().replace(/\d+/, selected));
//        		$(this).hover(function(){$(this).css('color', '#ffff00');}, function(){$(this).css('color', '');});
    		});
    	} else {
    	    $('.nav-compare-btn').each ( function(index) {
        		$(this).removeClass('awesome_reset');
        		$(this).removeClass('global_btn');
        		$(this).addClass('awesome_reset_grey');
        		$(this).addClass('global_btn_grey');
        		$(this).text($(this).text().replace(/\d+/, 0));
//        		$(this).unbind('mouseenter mouseleave'); // Remove the hover color change
    		});
        }
	};
	
    $('.optemo_compare_button').live('click', function(){
    	var objCheckbox = $(this).parent().find('.optemo_compare_checkbox');
    	if (!objCheckbox.attr('checked')) {
    	    objCheckbox.attr('checked', 'checked');
    	    my.loadspecs(objCheckbox.attr('data-sku'));
        }
    	my.compareCheckedProducts();
	// Change navigator bar compare button text
	my.changeNavigatorCompareBtn(my.getSelectedComparisons().length);
	
    	return false;
    });
    
    // Back to top button
    $(window).scroll(function () {
    	if ($(this).scrollTop() > $('#filterbar').height()) {
    	    $('#back-top').fadeIn();
    	} else {
    	    $('#back-top').fadeOut();
    	}
	});
		   
    $('#back-top a').click( function () {
    	$('body,html').animate({
    	    scrollTop: 0
    	}, 800);
    	return false;
	});

    return my;
})(optemo_module || {});
    
//--------------------------------------//
//          document.ready()            //
//--------------------------------------//

$(function(){
    if ($("#optemo_embedder").children().length)
        optemo_module.domready();
});


//--------------------------------------//
//             Page Loader              //
//--------------------------------------//

// This should be able to go ahead before document.ready for a slight time savings.
// This history discovery works for embedded also, because by now the ajaxsend function has been redefined, and the history init has been called.
if ($('#opt_discovery').length) {
    if (location.hash) {
    	optemo_module.ajaxsend(location.hash.replace(/^#/, ''),'/');
	} else {
		optemo_module.ajaxsend(null,'/', {landing:'true'});
	}
}

}); // This corresponds with optemo_module_activator and is intentional. The code below here executes first.

// Load jQuery if it's not already loaded.
// The purpose of using a try/catch loop is to avoid Internet Explorer 8 from crashing when assigning an undefined variable.
// NB: Cannot use "$" because of jQuery.noConflict() -- $ might be scoped to prototype or some other framework, depending
var jQueryIsLoaded = jQuery;
try {
    jQueryIsLoaded = true;
}
catch(err) {
    jQueryIsLoaded = false;
}

if(jQueryIsLoaded) {
    // Used to pass in jQuery object to optemo_module_activator
    optemo_module_activator();
} else {
    var script_element = document.createElement("script");
    script_element.setAttribute("type", "text/javascript");
    if (script_element.readyState){  //IE
        script_element.onreadystatechange = function(){
            if (script_element.readyState == "loaded" ||
                    script_element.readyState == "complete"){
                script_element.onreadystatechange = null;
                optemo_module_activator(); // Using square bracket notation because the jquery object won't be initialized until later
            }
        };
    } else {  //Others
        script_element.onload = function(){
            optemo_module_activator();
        };
    }
    // Using jquery 1.4.2 for Best Buy integration reasons
    script_element.setAttribute("src", 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js');
    document.getElementsByTagName("head")[0].appendChild(script_element);
}

