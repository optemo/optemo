// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var language;
function findBetter(id, feat)
{
       // Check if better product exists for that feature using /compare/better Rails me
       // Query.get( url, [data], [callback], [type] )
       $.get("/compare/better?original=" + id + "&feature=" + feat, 
               function(data){
                       if (data == "-1")
                       {
                               $('#betternotfoundmsg').css('visibility', 'visible');
                       }
                       else
                       {
                               // found better printer (with id stored in data)
                               window.location = "/compare/index/" + id + "-" + data;
                       }
               }, "text");
}

function fadeout(url,data,width,height)
{
	//IE Compatibility
	var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body
	var dsoctop=document.all? iebody.scrollTop : pageYOffset
	$('#info').html("");
	$('#outsidecontainer').css('left', ((document.body.clientWidth-(width||800))/2)+'px')
		.css('top', (dsoctop+5)+'px').css('width',width||800).css('height',height||770)
		.css('display', 'inline');
	$('#fade').css('height', getDocHeight()+'px').css('display', 'inline');
	$('#selector').css('visibility', 'hidden');
	if (data)
		$('#info').html(data);
	else
		$('#info').load(url,function(){DBinit('#info');});	
}

function fadein()
{
	$('#selector').css('visibility', 'visible');
	$('#fade').css('display', 'none');
	$('#outsidecontainer').css('display', 'none');	
}

function disableit(pid)
{
	name = pid.toString() + "_save";
	document[name].src = '/images/save_disabled.png';
	
}

function spinner(holderid, R1, R2, count, stroke_width, colour) {
                var sectorsCount = count || 12,
                    color = colour || "#fff",
                    width = stroke_width || 15,
                    r1 = Math.min(R1, R2) || 35,
                    r2 = Math.max(R1, R2) || 60,
                    cx = r2 + width,
                    cy = r2 + width,
                    r = Raphael(holderid, r2 * 2 + width * 2, r2 * 2 + width * 2),
                    
                    sectors = [],
                    opacity = [],
                    beta = 2 * Math.PI / sectorsCount,

                    pathParams = {stroke: color, "stroke-width": width, "stroke-linecap": "round"};
                    Raphael.getColor.reset();
                for (var i = 0; i < sectorsCount; i++) {
                    var alpha = beta * i - Math.PI / 2,
                        cos = Math.cos(alpha),
                        sin = Math.sin(alpha);
                    opacity[i] = 1 / sectorsCount * i;
                    sectors[i] = r.path(pathParams)
                                    .moveTo(cx + r1 * cos, cy + r1 * sin)
                                    .lineTo(cx + r2 * cos, cy + r2 * sin);
                    if (color == "rainbow") {
                        sectors[i].attr("stroke", Raphael.getColor());
                    }
                }
                var tick;
                (function ticker() {
                    opacity.unshift(opacity.pop());
                    for (var i = 0; i < sectorsCount; i++) {
                        sectors[i].attr("opacity", opacity[i]);
                    }
                    r.safari();
                    tick = setTimeout(ticker, 1000 / sectorsCount);
                })();
                return function () {
                    clearTimeout(tick);
                    r.remove();
                };
            }

			// When you click the Save button:
			function saveit(id)
			{	
				if($(".saveditem").length == 4)
				{
					$("#too_many_saved").attr("style","display:block");
				}
				else
				{
				//Check if this id has already been added.
				if(null != document.getElementById('c'+id)){
					$("#already_added_msg").attr("style","display:block");
				}else{
					trackPage('goals/save/'+id);
					// Create an empty slot for product
					$('#savedproducts').append("<div class='saveditem' id='c" + id + "'> </div>");
					// Update just the savebar_content div after doing get on /saveds/create/[id here].
					$.get('/saveds/create/'+id + "?ajax=true", function(data){
						$(data).appendTo('#c'+id);
						//Load JS for item
						DBinit("#c"+id);
					});
					$("#already_added_msg").attr("style","display:none");
					$("#too_many_saved").attr("style","display:none");	
				}

				// There should be at least 1 saved item, so...
				// 1. show compare button	
				$("#compare_button").attr("style","display:block");
				// 2. hide 'add stuff here' message
				$("#deleteme").attr("style","display:none");
				}
			}
// Removed preference operations for size optimization
//function savedProductRemoval(obj)

