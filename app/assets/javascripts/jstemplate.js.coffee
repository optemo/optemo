# Product Template

@module "optemo_module", ->
  #****Public Functions****
  @public_func = (args) ->
    #myfunc
  
  #****Private Functions***
  private_func = (args) ->
    #myfunc
  
  #****Live-init Functions*
  $('.example').live 'click', ->
    optemo_module.ajaxcall('/', {})
    return false