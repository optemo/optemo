/* Application-specific Javascript. 
   If you add a function and don't add it to the table of contents, prepare to be punished by your god of choice.
 
   ---- UI Manipulation ----
   fadein()
   fadeout(url, data, width, height)  -  Puts up fading boxes
   saveProductForComparison(id, imgurl, name)  -  Puts comparison items in #savebar_content and stores them in a cookie
   renderComparisonProducts(id, imgurl, name)  -  Does actual insertion of UI elements
   removeFromComparison(id)  -  Removes comparison items from #savebar_content
   removeBrand(str)  
   submitCategorical()
   submitsearch()
   histogram(element, norange)  -  draws histogram

   ---- Data Manipulation ----
   findBetter(id, feat) - Checks if a better product exists for that feature. PROBABLY DEPRECATED
  
   ---- Piwik Tracking Functions ----
   trackPage(str)  -  Piwik tracking per page
   trackCategorical(name, val, type)  -  Piwik tracking per category
 
   ---- Discover Browser Initialization ----
   DBinit(context)  -  Does context-based refresh and initialization routines for many UI elements.
 
   ---- document.ready() ----
   document.ready()  -  The jquery call that gets everything started.

*/

var language;
// The following is pulled from optemo.html.erb, which in turn checks GlobalDeclarations.rb
var IS_DRAG_DROP_ENABLED = ($("#dragDropEnabled").html() === 'true');

//--------------------------------------//
//           UI Manipulation            //
//--------------------------------------//

