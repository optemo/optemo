#= require raphael
#= require jquery.dependClass
#= require jquery.history
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
#= require bootstrap-dropdown.js

opt = window.optemo_module ? {}
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
  t = $(this)
  t.siblings('.bundle_item').slideToggle()
  t.siblings('.bundle_spacer').slideToggle()
  t.children('.bundle_package_stub_text, .bundle_icon').each -> 
    $(this).toggle()
  return false

#/* End of LiveInit functions */


#//--------------------------------------//
#//             Page Loader              //
#//--------------------------------------//

#Load the initial page in non-embedded layout
if $('#opt_discovery').length
  #Pass in the option as a url param (Digital Cameras are default)
  window.opt_category_id = decodeURI((RegExp('([?]|&)[Cc]ategory_id=(.+?)(&|$)').exec(location.search)||[0,0,"B20218"])[2])
  hash = location.hash
  if hash?
    hash = hash.replace(/^#/, '')
  if (hash? and hash != "")
    opt.ajaxsend('/', {category_id: opt_category_id}, hash)
  else
    opt.ajaxsend('/', {landing:'true', category_id: opt_category_id}, null)
    
window.optemo_module = opt

