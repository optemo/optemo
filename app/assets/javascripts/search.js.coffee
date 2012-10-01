#Search
opt = window.optemo_module ? {}

#****Public Functions****
#****Private Functions***
get_filtering_specs = ->
  # check if there is any filtering before starting the keyword search (maybe it's needed to combine with my.submitAJAX)
  selections = $("#filter_form").serializeObject()
  $.each selections, (k,v) ->
    if v == "" || v == "-" || v == ";"
      delete selections[k]
    # Slider values shouldn't get sent unless specifically set
    if k.match(/superfluous/)
      delete selections[k]
  return selections

# LiveInit functions
$('#keyword_submit').live "click", ->
  return false if opt.loading_indicator_state.disable
  selections = get_filtering_specs()
  if $("#product_name").val() != "" && $("#product_name").val() != "Search terms"
    my.ajaxcall "/search", $.extend(selections, {"keyword" : $("#product_name").val()})
  else
    my.ajaxcall "/search", selections
  return false

$('.suggestion').live 'click', ->
  return false if opt.loading_indicator_state.disable
  selections = get_filtering_specs()
  my.ajaxcall "/search", $.extend(selections,{"keyword" : $.trim($(this).html())})
  return false

# End of LiveInit Functions

window.optemo_module = opt