#= require def
#= require realtime_price
#= require raphael
#= require jquery.dependClass
#= require jquery.slider
#= require jquery.history
#= require cookies
#= require sliders
#= require comparison
#= require ajax
#= require_self
#= require filters
#= require bbfixes

# Switched 'def' position from before 'cookies' to before 'realtime_price' so that module method would be defined in realtime_price

# These global variables must be declared explicitly for proper scope (the spinner is because setTimeout has its own scope and needs to set the spinner)
@module "optemo_module", ->
  #/* LiveInit functions */
  
  #Product links
  $(".productimg, .easylink").live "click", ->
    # This is the show page
    t = $(this)
    href = t.attr('href') or t.parent().find('.easylink').attr('href')
    window.location = href
    return false
  
  #Links which open in a new window
  $(".popup").live 'click', ->
    window.open($(this).attr('href'))
    return false
  
  #Scroll back to the top
  $('#back-to-top-bottom').live "click", ->
    $('body,html').animate({scrollTop: 0}, 800)
    return false
  
  ### Bundles are disabled for now
  //Bundle link
  $('.bundlediv').live('click', function() {
      window.location = $(this).attr("data-url");
  });
  ###

  #/* End of LiveInit functions */


#//--------------------------------------//
#//             Page Loader              //
#//--------------------------------------//

#Load the initial page in non-embedded layout
if $('#opt_discovery'),length
  #Pass in the option as a url param (Digital Cameras are default)
  window.opt_category_id = decodeURI((RegExp('([?]|&)[Cc]ategory_id=(.+?)(&|$)').exec(location.search)||[0,0,22474])[2])
  if (location.hash)
    optemo_module.ajaxsend(location.hash.replace(/^#/, ''),'/', {category_id: opt_category_id})
  else
    optemo_module.ajaxsend(null,'/', {landing:'true', category_id: opt_category_id})
    

