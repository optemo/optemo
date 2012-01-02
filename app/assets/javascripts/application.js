//= require realtime_price
//= require raphael
//= require jquery-ui-1.8.13.custom.min
//= require jquery.history
//= require cookies
//= require ajax
//= require_self
//= require filters
//= require sliders
//= require comparison
//= require bbfixes
//= require solr-autocomplete/ajax-solr/core/Core
//= require solr-autocomplete/ajax-solr/core/AbstractManager
//= require solr-autocomplete/ajax-solr/managers/Manager.jquery
//= require solr-autocomplete/ajax-solr/core/Parameter
//= require solr-autocomplete/ajax-solr/core/ParameterStore
//= require solr-autocomplete/jquery-autocomplete/jquery.autocomplete

// These global variables must be declared explicitly for proper scope (the spinner is because setTimeout has its own scope and needs to set the spinner)
var optemo_module;
optemo_module = (function (my){
    /* LiveInit functions */
    
    //Product links
    $(".productimg, .easylink").live("click", function (){
        // This is the show page
        var t = $(this), href = t.attr('href') || t.parent().find('.easylink').attr('href');
        window.location = href;
        return false;
    });
    
    //Links which open in a new window
    $(".popup").live('click', function(){
        window.open($(this).attr('href'));
        return false;
    });
    
    //Scroll back to the top
    $('#back-to-top-bottom').live("click", function() {
        $('body,html').animate({scrollTop: 0}, 800);
        return false;
    });
    
    /* Bundles are disabled for now
    //Bundle link
    $('.bundlediv').live('click', function() {
        window.location = $(this).attr("data-url");
    });
    */
  
    /* End of LiveInit functions */

    return my;
})(optemo_module || {});

//--------------------------------------//
//             Page Loader              //
//--------------------------------------//

//Load the initial page in non-embedded layout
if ($('#opt_discovery').length) {
    //Pass in the option as a url param (Digital Cameras are default)
    window.opt_category_id = decodeURI((RegExp('([?]|&)[Cc]ategory_id=(.+?)(&|$)').exec(location.search)||[,,22474])[2]);
    if (location.hash) {
        optemo_module.ajaxsend(location.hash.replace(/^#/, ''),'/', {category_id: opt_category_id});
    } else {
        optemo_module.ajaxsend(null,'/', {landing:'true', category_id: opt_category_id});
    }
}
