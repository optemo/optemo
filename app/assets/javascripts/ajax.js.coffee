
#//--------------------------------------//
#//                AJAX                  //
#//--------------------------------------//

opt = window.optemo_module ? {}
opt.loading_indicator_state = {spinner_timer : null, socket_error_timer : null, disable : false}

#****Public Functions****
opt.whenDOMready = ->
  if not opt.history_initialized
    # Set up the on_hash_change function for use with the back button
    $.history.init(opt.on_hash_change,{unescape: true})
    opt.history_initialized = true

  # Update the hash to match the value provided in the page.
  $.history.update_hash($("#actioncount").html(), null, null)

  BestBuyLandingElements()
  SetLayout()
  opt.SliderInit()
  opt.getRealtimePrices(false) if typeof(opt.getRealtimePrices) == "function"
  opt.load_comparisons()

# Submit a categorical filter, e.g. brand.
opt.submitAJAX = ->
  opt.ajaxcall("/compare", opt.build_ajax_data())

opt.removeSilkScreen = ->
  $('#opt_silkscreen, #opt_outsidecontainer').hide()
  
opt.current_height = -> 
  D = document
  return Math.max(
    Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
    Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
    Math.max(D.body.clientHeight, D.documentElement.clientHeight)
  )

#Optemo's Lightbox effect
opt.applySilkScreen = (url,data,width,height,f) ->
  #IE Compatibility
  iebody= if(document.compatMode and document.compatMode isnt "BackCompat") then document.documentElement else document.body
  dsoctop= if document.all then iebody.scrollTop else window.pageYOffset
  outsidecontainer = $('#opt_outsidecontainer')
  if (outsidecontainer.css('display') isnt 'block') 
    $('#info').html("").css({'height' : "560px", 'width' : (width-34)+'px'})
  wWidth = $(window).width()
  # Position with equal L/R margins
  lPosition = parseInt((wWidth - width) / 2.0)
  outsidecontainer.css(
    'left' : lPosition,
    'top' : (dsoctop+10)+'px',
    'width' : (width||560)+'px',
    'display' : 'inline' )
  $('#opt_silkscreen').css({'height' : opt.current_height()+'px', 'display' : 'inline', 'width' : wWidth + 'px'})
  if ($.browser.msie && $.browser.version.substr(0,1)<7) # IE6 only
    $('#info').css('overflow', 'hidden')
    quickview_close = $("#info .bb_quickview_close").detach()
    quickview_close.prependTo("#opt_outsidecontainer")
    $('#opt_silkscreen').css({'height' : opt.current_height()+500+'px'}) # This is for the compare screen.
  if (data)
    $('#info').html(data).css('height','')
  else
    quickajaxcall('#info', url, ->
      $('#opt_outsidecontainer').css('width','')
      $('#info').css("height",'')
      if (f)
          f()
    )

# Called whenever the forward or back button is pressed.
opt.on_hash_change = (hash,myurl,mydata) ->
  if not hash? or hash == ""
    if not mydata?
      mydata = {landing: true}
    else
      $.extend(mydata, {landing: true})
  opt.ajaxsend(myurl,mydata,hash)

#/* Does a relatively generic ajax call and returns data to the handler below */
opt.ajaxsend = (myurl,mydata,hash) ->
  lis = opt.loading_indicator_state
  #The Optemo category ID should be set in the loader unless this file is loaded non-embedded, then it is set in the opt_discovery section
  mydata = $.extend({'ajax': true, category_id: window.opt_category_id},mydata)
  QC_cookie_value = opt.getCookieValue("regionCode")
  mydata.is_quebec = (if (QC_cookie_value is "QC") then "true" else "false")
  if (hash? and hash != "") 
    mydata.hist = hash
  if (not(lis.spinner_timer)) 
    lis.spinner_timer = setTimeout(opt.start_spinner, 800)
  val_timeout = 10000
  if (/localhost/.test(myurl) or /192\.168/.test(myurl))
    val_timeout = 100000
  lis.socket_error_timer = setTimeout(opt.ajaxerror, val_timeout)
  if (window.OPT_REMOTE)
    #Embedded Layout
    myurl = if myurl? then myurl.replace(/http:\/\/[^\/]+/,'') else "/compare"
    # There is a bug in the JSONP implementation. If there is a "?" in the URL, with parameters already on it,
    # this JSONP implementation will add another "?" for the second set of parameters (specified in mydata).
    # For now, just check for a "?" and take those parameters into mydata, 
    # then strip them and the '?' from the URL. -ZAT July 20, 2011
    if (myurl.match(/\?/))
      for contents in myurl[(myurl.indexOf('?') + 1)..-1].split('&')
        data = contents.split('=')
        mydata[data[0]] = data[1]
      myurl = myurl[0...myurl.indexOf('?')]                   
    JSONP.get(window.OPT_REMOTE+myurl,mydata,ajaxhandler)
  else
    $.ajax
      data: if mydata? then mydata else "",
      url: myurl or "/compare",
      success: ajaxhandler,
      error: opt.ajaxerror

