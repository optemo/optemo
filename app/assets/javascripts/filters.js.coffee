# Filters 
opt = window.optemo_module ? {}

#****Public Functions****

#****Private Functions****

# LiveInit functions 

$('.binary_filter').live 'click', opt.submitAJAX
$('.cat_filter').live 'click', opt.submitAJAX
$('.checkbox_text').live 'click', ->
  if (opt.loading_indicator_state.disable)
    return false
  checkbox = $(this).siblings('input')
  if (checkbox.is(":checked"))
    checkbox.prop('checked', false)
  else
    checkbox.prop('checked', 'checked')
  opt.submitAJAX()
  return false

# Add a color selection -- submit
$('.swatch_button').live 'click', ->
  if (opt.loading_indicator_state.disable)
    return false
  t = $(this)
  if (t.hasClass("selected_swatch_dark") || t.hasClass("selected_swatch_light"))
    #Removed selected color
    $('#categorical_color').val("")
  else 
  #Added selected color
    whichThingSelected = t.attr("style").replace(/background-color: (\w+);?/i,'$1')
    $('#categorical_color').val(whichThingSelected.toLowerCase())
  t.toggleClass('selected_swatch')
  opt.submitAJAX()

$('.remove_filter').live 'click', ->
  id = $(this).attr('data-id')
  selection = 'input[data-id="' + id + '"]'
  if id.match(/slider/)
    $(selection).val(';')
    opt.submitAJAX()
  else 
    if id == "swatchcolor"
      $(selection).val('')
      opt.submitAJAX()
    else
      $(selection).prop('checked', false).click()
  #Needs to handle slider and color swatches
  return false

#Reset filters
$('.reset').live 'click', ->
  if (opt.loading_indicator_state.disable)
    return false
  opt.ajaxcall('/',{landing:'true'})
  return false
  
$('.moreless').live 'click', ->
  t = $(this).toggle()
  t.siblings(".minor,.moreless").toggle() #Toggle cat options
  #Save setting in hidden field
  v = t.parent().siblings("input")
  v.val(v.val() == "" || v.val() == "false")
  return false

# End of LiveInit Functions
window.optemo_module = opt