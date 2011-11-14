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
    
    // Showcase Products - the product banner on the landing page is paid advertising
    $('.showcase_banner').live('click', function () {
        var whichBrand = $(this).attr('data-brand');
        if (whichBrand != undefined && whichBrand != "") {
            var feat_obj = $('#categorical_brand');
            // Since it's just on the landing page, we know that there are no filters yet, 
            // so we can add without checking if it's already there
            feat_obj.val(whichBrand);
            my.submitAJAX();
        } else { // This is not scalable. Eventually this sort of logic should be in Firehose.
            var whichProduct = $(this).attr('product_type');
            if (whichProduct == 'camera_bestbuy'){
                window.location = "http://www.bestbuy.ca/" + ((!(typeof(optemo_french) == "undefined") && optemo_french) ? "fr" : "en") + "-CA/category/new-technology/pc_new.aspx";
            } else if (whichProduct == 'drive_bestbuy'){
                window.location = "http://www.bestbuy.ca/" + ((!(typeof(optemo_french) == "undefined") && optemo_french) ? "fr" : "en") + "-CA/category/new-technology/pc_new.aspx";
            }    
        }
        return false;
    });
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
