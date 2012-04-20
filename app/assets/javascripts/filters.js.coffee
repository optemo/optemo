# Filters 
@module "optemo_module", ->

    #****Public Functions****
  
    #****Private Functions****
  
    # LiveInit functions 
  
    $('.binary_filter').live 'click', optemo_module.submitAJAX
    $('.cat_filter').live 'click', optemo_module.submitAJAX
    $('.checkbox_text').live 'click', ->
      if (optemo_module.loading_indicator_state.disable)
        return false
      checkbox = $(this).siblings('input')
      if (checkbox.attr("checked"))
        checkbox.removeAttr("checked")
      else
        checkbox.attr("checked", "checked")
      optemo_module.submitAJAX()
      return false
  
    # Add a color selection -- submit
    $('.swatch_button').live 'click', ->
      if (optemo_module.loading_indicator_state.disable)
        return false
      t = $(this)
      if (t.hasClass("selected_swatch"))
        #Removed selected color
        $('#categorical_color').val("")
      else 
      #Added selected color
        whichThingSelected = t.attr("style").replace(/background-color: (\w+);?/i,'$1')
        # Fix up the case issues for Internet Explorer (always pass in color value as "Red")
        whichThingSelected = whichThingSelected.toLowerCase()
        whichThingSelected = whichThingSelected.charAt(0).toUpperCase() + whichThingSelected.slice(1)
        $('#categorical_color').val(whichThingSelected)
      t.toggleClass('selected_swatch')
      optemo_module.submitAJAX()
    
    $('.remove_filter').live 'click', ->
      selected_node = $(this).parent()
      name = selected_node.attr('data-name')
      value = selected_node.attr('data-value')
      if value == undefined
        filter_node = $('#'+name)
      else
        filter_node = $('#'+name+'[value='+value+']')
      if (filter_node.attr("checked"))
        filter_node.removeAttr('checked')
      optemo_module.submitAJAX()
      return false
  
    #Reset filters
    $('.reset').live 'click', ->
      if (optemo_module.loading_indicator_state.disable)
        return false
      optemo_module.ajaxcall('/',{landing:'true'})
      return false
      
    $('.moreless').live 'click', ->
      $(this).parent().toggle().siblings('.categorical').toggle()
      return false

    # End of LiveInit Functions