opt.ajaxerror = ->
  clear_loading()
  if optemo_french?
    errorstr = '<div class="bb_poptitle"><label class="comp-title">Erreur</label><div class="bb_quickview_close"></div></div><p class="error">Désolé! Une erreur est survenue sur le serveur.</p><p>Vous pouvez réinitialiser l\'outil et voir si le problème est résolu.</p>'
  else
    errorstr = '<div class="bb_poptitle"><label class="comp-title">Error</label><div class="bb_quickview_close"></div></div><p class="error">Sorry! An error has occurred on the server.</p><p>You can reload the page and see if the problem is resolved.</p>'
  iebody= if(document.compatMode and document.compatMode isnt "BackCompat") then document.documentElement else document.body
  dsoctop= if document.all then iebody.scrollTop else window.pageYOffset
      
  opt.applySilkScreen(null,errorstr) #,dsoctop + 10,107)
  unless opt.lastpage?
    opt.lastpage = true #Loads the first page after the dialog is closed to try and mitigate the problem. and only do it once

opt.ajaxcall = (myurl,mydata,hash=null) ->
  # Disable interface elements.
  $('.binary_filter, .cat_filter').attr('disabled', true)
  opt.loading_indicator_state.disable = true #Disables any live click handlers and sliders
  $('.jslider-pointer').each( ->
    $(this).addClass('jslider-pointer-disabled')
  )
  opt.ajaxsend(myurl, mydata, hash)

# Builds the data parameter for the Ajax call. Values in the data hash (if provided)
# override the values gathered by this function.
opt.build_ajax_data = (data = null) ->
  ajax_data = $("#filter_form").serializeObject()
  $.each(ajax_data, (k,v) ->
    if(v is "" or v is "-" or v is ";" or v is "false")
      delete ajax_data[k]
    #/* Slider values shouldn't get sent unless specifically set */
    if(k.match(/superfluous/))
      delete ajax_data[k]
  )
  product_name = $("#product_name").val()
  if product_name? and product_name != "" and product_name != "Search terms" 
    ajax_data["keyword"] = product_name
  sorting_method = $("#current_sorting_method").html()
  if sorting_method? and sorting_method != ""
    ajax_data["sortby"] = sorting_method
  if data?
    $.extend(ajax_data, data)
  ajax_data

#//--------------------------------------//
#//            Loading Spinner           //
#//--------------------------------------//

opt.start_spinner = ->
  #Show the spinner up top
  viewportwidth = undefined
  viewportheight = undefined
  if window.innerWidth? # (mozilla/netscape/opera/IE7/etc.)
    viewportwidth = window.innerWidth
    viewportheight = window.innerHeight
  else # IE6 and others
    viewportwidth = document.getElementsByTagName('body')[0].clientWidth
    viewportheight = document.getElementsByTagName('body')[0].clientHeight
  $('#opt_loading').css({left: viewportwidth/2 + 'px', top : viewportheight/2 + 'px'}).show()

opt.stop_spinner = ->
  $('#opt_loading').hide()

#****Private Functions****
BestBuyLandingElements = ->
  bb_divs = $("#pagecontentmain2 > [id^=ctl00_CP], #pagecontentmain2 > .std-bottommargin, #pagecontentmain2 .articles-container, #pagecontentmain2 .ui-tabcontrol, #contentleft1 [id^=ctl00_CC], #contentleft1 .department-headline, #contentleft1 .tech-community, #contentleft1 .btm-space")
  if ($("#landingpage_indicator").length == 0)
    # If they exist, hide the Best Buy landing page elements
    if (bb_divs.length != 0) # Make sure they exist
      bb_divs.hide()
  else
    # show them again for landing page
    if (bb_divs.length != 0) # Make sure they exist
      bb_divs.show()
  $('#pagecontentleft2 .sublevel, #pagecontentleft2 .leftnavbox-white').hide();