function fadein()
{
	$('#selector').css('visibility', 'visible');
	$('#fade').css('display', 'none');
	$('#outsidecontainer').css('display', 'none');	
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

// When you click the Save button:
function saveProductForComparison(id, imgurl, name)
{	
	if($(".saveditem").length == 4)
	{
		$("#too_many_saved").css("display", "block");
	}
	else
	{
	//Check if this id has already been added.
	if(null != document.getElementById('c'+id)){
		$("#already_added_msg").css("display", "block");
	} else {
		trackPage('goals/save/'+id);
		renderComparisonProducts(id, imgurl, name);
		addValueToCookie('savedProductIDs', [id, imgurl, name]);
	}

	// There should be at least 1 saved item, so...
	// 1. show compare button	
	$("#compare_button").css("display", "block");
	// 2. hide 'add stuff here' message
	$("#deleteme").css("display", "none");
	}
}

function renderComparisonProducts(id, imgurl, name)
{
	// Create an empty slot for product
	$('#savedproducts').append("<div class='saveditem' id='c" + id + "'> </div>");

	// The best is to just leave the medium URL in place, because that image is already loaded in case of comparison, the common case.
	// For the uncommon case of page reload, it's fine to load a larger image.
	//	imgurl.replace(/_m/g, "_s")
	smallProductImageAndDetail = "<img class=\"productimg\" width=\"45\" height=\"50\" src=" + 
	//"/images/printers/"+id+"_s.jpg?1260303451" + 
	imgurl +
	" data-id=\""+id+"\" alt=\""+id+"_s\"/>" + 
	"<div class=\"smalldesc\">" +
	"<a class=\"easylink\" data-id=\""+id+"\" href=\"#\">"+
	((name) ? getShortProductName(name) : 0) +
	//Zevtor +
	"</a></div>" + 
	"<a class=\"deleteX\" data-name=\""+id+"\" href=\"javascript:removeFromComparison("+id+")\">" + 
	"<img src=\"/images/close.png\" alt=\"Close\"/></a>"; // do we need '?1258398853' ? I doubt it.

	$(smallProductImageAndDetail).appendTo('#c'+id);
	DBinit("#c"+id)

	$("#already_added_msg").css("display", "none");
	$("#too_many_saved").css("display", "none");
}

// When you click the X on a saved product:
function removeFromComparison(id)
{
	$('#c'+id).remove();
	
	$("#already_added_msg").css("display", "none");
	$("#too_many_saved").css("display", "none");
	
	removeValueFromCookie('savedProductIDs', id);
	if($('.saveditem').length == 0){
		$("#compare_button").css("display", "none");
		$("#deleteme").css("display", "block");
	}
}

function removeBrand(str)
{
	$('#myfilter_Xbrand').attr('value', str);
	ajaxcall("/products/filter", $("#filter_form").serialize());
}

function submitCategorical(){
	ajaxcall("/products/filter", $("#filter_form").serialize());
	trackPage('goals/filter/autosubmit');
}

function submitsearch() {
	var searchinfo = { 'search_text' : $("#search_form input#search").attr('value'), 'optemo_session': parseInt($('#seshid').attr('session-id')) };
	piwikTracker2.setCustomData(searchinfo);
	trackPage('goals/search');
	piwikTracker2.setCustomData({});
	ajaxcall("/products/find?ajax=true", $("#search_form").serialize(), true);
	return false;
}

// Draw slider histogram, called for each slider above
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

//--------------------------------------//
//          Data Manipulation           //
//--------------------------------------//

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

//--------------------------------------//
//       Piwik Tracking Functions       //
//--------------------------------------//

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

//--------------------------------------//
//   Discover Browser Initialization    //
//--------------------------------------//

function DBinit(context) {
	
	$("#comparisonTable").tableDnD({
		onDragClass: "rowBeingDragged",
		onDrop: function(table, row){		
			newPreferencesString = $.tableDnD.serialize();
			// window.location = "/compare/list?" + newPrefString
		}
	});
	
	// With the image getting cloned for drag and drop, it's fine to keep the click handler.
	// But it's important to check that $(".productimg") actually exists, for cases of images being missing.
	if ($(".productimg").length)
	{
		$(".productimg",context).click(function (){
			fadeout('/products/show/'+$(this).attr('data-id')+'?plain=true',null, 800, 800);/*Star-h:700*/
			trackPage('products/show/'+$(this).attr('data-id')); 
			// As far as I can tell, the following line is deprecated. ZAT Dec 2009
			//trackPage($(this).attr('href'));
			return false;
		});
	}
	
	if (IS_DRAG_DROP_ENABLED)
	{
		// Make item boxes draggable. This is a jquery UI builtin.		
		$(".image_boundingbox").each(function() {
			$(this).draggable({ 
				revert:true, 
				cursor:"move", 
				// The following defines the drag distance before a "drag" event is actually initiated. Helps for people who click while the mouse is slightly moving.
				distance:5,
				helper: 'clone',
				start: function(e, ui) { $(ui.helper).addClass('moving_box_ghost'); }
			});
            $(this).hover(function() {
	                $(this).find('.dragHand').stop().animate({ opacity: 1.0 }, 150);
					$(this).addClass('productimgborder');
			    },
		        function() {
	            	$(this).find('.dragHand').stop().animate({ opacity: 0.35 }, 450);
					$(this).removeClass('productimgborder');
           });
	    });
	
		// Make savebar area droppable. jquery UI builtin.
		$("#savebar").each(function() {
			$(this).droppable({ 
				hoverClass: 'drop-box-hover',
				activeClass: 'ui-state-dragging', 
				accept: ".image_boundingbox",
				drop: function (e, ui) {
					imgObj = $(ui.helper).find('.productimg')
					saveProductForComparison(imgObj.attr('data-id'), imgObj.attr('src'), imgObj.attr('alt'));
				}
			 });
		});
	}
	
	// However, always add it to the link below the image.
	$(".easylink",context).click(function() {
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
		$('#myfilter_brand').val(appendStringWithToken($('#myfilter_brand').val(), whichbrand, '*'));
		submitCategorical();
		trackCategorical(whichbrand,100,2);
	});
	
	// Remove a brand -- submit
	// Handle brand spinner
	$('.removeBrand',context).click(function(){
		var whichbrand = $(this).attr('data-id');
		$('#myfilter_brand').val(removeStringWithToken($('#myfilter_brand').val(), whichbrand, '*'));
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
		removeFromComparison($(this).attr('data-name'));
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
	
	// Set up sliders
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

	// Set up the next image to the right

/*   This image cycling code skeleton is probably not useful now.

	$('.right_arrow_bounding_box').each(function(){
		 $(this).hover(function() {
	                $(this).stop().animate({ opacity: 1.0 }, 150);
			    },
		        function() {
	            	$(this).stop().animate({ opacity: 0.35 }, 450);
        });
		$(this).click(function() {
			// 0. Slide old image off to the left.
			// 1. Animate the next image coming to the left. It should already be loaded at this point.
			// 2. Change the back image
			// 3. Turn off the front image
			// 4. Reset its position
			// 5. Reload the next click handler and image
			//   5a. Chances are, the click handler on the right arrow is no longer on... ?
			 
		})
	}); */
}

//--------------------------------------//
//          document.ready()            //
//--------------------------------------//

$(document).ready(function() {
	DBinit();
	
	//Find product language
	language = (/^\s*English/.test($(".languageoptions:first").html())==true)?'en':'fr';

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
		var productIDs = '';
		// For each saved product, get the ID out of the id=#savedproducts children.
		$('#savedproducts').children().each(function() {
			// it's a saved item if the CSS class is set as such. This allows for other children later if we feel like it.
			if ($(this).attr('class').indexOf('saveditem') != -1) 
			{
				// Build a list of product IDs to send to the AJAX call
				productIDs = productIDs + $(this).attr('id').substring(1) + ',';
			}
		});
		fadeout('/compare/index/' + productIDs, null, 900, 530);/*star-h:580*/
		trackPage('goals/compare/');
		return false;
	});
	
	// 
	if (savedProducts = readAllCookieValues('savedProductIDs'))
	{
		// There are saved products to display
		for (var tokenizedArrayID in savedProducts)
		{	
			tokenizedArray = savedProducts[tokenizedArrayID].split(',');
			renderComparisonProducts(tokenizedArray[0], tokenizedArray[1], tokenizedArray[2]);
		}
		// There should be at least 1 saved item, so...
		// 1. show compare button	
		$("#compare_button").css("display", "block");
		// 2. hide 'add stuff here' message
		$("#deleteme").css("display", "none");
	}
	
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

/* I am 99% sure that this is no longer useful, but not 100%. ZAT */
/* http://snipplr.com/view/1696/get-elements-by-class-name/ */
/* function getElementsByClassName(classname, node) {
   if(!node) node = document.getElementsByTagName("body")[0];
   var a = [];
   var re = new RegExp('\\b' + classname + '\\b');
   var els = node.getElementsByTagName("*");
   for(var i=0,j=els.length; i<j; i++)
   		if(re.test(els[i].className))a.push(els[i]);
   return a;
  } */