// When you click the X on a saved product:
function remove(id)
{
	$.get('/saveds/destroy/'+id);
	$('#c'+id).remove();
	
	$("#already_added_msg").attr("style","display:none");
	$("#too_many_saved").attr("style","display:none");
		
	if($('.saveditem').length == 0){
		$("#compare_button").attr("style","display:none");
		$("#deleteme").attr("style","display:block");
	}
}

function removeFromComparison(id)
{
// Removed preference operations for speed-up
	remove(id);
	window.location.href = "/compare";
}

function removeBrand(str)
{
	$('#myfilter_Xbrand').attr('value', str);
	ajaxcall("/products/filter", $("#filter_form").serialize());
}

function submitPreferences()
{
	$('#preference_form').submit();
}

// Removed preference operations for size optimization
// function buildOtherItemsArray(root, attr_name, itemId)

function showspinner()
{
	$('#loading').css('display', 'inline');
}
function hidespinner()
{
	$('#loading').css('display', 'none');
}

//add an item to a list
function additem(newitem, items)
{
	if (items == "")
		return newitem;
	//var re = new RegExp('(^|\*)'+newitem+'(\*|$)');
	//if (re.test(items) == false)
		return items+"*"+newitem;
}

//Remove an item from a list
function removeitem(rem, items)
{
	i = items.split('*');
	i.splice(i.indexOf(rem),1);
	return i.join("*");
}

function closeDesc(id){
	$(id).siblings('.desc').css('display','none');
	$(id).click(openDesc(id));
	return false;
}
function submitCategorical(){
	ajaxcall("/products/filter", $("#filter_form").serialize());
	trackPage('goals/filter/autosubmit');
}

function flashError(str)
{
	var errtype = 'other';
	
	if (/search/.test(str)==true)
	{
	  errtype = "search";
	  $('#search').attr('value',"");
	}
	else
	 	if (/filter/.test(str)==true)
	 	{
	  		errtype = "filters";
	  	}
	trackPage('error/'+errtype);
	hidespinner();
	fadeout(null,str,600,100);
}
function submitsearch() {
	var searchinfo = { 'search_text' : $("#search_form input#search").attr('value'), 'optemo_session': parseInt($('#seshid').attr('session-id')) };
	piwikTracker2.setCustomData(searchinfo);
	trackPage('goals/search');
	piwikTracker2.setCustomData({});
	ajaxcall("/products/find?ajax=true", $("#search_form").serialize(), true);
	return false;
}

function ajaxcall(myurl,mydata,isSearch) {
	showspinner();
	$.ajax({
		type: (mydata==null)?"GET":"POST",
		data: (mydata==null)?"":mydata,
		url: myurl,
		success: ajaxhandler,
		error: function(){
			//if (language=="fr")
			//	flashError('<div class="poptitle">&nbsp;</div><p class="error">Désolé! Une erreur s’est produite sur le serveur.</p><p>Vous pouvez <a href="" class="ajaxlink popuplink">réinitialiser</a> l’outil et constater si le problème persiste.</p>');
			//else
				flashError('<div class="poptitle">&nbsp;</div><p class="error">Sorry! An error has occured on the server.</p><p>You can <a href="" class="ajaxlink popuplink">reset</a> the tool and see if the problem is resolved.</p>');
			}
	});
}

function ajaxhandler(data)
{
	if (data.indexOf('[ERR]') != -1)
	{	
		var parts = data.split('[BRK]');
		
		if (parts[1] != null)
		{
			$('#ajaxfilter').html(parts[1]);
			DBinit('#ajaxfilter');
		}
		flashError(parts[0].substr(5,parts[0].length));
		return -1;
	}
	else
	{
		var parts = data.split('[BRK]');
		$('#ajaxfilter').html(parts[0]);
		$('#main').html(parts[1]);
		$('#search').attr('value',parts[2]);
		hidespinner();
		DBinit();
		return 0;
	}
}

function trackPage(str){
	try { 
		piwikTracker.setDocumentTitle(str);
		piwikTracker.trackPageView();
		piwikTracker2.setDocumentTitle(str);
		piwikTracker2.trackPageView();
		piwikTracker2.setDocumentTitle('');
	} catch( err ) {}
}

function trackCategorical(name, val, type){
	var info = {'slider_min' : val, 'slider_max' : val, 'slider_name' : name, 'optemo_session': parseInt($('#seshid').attr('session-id')), 'filter_type' : type };
	piwikTracker2.setCustomData(info);
	piwikTracker2.trackPageView();
	piwikTracker2.setCustomData({});
}


