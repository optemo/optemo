// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
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

function fadeout(url)
{
	//IE Compatibility
	var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body
	var dsoctop=document.all? iebody.scrollTop : pageYOffset
	$('#info').css('left', ((document.body.clientWidth-800)/2)+'px')
		.css('top', (dsoctop+5)+'px')
		.css('display', 'inline');
	$('#fade').css('height', getDocHeight()+'px').css('display', 'inline');
	$('#myfilter_brand').css('visibility', 'hidden');
	$('#info').css('width',800).css('height',770).load(url,loadOverlay);
}

function fadein()
{
	$('#myfilter_brand').css('visibility', 'visible');
	$('#fade').css('display', 'none');
	$('#info').css('display', 'none');	
}

function disableit(pid)
{
	name = pid.toString() + "_save";
	document[name].src = '/images/save_disabled.png';
	
}
function loadOverlay() {
	$('#requestsubmit').click(function(){
		$.post("/content/create_request",$("#requestform").serialize());
		$('#info').html("<h3><span style='color: green;'>Thank you for submitting your feedback.</span></h3><a href='javascript:fadein();' id='close'><img src='/images/close.gif'></a>").effect("scale",{percent: 20, scale: 'box'})//.css('width',400).css('height',100)
		return false;
	});
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
	// Tracking	
	try { piwikTracker.trackGoal(11)); } catch( err ) {}
	
	//Check if this id has already been added.
	if(null != document.getElementById('c'+id)){
		$("#already_added_msg").attr("style","display:block");
	}else{
		// Update just the savebar_content div after doing get on /saveds/create/[id here].
		$.get('/saveds/create/'+id, function(data){ 
			$(data).click(function() {
				savedProductRemoval($(".deleteX", this));
			}).appendTo('#savebar_content');
		});
		$("#already_added_msg").attr("style","display:none");
	}
	
	// There should be at least 1 saved item, so...
	// 1. show compare button	
	$("#compare_button").attr("style","display:block");
	// 2. hide 'add stuff here' message
	$("#deleteme").attr("style","display:none");
	
}

// Removed preference operations for size optimization
//function savedProductRemoval(obj)

// When you click the X on a saved product:
function remove(id)
{
	$.get('/saveds/destroy/'+id);
	$('#c'+id).remove();
	
	$("#already_added_msg").attr("style","display:none");
		
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
	$('#filter_form').submit();
}

function submitPreferences()
{
	$('#preference_form').submit();
}

// Removed preference operations for size optimization
// function buildOtherItemsArray(root, attr_name, itemId)

function submit_filter()
{
	// Tracking
	try { piwikTracker.trackGoal(13); } catch( err ) {}
	
	$('#filter_form').submit();
	spinner("myspinner", 11, 20, 9, 5, "#000");
	$('#loading').css('display', 'inline');
}

function closeDesc(id){
	$(id).siblings('.desc').css('display','none');
	$(id).click(openDesc(id));
	return false;
}

$(document).ready(function() {
	
	$("#comparisonTable").tableDnD({
		onDragClass: "rowBeingDragged",
		onDrop: function(table, row){		
			newPreferencesString = $.tableDnD.serialize();
			// window.location = "/compare/list?" + newPrefString
		}
	});
	
	//Fadeout labels
	$(".easylink, .productimg").click(function(){
		fadeout('/products/show/'+$(this).attr('data-id')+'?plain=true');
		return false;
	});
	
	//Request a feature
	$("#requestafeature").click(function(){
		fadeout('/content/request');
		return false;
	});
	//Show and Hide Descriptions
	$('.feature .label a, .feature .deleteX').click(function(){
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
	
	//Display loading spinner
	$('#myfilter_brand').change(function() {submit_filter();});
	
	//Set up sliders
	$('.slider').each(function() {
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
                if (ui.value == ui.values[0])
				{
					$(this).slider('values', 0, value);
					realselectmin = (parseFloat((ui.values[0]/100))*(rangemax-rangemin))+rangemin;	// The actual feature value corresponding to slider position
					if(itof == 'true')
						realselectmin = parseInt(realselectmin);
					else
						realselectmin = parseInt(realselectmin*10)/10;
					$('a:first', this).html(realselectmin).addClass("valbelow");
					// Set the form values that get submitted
					$(this).siblings('.min').attr('value',realselectmin);
					$(this).siblings('.max').attr('value',curmax);
                }
                else
				{
                    $(this).slider('values', 1, value);
					realselectmax = (parseFloat((ui.values[1]/100))*(rangemax-rangemin))+rangemin;
					if(itof == 'true')
						realselectmax = parseInt(realselectmax);
					else
						realselectmax = parseInt(realselectmax*10)/10;
					$('a:last', this).html(realselectmax).addClass("valabove");
					// Set the form values that get submitted
					$(this).siblings('.max').attr('value',realselectmax);
					$(this).siblings('.min').attr('value',curmin);
			     }	
               	return false;
            },
			stop: function(e,ui)
			{
				submit_filter();
			}
		});
		$(this).slider('values', 0, ((curmin-rangemin)/(rangemax-rangemin))*100);
		$('a:first', this).html(curmin).addClass("valbelow");
		$(this).slider('values', 1, ((curmax-rangemin)/(rangemax-rangemin))*100);
		$('a:last', this).html(curmax).addClass("valabove");
		if ((itof=='true' && (curmin>=curmax-1)) || (itof=='false' && curmin>=curmax-.1))	// Shade histogram if feature range is 1 for itof features and .1 for others
		{
			histogram($(this).siblings('.hist')[0], true);
		}
		else
		{
			histogram($(this).siblings('.hist')[0], false);
		}
	});
	
// Removed preference operations for speed-up
/*	$(".deleteX").click(function() {
	$(".simlinks").click(function() {
	$(".save").click(function() { 
*/
	
	$(".usecase").click(function() { 
		name = $(this).attr('data-name');
		$.get('/products/select/'+name,function() {window.location = $(".usecase").attr('href');});
		return false;
	});

// Removed preference sliders for size optimization
/*	$(".preferenceSlider").each(function() {
	$(".preferenceSliderVertical").each(function() {
*/	
	//Draw cluster graphs
	$('.clustergraph').each(function () {
		Raphael.getColor.reset();
		$(this).children().each(function () {
			max = parseFloat($(this).parent().css('width'), 10);
			margin = parseFloat($(this).attr('data-left')) * max;
			width = $(this).attr('data-width') * max;
			$(this).css('margin-left', margin+'px');
			$(this).css('width', width+'px');
			$(this).css('background-color', Raphael.getColor());
		});
	});
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
					
	// Piwik
	try {
	var piwikTracker = Piwik.getTracker("http://pj.laserprinterhub.com/piwik.php", 1);
	piwikTracker.trackPageView();
	piwikTracker.enableLinkTracking();
	} 
	catch( err ) {}
	
});

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
	length = 168,
	shapelayer = Raphael(element,length,height),
	h = height - 1;
	if(norange==true)	// i.e if left slider and right slider are the same value
	{
		t = shapelayer.path({fill: 'gray', opacity: 0.30});
		Raphael.getColor(); //Don't want to mess up the color rotation
	}
	else
		t = shapelayer.path({fill: Raphael.getColor(), opacity: 0.75});
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

function clickOnlyIfSomethingSelected(){
	//TODO
	
	if (true) {};
	return;
}
}