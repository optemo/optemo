# Product Template

opt = window.optemo_module ? {}

#****Public Functions****
opt.public_func = (args) ->
  #myfunc

#****Private Functions***
private_func = (args) ->
  #myfunc

#****Live-init Functions*
$('.example').live 'click', ->
  optemo_module.ajaxcall('/', {})
  return false
    
window.optemo_module = opt