function DBinit(context) {
	
	$("#comparisonTable").tableDnD({
		onDragClass: "rowBeingDragged",
		onDrop: function(table, row){		
			newPreferencesString = $.tableDnD.serialize();
			// window.location = "/compare/list?" + newPrefString
		}
	});
	
	//Fadeout labels
	$(".easylink, .productimg",context).click(function(){
		fadeout('/products/show/'+$(this).attr('data-id')+'?plain=true',null, 800, 800);/*Star-h:700*/
		trackPage('products/show/'+$(this).attr('data-id')); 
		//trackPage($(this).attr('href'));
		return false;
	});
	
	//Show and Hide Descriptions
	$('.feature .label a, .feature .deleteX',context).click(function(){
		if($(this).parent().attr('class') == "desc")
			{var obj = $(this).parent();}
		else
			{var obj = $(this).siblings('.desc');}
		var flip=parseInt(obj.attr('name-flip'));
		if (isNaN(flip)){flip = 0;}
		obj.toggle(flip++ % 2 == 0);
		obj.attr('name-flip',flip);
		return false;
	});
	
	//Show Additional Features
	$('#morefilters').click(function(){
		$('.extra').show("slide",{direction: "up"},100);
		$(this).css('display','none');
		$('#lessfilters').css('display','block');
		return false;
	});
	
	//Hide Additional Features
	$('#lessfilters').click(function(){
		$('.extra').hide("slide",{direction: "up"},100);
		$(this).css('display','none');
		$('#morefilters').css('display','block');
		return false;
	});
	
	// Sliders -- submit
	$('.autosubmit',context).change(function() {
		submitCategorical();
	});
	
	// Checkboxes -- submit
	$('.autosubmitbool',context).click(function() {
		var whichbox = $(this).attr('id');
		var box_value = $(this).attr('checked') ? 100 : 0;
		submitCategorical();
		trackCategorical(whichbox, box_value, 3);
	});
	
	// Add a brand -- submit
	// Handle brand spinner
	$('#selector',context).change(function(){
		var whichbrand = $(this).val();
		$('#myfilter_brand').val(additem(whichbrand,$('#myfilter_brand').val()));
		submitCategorical();
		trackCategorical(whichbrand,100,2);
	});
	
	// Remove a brand -- submit
	// Handle brand spinner
	$('.removeBrand',context).click(function(){
		var whichbrand = $(this).attr('data-id');
		$('#myfilter_brand').val(removeitem(whichbrand,$('#myfilter_brand').val()));
		submitCategorical();
		trackCategorical(whichbrand,0,2);
		return false;
	});
	
	//Ajax call for simlinks
	$('.simlinks, .productlink',context).click(function(){ 
		ajaxcall($(this).attr('href')+'?ajax=true');
		
		linkinfo = {'product_picked' : $(this).attr('data-id') , 'optemo_session': parseInt($('#seshid').attr('session-id'))};
		morestuff = getAllShownProductIds(); 
		linkinfo['product_ignored'] = morestuff;
		piwikTracker2.setCustomData(linkinfo);
		trackPage('goals/browse');
		piwikTracker2.setCustomData({});
		return false;
	});
	
	$('.ajaxlink',context).click(function(){
		ajaxcall($(this).attr('href')+'?ajax=true');
		return false;
	});
	
	//Link from popup
	$('.popuplink', context).click(function(){
		fadein();
		return false;
	});
	
	//Remove buttons on compare
	$('.remove', context).click(function(){
		remove($(this).attr('data-name'));
		$(this).parents('.column').remove();
		return false;
	});
	
	$('.buylink, .buyimg', context).click(function(){
		var buyme_id = $(this).attr('product');
		trackPage('goals/addtocart/'+buyme_id);
	});
	
	$('#yesdecisionsubmit', context).click(function(){
		trackPage('survey/yes');
		fadeout('/survey/index', null, 600, 835);
		return false;
	});

	$('#nodecisionsubmit', context).click(function(){
		fadein();
		trackPage('survey/no');
		return false;
	});
	
	$('#surveysubmit', context).click(function(){
		trackPage('survey/submit');
		$('#feedback').css('display','none');
		fadeout('/survey/submit?' + $("#surveyform").serialize(), null, 300, 70);
		return false;
	});
	
	//Set up sliders
	$('.slider',context).each(function() {
		threshold = 20;							// The parameter that identifies that 2 sliders are too close to each other
		itof = $(this).attr('data-itof');
		if(itof == 'false')
		{
			curmin = parseFloat($(this).attr('data-startmin'));
			curmax = parseFloat($(this).attr('data-startmax'));
			rangemin = parseFloat($(this).attr('data-min'));
			rangemax = parseFloat($(this).attr('data-max'));
		}
		else
		{
			curmin = parseInt($(this).attr('data-startmin'));
			curmax = parseInt($(this).attr('data-startmax'));
			rangemin = parseInt($(this).attr('data-min'));
			rangemax = parseInt($(this).attr('data-max'));
		}
		$(this).slider({
			orientation: 'horizontal',
	        range: true,
	        min: 0,
	        max: 100,
	        values: [((curmin-rangemin)/(rangemax-rangemin))*100,((curmax-rangemin)/(rangemax-rangemin))*100],
			start: function(event, ui) {
				// At the start of sliding, if the two sliders are very close by, then push the value on other slider to the bottom
				itof = $(this).attr('data-itof');
				if(itof == 'false')
				{
					curmin = parseFloat($(this).attr('data-startmin'));
					curmax = parseFloat($(this).attr('data-startmax'));
				}
				else
				{
					curmin = parseInt($(this).attr('data-startmin'));
					curmax = parseInt($(this).attr('data-startmax'));
				}
				var diff = ui.values[1] - ui.values[0];
				if (diff < threshold)
				{
					if(ui.value == ui.values[0])	// Left slider
					{
						$('a:last', this).html(curmax).removeClass("valabove").addClass("valbelow");
						$('a:first', this).html(curmin).addClass("valabove");						
					}
					else
					{
						$('a:first', this).html(curmin).removeClass("valabove").addClass("valbelow");
						$('a:last', this).html(curmax).addClass("valabove");												
					}
				}
			},
			slide: function(event, ui) {
				itof = $(this).attr('data-itof');
				if(itof == 'false')
				{
					curmin = parseFloat($(this).attr('data-startmin'));
					curmax = parseFloat($(this).attr('data-startmax'));
					rangemin = parseFloat($(this).attr('data-min'));
					rangemax = parseFloat($(this).attr('data-max'));
				}
				else
				{
					curmin = parseInt($(this).attr('data-startmin'));
					curmax = parseInt($(this).attr('data-startmax'));
					rangemin = parseInt($(this).attr('data-min'));
					rangemax = parseInt($(this).attr('data-max'));
				}
				var min = 0;
				var max = 100;
				var realselectmin, realselectmax;
				var value = ui.value;
				var sliderno = -1;
				if(ui.value == ui.values[0])
					sliderno = 0;
				else
					sliderno = 1;
				$(this).slider('values', sliderno, value);
				realvalue = (parseFloat((ui.values[sliderno]/100))*(rangemax-rangemin))+rangemin;
				if(itof == 'true')
					realvalue = parseInt(realvalue);
				else
					realvalue = parseInt(realvalue*10)/10;
				if (sliderno == 0 && ui.values[0] != ui.values[1])						// First slider is not identified correctly by sliderno for the case
					$('a:first', this).html(realvalue).addClass("valabove");			// when rightslider = left slider, hence the second condition
				else if (ui.values[0] != ui.values[1])
					$('a:last', this).html(realvalue).addClass("valabove");
					
				if(sliderno == 0)
				{
					$(this).siblings('.min').attr('value',realvalue);
					$(this).siblings('.max').attr('value',curmax);
				}
				else
				{
					$(this).siblings('.min').attr('value',curmin);
					$(this).siblings('.max').attr('value',realvalue);
				}
					
			   	return false;
	        },
			stop: function(e,ui)
			{
				var diff = ui.values[1] - ui.values[0];
				if (diff > threshold)
				{
					$('a:first', this).removeClass("valabove").addClass("valbelow");
					$('a:last', this).removeClass("valabove").addClass("valbelow");
				}
				var sliderinfo = {'slider_min' : parseFloat(ui.values[0]), 'slider_max' : parseFloat(ui.values[1]), 'slider_name' : $(this).attr('data-label'), 'optemo_session': parseInt($('#seshid').attr('session-id')), 'filter_type' : 1 };
				piwikTracker2.setCustomData(sliderinfo);
				trackPage('goals/filter/sliders');
				piwikTracker2.setCustomData({});
				ajaxcall("/products/filter", $("#filter_form").serialize());
			}
		});
		$(this).slider('values', 0, ((curmin-rangemin)/(rangemax-rangemin))*100);
		$('a:first', this).html(curmin).addClass("valbelow");
		$(this).slider('values', 1, ((curmax-rangemin)/(rangemax-rangemin))*100);
		var diff = $(this).slider('values', 1) - $(this).slider('values', 0);
		$('a:last', this).html(curmax).addClass("valbelow");
		if (diff < threshold)
			$('a:last', this).html(curmax).addClass("valabove");
		histogram($(this).siblings('.hist')[0]);
	});
}
	
	$(".usecase").click(function() { 
		name = $(this).attr('data-name');
		$.get('/products/select/'+name,function() {window.location = $(".usecase").attr('href');});
		return false;
	});
	
