/* Application-specific Javascript. 
   These functions are only used by the mobile branch. This results in a bit of duplication, but is substantially more convenient.
   
   ---- Piwik Tracking Functions ----
    trackPage(page_title, extra_data)  -  Piwik tracking per page. Extra data is in JSON format, with keys for ready parsing by Piwik into piwik_log_preferences. 
                                       -  For more on this, see the Preferences plugin in the Piwik code base.

   ---- JQuery Initialization Routines ----
    FilterAndSearchInit()  -  Search and filter areas.
    DBinit()  -   UI elements from the _discoverybrowser partial, also known as <div id="main">.
	
   ---- document.ready() ----
    document.ready()  -  The jquery call that gets everything started.
*/
var optemo_module;

(function ($) { // See bottom, this is for jquery noconflict
optemo_module = (function (my){
    // The following is pulled from optemo.html.erb
    var VERSION = $("#version").html();
    var SESSION_ID = parseInt($('#seshid').attr('session-id'));
    var AB_TESTING_TYPE = parseInt($('#ab_testing_type').html());

    //--------------------------------------//
    //       Piwik Tracking Functions       //
    //--------------------------------------//

    function trackPage(page_title, extra_data){
    	try {
    	    if (!extra_data) extra_data = {}; // If this argument didn't get sent, set an empty hash
    		extra_data['optemo_session'] = SESSION_ID;
    		extra_data['version'] = VERSION;
    		extra_data['interface_view'] = 'mobile';
    		piwikTracker.setDocumentTitle(page_title);
    		piwikTracker.setCustomData(extra_data);
    		piwikTracker.trackPageView();
    		// I'm not sure what emptying the title and data do, but it seems like a standard pattern.
    		piwikTracker.setDocumentTitle('');
    		piwikTracker.setCustomData({});
    	} catch( err ) {  } // Do nothing, in order to not stop execution of the script. In testing, though, use this line: console.log("Something happened: " + err);
    }

    //--------------------------------------//
    //       Initialization Routines        //
    //--------------------------------------//

    my.FilterAndSearchInit = function() {
    	//Show and Hide Descriptions
    	$('.feature .label a, .feature .deleteX, .desc').click(function(){
    		if($(this).parent().attr('class') == "desc")
    			var obj = $(this).parent();
    		else if ($(this).siblings('.desc').length)
    			var obj = $(this).siblings('.desc');
    		else
    			var obj = $(this);
    		obj.toggle();
            if( obj.is(':visible') ) {
           		trackPage('goals/label', {'filter_type' : 'description', 'ui_position' : obj.parent().attr('data-position')});
       		}
    		return false;
    	});

    	// Checkboxes -- submit
    	$('.binary_filter').click(function() {
    		var whichbox = $(this).attr('id');
    		trackPage('goals/filter/checkbox', {'feature_name' : whichbox});
    	});
	
    	$("#filter_bar").click(function() {
    	    trackPage('goals/mobile-filters', {'filter_type' : 'mobile-filters'});
    		window.location = ("/compare/filter");
    		return false;
    	});
    	$("#startover").click(function() {
    		trackPage('goals/reset', {'filter_type' : 'reset'});
    		window.location = ("/");
    		return false;
    	});
    	// Add a brand
    	$('.selectboxfilter').change(function(){
    		var whichThingSelected = $(this).val();
    		var whichSelector = $(this).attr('name');
    		var selectedOption = $(this).find(":selected");
    		var cat = whichSelector.substring(whichSelector.indexOf("[")+1, whichSelector.indexOf("]"));
    		var capitalizedCat = cat.replace( /(^|\s)([a-z])/g , function(m,p1,p2){ return p1+p2.toUpperCase(); } );
    		$('#myfilter_'+cat).val(opt_appendStringWithToken($('#myfilter_'+cat).val(), whichThingSelected, '*'));
    		// submitCategorical();
    		var info = {'chosen_categorical' : whichThingSelected, 'slider_name' : cat, 'filter_type' : 'categorical'};
        	trackPage('goals/filter/categorical', info);

    		var cat_features_div = $(this).prev();
    		if (cat_features_div.hasClass('selected_cat_features')) {
    	        cat_features_div.append('<a title="Remove filter" data-id="'+whichThingSelected+'" class="removefilter" href=""><img width="13" src="/images/close.png" alt="Close"></a>'+whichThingSelected);
    	    } else {
        		$(this).before('<div class="selected_cat_features"><a title="Remove filter" data-id="'+whichThingSelected+'" class="removefilter" href=""><img width="13" src="/images/close.png" alt="Close"></a>'+whichThingSelected+'</div>');
    		}
		
    		$(this).find('option:first').val('Add Another '+capitalizedCat).html('Add Another '+capitalizedCat);
    		$(this).find('option:first').attr('selected', 'selected');
    		selectedOption.remove();
    		FilterAndSearchInit(); // Need the removefilter button which just showed up to be jquery enabled
    	});
	
    	// Remove a brand -- submit
    	$('.removefilter').click(function(){
    	    var whichRemoved = $(this).attr('data-id');
    		var whichCat = $(this).attr('data-cat');
    		$('#myfilter_'+whichCat).val(opt_removeStringWithToken($('#myfilter_'+whichCat).val(), whichRemoved, '*'));
    		var info = {'chosen_categorical' : whichRemoved, 'slider_name' : whichCat, 'filter_type' : 'categorical_removed'};
        	trackPage('goals/filter/categorical_removed', info);
    		$(this).parent().remove();
    		return false;
    	});
	
    	$('#removeSearch').click(function(){
    		$('#previous_search_word').val('');
    		$('#previous_search_container').remove();
    		$('#myfilter_search').val('');
    		return false;
    	});
	
    	//Clear form
    	$('.reset').click(function(){
    		//Reset min sliders
    		$('*[id^=featurerangeone]').each(function() {
    			this.selectedIndex = 0;
    		});
    		//Reset max sliders
    		$('*[id^=featurerangetwo]').each(function() {
    			this.selectedIndex = this.length-1;
    		});
    		//Reset brands
    		$('.removefilter').each(function() {
    			$(this).click();
    		});
    		//Clear search term
//    		$('#removeSearch').click(); // ?
    		//Clear check boxes
    		$('.binary_filter').each(function() {
    			this.checked = false;
    		});
    		trackPage('goals/reset', {'filter_type' : 'reset'});
    		return false;
    	});
    	
    	$('.productinfo').click(function(){
    	    window.location = ($(this).attr('data-url'));
	    });
    }

    my.DBinit = function() {
    	$('.sim, .simparent').unbind('click').click(function(){
            window.location = ($(this).find('img').attr('data-id'));
    		return false;
    	});	
    	// This next function covers for the fact that not all images are the same dimensions.
    	// In future, it would be nice if every image were known, square sizes like 50x50. Then we could avoid this.
    	$('img.productimg').each(function() {
    	    if(parseInt($(this).css('height')) > 50) 
    	    {
    	        // We should not have resized the width; aspect ratio is wrong. So, add the appropriate height constrait and change the width constraint.
    	        // We can't just edit the class directly since it applies to all the other images.
    	        $(this).css('width', (2500.0 / parseInt($(this).css('height')))+'px').css('height','50px');
            }
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
	optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
});
