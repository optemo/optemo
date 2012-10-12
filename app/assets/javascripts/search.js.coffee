#Search
opt = window.optemo_module ? {}

#****Public Functions****
#****Private Functions***

# LiveInit functions
$('#keyword_submit').live "click", ->
  return false if opt.loading_indicator_state.disable
  ajax_data = {}
  product_name = $("#product_name").val()
  if product_name? and product_name != "" and product_name != "Search terms" 
    ajax_data["keyword"] = product_name
  opt.ajaxcall "/search", ajax_data
  return false

$('.suggestion').live 'click', ->
  return false if opt.loading_indicator_state.disable
  opt.ajaxcall "/search", {"keyword" : $.trim($(this).html())}
  return false

# Return to the home or category that user searched from.
$('.last_page').live 'click', ->
  opt.ajaxcall('/', {})
  return false

# End of LiveInit Functions

window.optemo_module = opt
