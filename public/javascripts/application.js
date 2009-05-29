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

function saveit(id)
{
	if ($('#deleteme')){$('#deleteme').remove()};
	$.get('/saveds/create/'+id,function(data){$(data).appendTo('#savebar_content');});
}

function remove(id)
{
	$.get('/saveds/destroy/'+id)
	$('#c'+id).remove();
}

function removeBrand(str)
{
	$('#myfilter_Xbrand').attr('value', str);
	$('#filter_form').submit();
}


$(document).ready(function() {
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
					dispstr = "$"+min+"-$"+max;
				}
				else
				{
					min = Math.floor(ui.values[0]*10)/10;
					max = Math.ceil(ui.values[1]*10)/10;
					//dispstr = ($(filter_min).value.indexOf('.') == -1 ? $(filter_min).value+".0" : $(filter_min).value) +"-"+($(filter_max).value.indexOf('.') == -1 ? $(filter_max).value+".0" : $(filter_max).value)+" "+label;
					dispstr = min+"-"+max;
				}
				$(this).siblings('.disp').html(dispstr);
				$(this).siblings('.min').attr('value',min);
				$(this).siblings('.max').attr('value',max);
				},
			stop: 	function(e,ui) {
				$('#filter_form').submit();
				}
		});
		histogram($(this).siblings('.hist')[0],(sessmin-rangemin)/(rangemax-rangemin),(sessmax-rangemin)/(rangemax-rangemin));
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


/*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
function getDocHeight() {
    var D = document;
    return Math.max(
        Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
        Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
        Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    );
}