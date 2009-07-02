// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function fadeout(id)
{
	$('#fade').css('height', getDocHeight()+'px').css('display', 'inline');
	//IE Compatibility
	var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body
	var dsoctop=document.all? iebody.scrollTop : pageYOffset
	$('#info').css('left', ((document.body.clientWidth-800)/2)+'px')
		.css('top', (dsoctop+5)+'px')
		.css('display', 'inline');
	$('#myfilter_brand').css('visibility', 'hidden');
	$('#info').load('/products/show/'+id+'?plain=true');
}

function fadein()
{
	$('#myfilter_brand').css('visibility', 'visible');
	$('#fade').css('display', 'none');
	$('#info').css('display', 'none');	
}

// When you click the Save button:
function saveit(id)
{	
	//Check if this id has already been added.
	if(null != document.getElementById('c'+id)){
		$("#already_added_msg").attr("style","display:block");
	}else{
		// Update just the savebar_content div after doing get on /saveds/create/[id here].
		$.get('/saveds/create/'+id, function(data){ $(data).appendTo('#savebar_content');});
		$("#already_added_msg").attr("style","display:none");
	}
	
	// There should be at least 1 saved item, so...
	// 1. show compare button	
	$("#compare_button").attr("style","display:block");
	// 2. hide 'add stuff here' message
	$("#deleteme").attr("style","display:none");
	
}

// When you click the X on a saved product:
function remove(id)
{
	$.get('/saveds/destroy/'+id)
	$('#c'+id).remove();
	
	$("#already_added_msg").attr("style","display:none");
		
	if($('.saveditem').length == 0){
		$("#compare_button").attr("style","display:none");
		$("#deleteme").attr("style","display:block");
	}
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

$(document).ready(function() {
	// ToDo: Add code for table drag drop here
	
	$("#comparisonTable").tableDnD({
		onDragClass: "rowBeingDragged",
		onDrop: function(table, row){		
			newPreferencesString = $.tableDnD.serialize();
			// window.location = "/compare/list?" + newPrefString
		}
	});
			
	//Set up sliders
	$('.slider').each(function () {
		curmin = parseInt($(this).attr('data-startmin'));
		curmax = parseInt($(this).attr('data-startmax'));
		rangemin = parseInt($(this).attr('data-min'));
		rangemax = parseInt($(this).attr('data-max'));
		sessmin = parseInt($(this).attr('data-prodmin'));
		sessmax = parseInt($(this).attr('data-prodmax'));
		$(this).slider({
			range: false,
			min: rangemin,
			max: rangemax,
			values: [curmin,curmax],
			slide: function(e,ui) {
				if ($(this).attr('data-formatting') == '$')
				{
					min = Math.floor(ui.values[0]);
					max = Math.ceil(ui.values[1]);
				}
				else
				{
					min = Math.floor(ui.values[0]*10)/10;
					max = Math.ceil(ui.values[1]*10)/10;
				}
				$(this).siblings('.min').attr('value',min);
				$(this).siblings('.max').attr('value',max);
				$('.sliderlabel:first', this).html(min);
				$('.sliderlabel:last', this).html(max);
				},
			stop: 	function(e,ui) {
				$('#filter_form').submit();
				}
		});
		$('a:first', this).html('<div class="sliderlabel">'+curmin+'</div>')
		$('a:last', this).html('<div class="sliderlabel">'+curmax+'</div>')
		histogram($(this).siblings('.hist')[0],(sessmin-rangemin)/(rangemax-rangemin),(sessmax-rangemin)/(rangemax-rangemin));
	});
	
	$(".save").click(function() { 
		// product id of the chosen item
		itemId = $(this).attr('itemId');
		// product ids of all other items displayed
		var otherItems = new Array(8)
		i = 0;
		$(".save").each(function()
		{
			if($(this).attr('itemId') != itemId)
			{
				otherItems[i] = $(this).attr('itemId');
				i = i + 1;
			}
		});
		// The source field helps identify weight
		$.get('/products/buildrelations?source=saveit&itemId=' + itemId + '&otherItems=' + otherItems);
	});
	
	$(".usecase").click(function() { 
		name = $(this).attr('data-name');
		$.get('/products/select/'+name);
	});
	sum = 0.0
	$(".preferenceSlider").each(function() {
		prefVal = parseInt($(this).attr('pref-value'));
		$(this).slider({
			max: 100,
			min: 0,
			step: 1,
			// value: (Get value of preferences from session) 
			value: prefVal,
			start: function(e, ui)
			{
			},
			// On slide, update the value of the text displayed under handle 
			slide: function(e,ui)
			{
				$('.sliderlabel', this).html(" ");
			},
			// When stopped sliding, check for condition of sum of preferences <= 1
			stop: function(e,ui) 
			{	
				sum = 0
				$('.preferenceSlider').each(function(){
					sum = sum + $(this).slider('option', 'value');					
				})
				
				$('.preferenceSlider').each(function(){
					normValue = ($(this).slider('option', 'value')/sum);	// normValue is upto many decimal places
					$('.sliderlabel', this).html(normValue.toFixed(2));		// Display only upto 2 decimal places
					$(this).siblings('.prefValue').attr('value',normValue);
				})
				
				/*if (sum > 100)
				{
					autoValue = $(this).slider('option', 'value')-(sum-100);
					$(this).slider('option', 'value', autoValue);
					$('.sliderlabel', this).html(autoValue/100);		
					$(this).siblings('.prefValue').attr('value',autoValue/100);
					$('#preference_form').submit();
					return false;
				}
				else
				{
					$(this).siblings('.prefValue').attr('value',ui.value/100);
					$('#preference_form').submit();
				}*/				
			}
		});
		$('a', this).html('<div class="sliderlabel">' + prefVal/100 + '</div>')
	});
	
	$(".preferenceSliderVertical").each(function() {
		prefVal = parseInt($(this).attr('pref-value'));
		$(this).slider({
			orientation: 'vertical',
			max: 100,
			min: 0,
			step: 1,
			// value: (Get value of preferences from session) 
			value: prefVal,
		});
	});
	
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
});

//Draw slider histogram
function histogram(element,min,max) {
	var raw = $(element).attr('data-data');
	if (raw)
		var data = raw.split(',');
	else
		var data = [0.5,0.7,0.1,0,0.3,0.8,0.6,0.4,0.3,0.3];
	//Data is assumed to be 10 normalized elements in an array
	
	var peak = 10,
	trans = 4,
	step = peak + 2*trans,
	height = 20,
	length = 177,
	paper = Raphael(element,length,height),
	shapelayer = paper.group(),
	t = shapelayer.path({fill: Raphael.getColor(), opacity: 0.75});//Raphael.hsb2rgb(Math.abs(Math.sin(parseInt(element,36))),1,1).hex, opacity: 0.5});
	
	t.moveTo(0,height);
	for (var i = 0; i < data.length; i++)
	{
	t.cplineTo(i*step+trans,height*(1-Math.sqrt(data[i])),5);
	t.lineTo(i*step+trans+peak,height*(1-Math.sqrt(data[i])));	
	}
	t.cplineTo((data.length)*step,height,5);
	t.andClose();
	shapelayer.rect(0,0,min*length,height).attr({fill: "#dddddd", "stroke-opacity": 0});
	shapelayer.rect(max*length,0,length,height).attr({fill: '#dddddd', "stroke-opacity": 0});
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