$(document).ready(function() {
	DBinit();
	
	//Find product language
	language = (/^\s*English/.test($(".languageoptions:first").html())==true)?'en':'fr';

// Removed preference sliders for size optimization
/*	$(".preferenceSlider").each(function() {
	$(".preferenceSliderVertical").each(function() {
*/	

	//Decrypt encrypted links
	$('a.decrypt').each(function () {
		$(this).attr('href',$(this).attr('href').replace(/[a-zA-Z]/g, function(c){
			return String.fromCharCode((c<="Z"?90:122)>=(c=c.charCodeAt(0)+13)?c:c-26);
			}));
	});
	//Do rollover effect
	$('#logo').hover(function(){$('#logo > span').css('visibility', 'visible')},
					 function(){$('#logo > span').css('visibility', 'hidden')});
	$('#whylaser').hover(function(){$('#whylaser > span').css('visibility', 'visible')},
					 function(){$('#whylaser > span').css('visibility', 'hidden')});
	//Fadein
	$(".close").click(function(){
		fadein();
		return false;
	});
    
	//Call overlay for product comparison
	$("#compare_button").click(function(){
		fadeout('/compare/',null, 900, 530);/*star-h:580*/
		trackPage('goals/compare/');
		return false;
	});
    
	//Request a feature
	$("#requestafeature").click(function(){
		fadeout('/content/request');
		return false;
	});
    
	//Static Ajax call
	$('.staticajax').click(function(){
		ajaxcall($(this).attr('href')+'?ajax=true');
		return false;
	});
    
	//Search submit
	$('#submit_button').click(function(){
		return submitsearch();
	});
	//Search submit
	$('#search').keypress(function (e) {
		if (e.which==13)
			return submitsearch();
	});
    
	//Static feedback box
	$('#feedback').click(function(){
		trackPage('survey/feedback');
		fadeout('/survey/index', null, 600, 300);
		return false;
	});
	
	spinner("myspinner", 11, 20, 9, 5, "#000");
	
});

