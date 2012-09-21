#Search
opt = window.optemo_module ? {}

#****Public Functions****
#****Private Functions***

# LiveInit functions
$('#keyword_submit').live "click", ->
  return false if opt.loading_indicator_state.disable
  my.ajaxcall "/search", my.build_ajax_data()
  return false

$('.suggestion').live 'click', ->
  return false if opt.loading_indicator_state.disable
  my.ajaxcall "/search", my.build_ajax_data({"keyword" : $.trim($(this).html())})
  return false

# End of LiveInit Functions

window.optemo_module = opt