SetLayout = ->
  opt.layout = $('#opt_outsidecontainer').attr('data-layout') # This will be either fs or bb to indicate which layout

quickajaxcall = (element_name, myurl, fn) -> # The purpose of this is to do an ajax load without having to go through the relatively heavy ajaxcall().
  if (window.OPT_REMOTE)
    #Check for absolute urls
    JSONP.get(window.OPT_REMOTE+myurl.replace(/http:\/\/[^\/]+/,''), {embedding:'true', category_id: window.opt_category_id}, (data) ->
      $(element_name).html(data)
      fn() if (fn)
    )
  else
    $(element_name).load(myurl, fn)

#/* The ajax handler takes data from the ajax call and inserts the data into the #main part and then the #filtering part. */
ajaxhandler = (data) ->
  clear_loading()
  if (rdr = /\[REDIRECT\](.*)/.exec(data))
    window.location.replace(rdr[1])
  else
    parts = data.split('[BRK]')
    IEwrapper_pre = "<!--[if lte IE 6]>
    <div id='IE' class='ie6 ie67 ie678'>
    <![endif]-->
    <!--[if IE 7]>
    <div id='IE' class='ie7 ie67 ie678'>
    <![endif]-->
    <!--[if IE 8]>
    <div id='IE' class='ie8 ie678'>
    <![endif]-->
    <!--[if gte IE 9]>
    <div id='IE'>
    <![endif]-->"
    IEwrapper_post = "<!--[if IE]>
    </div>
    <![endif]-->"
    if parts.length == 4
      #Initial landing page
      #Create dynamic/static divs in content
      $('#optemo_content').empty().append("<div></div><div>"+parts.pop()+"</div>")
    
    # Because of the pop() call above, if the length was 4, it's 3 now (so this code gets executed too)
    if parts.length == 3
      $('#optemo_topbar').addClass("optemo").empty().append(IEwrapper_pre + parts[0] + IEwrapper_post)
      $('#optemo_filter').addClass("optemo").empty().append(IEwrapper_pre + parts[1] + IEwrapper_post)
      $('#optemo_content').addClass("optemo").find('div:first').empty().append(IEwrapper_pre + parts[2] + IEwrapper_post)
      # These lines are for the static content that is now in a separate div (opt_outsidecontainer, opt_silkscreen)
      temp_node = $('#optemo_content').children().eq(1)
      temp_node.html(IEwrapper_pre + temp_node.html() + IEwrapper_post)
      opt.whenDOMready()
      return 0

clear_loading = ->
  if opt.loading_indicator_state?
    opt.loading_indicator_state.disable = false
    clearTimeout(opt.loading_indicator_state.spinner_timer) # clearTimeout can run on "null" without error
    opt.stop_spinner()
    clearTimeout(opt.loading_indicator_state.socket_error_timer) # We need to clear the timeout error here
    opt.loading_indicator_state.spinner_timer = null
    opt.loading_indicator_state.socket_error_timer = null
    $('.jslider-pointer-disabled').each( ->
      $(this).removeClass('jslider-pointer-disabled')
    )
    
#Serialize an form into a hash, Warning: duplicate keys are dropped
$.fn.serializeObject = ->
  o = {}
  a = this.serializeArray()
  $.each(a, ->
  #So that multiple checkboxes don't get overwritten, if the value exists, turn it into an array
    if (o[this.name]?)
      o[this.name] = o[this.name] + "*" + this.value or ''
    else
      o[this.name] = this.value or ''
  )
  return o

#/* LiveInit functions */
$(".bb_quickview_close, #opt_silkscreen").live 'click', ->
  opt.removeSilkScreen()
  if (opt.lastpage?)
    #There was an error in the last request
    opt.ajaxcall("/", null, location.hash.replace(/^#/, ''))
    opt.lastpage = false

#Pagination links
$('.pagination a').live "click", ->
  if (opt.loading_indicator_state.disable) 
    return false
  opt.ajaxcall($(this).attr('href'), opt.build_ajax_data())
  return false

#See all Products
$('.seeall').live 'click', ->
  opt.ajaxcall('/', {})
  return false

# Change sort method
$('.sortby').live 'click', ->
  if (opt.loading_indicator_state.disable)
    return false
  opt.ajaxcall("/compare", opt.build_ajax_data({"sortby" : $(this).attr('data-feat')}))
  return false

#/* End of LiveInit Functions */
window.optemo_module = opt