function getAllShownProductIds(){
	var currentIds = "";
	$('.easylink').each(function(i){
		currentIds += $(this).attr('data-id') + ',';
	});
	return currentIds;
}

//Draw slider histogram
function histogram(element, norange) {
	var raw = $(element).attr('data-data');
	if (raw)
		var data = raw.split(',');
	else
		var data = [0.5,0.7,0.1,0,0.3,0.8,0.6,0.4,0.3,0.3];
	//Data is assumed to be 10 normalized elements in an array
	var peak = 0,
	trans = 4,
	step = peak + 2*trans,
	height = 20,
	length = 174,
	shapelayer = Raphael(element,length,height),
	h = height - 1;
	t = shapelayer.path({fill: "#bad0f2", stroke: "#039", opacity: 0.75});
	t.moveTo(0,height);

	init = 4;
	for (var i = 0; i < data.length; i++)
	{
	t.cplineTo(init+i*step+trans,h*(1-data[i])+1,5);
	t.lineTo(init+i*step+trans+peak,h*(1-data[i])+1);	
	//shapelayer.text(i*step+trans+5, height*0.5, i);
	}
	t.cplineTo(init+(data.length)*step+4,height,5);
	t.andClose();
}

/* http://snipplr.com/view/1696/get-elements-by-class-name/ */
function getElementsByClassName(classname, node) {
   if(!node) node = document.getElementsByTagName("body")[0];
   var a = [];
   var re = new RegExp('\\b' + classname + '\\b');
   var els = node.getElementsByTagName("*");
   for(var i=0,j=els.length; i<j; i++)
   		if(re.test(els[i].className))a.push(els[i]);
   return a;
  }

/*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
function getDocHeight() {
    var D = document;
    return Math.max(
        Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
        Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
        Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    );
}