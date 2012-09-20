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
  if (checkbox.attr("checked"))
    checkbox.removeAttr("checked")
  else
    checkbox.attr("checked", "checked")
  opt.submitAJAX()
  return false

# Add a color selection -- submit
$('.swatch_button').live 'click', ->
  if (opt.loading_indicator_state.disable)
    return false
  t = $(this)
  if (t.hasClass("selected_swatch"))
    #Removed selected color
    $('#categorical_color').val("")
  else 
  #Added selected color
    whichThingSelected = t.attr("style").replace(/background-color: (\w+);?/i,'$1')
    $('#categorical_color').val(whichThingSelected.toLowerCase())
  t.toggleClass('selected_swatch')
  opt.submitAJAX()

$('.remove_filter').live 'click', ->
  selected_node = $(this).parent()
  name = selected_node.attr('data-name')
  value = selected_node.attr('data-value')
  if value == undefined
    filter_node = $('#'+name)
  if name.match(/binary/)
    filter_node = $('#'+name)
  else if name.match(/slider/)
    filter_node = $('#continuous_' + name.split('_')[1])
  else if name.match(/continuous/)
    the_min = value.split(';')[0]
    filter_node = $('#' + name + '[data-min="' + the_min + '"]')
    filter_node = $('#' + name + '[class="range"]') if filter_node.length==0
  else if name.match(/categorical_color/)
    $('#categorical_color').val("")
    filter_node = $('.swatch_button[title="' + value + '"]')
    filter_node.removeClass('selected_swatch')
  else if name.match(/keyword/)
    $("#product_name").val('')
  else
    filter_node = $('#'+name+'[value="'+value+'"]')
  if (filter_node.attr("checked"))
    filter_node.removeAttr('checked')
  if (filter_node.hasClass('range'))
    filter_node.attr('value',';')
  opt.submitAJAX()
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