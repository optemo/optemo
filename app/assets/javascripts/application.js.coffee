#= require def
#= require realtime_price
#= require raphael
#= require jquery.dependClass
#= require jquery.history
#= require jshashtable
#= require jquery.numberformatter
#= require jquery.slider
#= require cookies
#= require sliders
#= require comparison
#= require ajax
#= require_self
#= require filters
#= require bbfixes
#= require search
#= require solr-autocomplete/ajax-solr/core/Core
#= require solr-autocomplete/ajax-solr/core/AbstractManager
#= require solr-autocomplete/ajax-solr/managers/Manager.jquery
#= require solr-autocomplete/ajax-solr/core/Parameter
#= require solr-autocomplete/ajax-solr/core/ParameterStore
#= require solr-autocomplete/jquery-autocomplete/jquery.autocomplete

# These global variables must be declared explicitly for proper scope (the spinner is because setTimeout has its own scope and needs to set the spinner)
@module "optemo_module", ->
  #/* LiveInit functions */
  
  #Product links
  $(".productimg, .easylink, .futureshop_price, .futureshop_sale_background").live "click", ->
    # This is the show page
    t = $(this)
    href = t.attr('href') or t.parent().find('.easylink').attr('href') or t.parent().parent().find('.easylink').attr('href')
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

  $('.bundle_more_deals_stub').live 'click', ->
    $(this).siblings('.bundle_item').slideToggle()
    $(this).siblings('.bundle_spacer').slideToggle()
    return false

  #/* End of LiveInit functions */


#//--------------------------------------//
#//             Page Loader              //
#//--------------------------------------//

#Load the initial page in non-embedded layout
if $('#opt_discovery').length
  #Pass in the option as a url param (Digital Cameras are default)
  window.opt_category_id = decodeURI((RegExp('([?]|&)[Cc]ategory_id=(.+?)(&|$)').exec(location.search)||[0,0,"B20218"])[2])
  if (location.hash)
    optemo_module.ajaxsend(location.hash.replace(/^#/, ''),'/', {category_id: opt_category_id})
  else
    optemo_module.ajaxsend(null,'/', {landing:'true', category_id: opt_category_id})
    

