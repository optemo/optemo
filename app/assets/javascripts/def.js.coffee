#@module helper from http://stackoverflow.com/questions/6815957/how-do-you-write-dry-modular-coffeescript-with-sprockets-in-rails-3-1
window.module = (name, fn)->
  if not @[name]?
    this[name] = {}
  if not @[name].module?
    @[name].module = window.module
  fn.apply(this[name], [])