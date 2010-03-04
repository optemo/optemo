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
//Load start page via ajax
if ($('#ajaxload'))
{
	if (location.hash)
		ajaxsend(location.hash.replace(/^#/, ''),null,null,true);
	else
		ajaxsend(null,'/?ajax=true',null,true);
	
}

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
	$('#outsidecontainer').css({'left' : ((document.body.clientWidth-(width||800))/2)+'px',
								'top' : (dsoctop+5)+'px',
								'width' : width||800,
								'height' : height||770,
								'display' : 'inline' });
	$('#fade').css({'height' : getDocHeight()+'px', 'display' : 'inline'});
	$('#selector').css('visibility', 'hidden');
	if (data)
		$('#info').html(data);
	else
		$('#info').load(url,function(){DBinit('#info');});	
}

// When you click the Save button:
function saveProductForComparison(id, imgurl, name)
{	
	imgurlToSaveArray = imgurl.split('/');
	
	imgurlToSaveArray[imgurlToSaveArray.length - 1] = id + "_s.jpg";
	productType = imgurlToSaveArray[(imgurlToSaveArray.length - 2)];
	productType = productType.substring(0, productType.length-1);
	imgurlToSave = imgurlToSaveArray.join("/");
	
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
		addValueToCookie('savedProductIDs', [id, imgurlToSave, name, productType]);
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
	smallProductImageAndDetail = "<img class=\"productimg\" src=" + // used to have width=\"45\" height=\"50\" in there, but I think it just works for printers...
	//"/images/printers/"+id+"_s.jpg?1260303451" + 
	imgurl + 
	" data-id=\""+id+"\" alt=\""+id+"_s\"/ width=\"50\">" + 
	"<div class=\"smalldesc\"";
	// It looks so much better in Firefox et al, so if there's no MSIE, go ahead with special styling.
	if ($.browser.msie) smallProductImageAndDetail = smallProductImageAndDetail + " style=\"position:absolute; bottom:5px;\"";
	smallProductImageAndDetail = smallProductImageAndDetail + ">" +
	"<a class=\"easylink\" data-id=\""+id+"\" href=\"#\">" + 
	((name) ? getShortProductName(name) : 0) +
	"</a></div>" + 
	"<a class=\"deleteX\" data-name=\""+id+"\" href=\"#\" onClick=\"javascript:removeFromComparison("+id+");return false;\">" + 
	"<img src=\"/images/close.png\" alt=\"Close\"/></a>"; // do we need '?1258398853' ? I doubt it.
	$(smallProductImageAndDetail).appendTo('#c'+id);
	DBinit("#c"+id)

	$("#already_added_msg").css("display", "none");
	$("#too_many_saved").css("display", "none");
	if ($.browser.msie) // If it's any browser other than IE, clear the height element.
		$("#savedproducts").css({"height" : ''});
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
	return false;
}

function removeBrand(str)
{
	$('#myfilter_Xbrand').attr('value', str);
	ajaxcall("/compare/filter", $("#filter_form").serialize());
}

function submitCategorical(){
	ajaxcall("/compare/filter", $("#filter_form").serialize());
	trackPage('goals/filter/autosubmit');
}

function submitsearch() {
	var searchinfo = { 'search_text' : $("#search_form input#search").attr('value'), 'optemo_session': parseInt($('#seshid').attr('session-id')) };
	piwikTracker2.setCustomData(searchinfo);
	trackPage('goals/search');
	piwikTracker2.setCustomData({});
	ajaxcall("/compare/find?ajax=true", $("#search_form").serialize());
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

function launchtour() {
	var browseposition = $("#sim0").offset();
	$("#sim0").addClass('tourDrawAttention');
	// Position relative to sim0 every time in case of interface changes (it is the first browse similar link)
	$("#popupTour1").css({"position":"absolute", "top" : parseInt(browseposition.top) - 120, "left" : parseInt(browseposition.left) + 165}).fadeIn("slow");
	return false;
}

//--------------------------------------//
//          Data Manipulation           //
//--------------------------------------//

function findBetter(id, feat)
{
       // Check if better product exists for that feature using /compare/better Rails me
       // Query.get( url, [data], [callback], [type] )
       $.get("/direct_comparison/better?original=" + id + "&feature=" + feat, 
               function(data){
                       if (data == "-1")
                       {
                               $('#betternotfoundmsg').css('visibility', 'visible');
                       }
                       else
                       {
                               // found better printer (with id stored in data)
                               window.location = "/direct_comparison/index/" + id + "-" + data;
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
console.log("Calling DBinit with context: "+context);
	
	//-------Info Popup--------//
	$("#comparisonTable",context).tableDnD({
		onDragClass: "rowBeingDragged",
		onDrop: function(table, row){		
			newPreferencesString = $.tableDnD.serialize();
		}
	});
	
	//Link from popup (used for error messages)
	$('.popuplink', context).click(function(){
		ajaxcall($(this).attr('href')+'?ajax=true');
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
	
	//--------Product Section-------//
	//Used in Main Section and Saved items box
	
	$(".productimg",context).click(function (){
		fadeout('/compare/show/'+$(this).attr('data-id')+'?plain=true',null, 800, 800);/*Star-h:700*/
		trackPage('products/show/'+$(this).attr('data-id')); 
		return false;
	});
	
	// However, always add it to the link below the image.
	$(".easylink",context).click(function() {
		fadeout('/compare/show/'+$(this).attr('data-id')+'?plain=true',null, 800, 800);/*Star-h:700*/
		trackPage('products/show/'+$(this).attr('data-id')); 
		//trackPage($(this).attr('href'));
		return false;
	});
	
	//-------Main Section-------//
	
	if (IS_DRAG_DROP_ENABLED)
	{
		// Make item boxes draggable. This is a jquery UI builtin.		
		$(".image_boundingbox img",context).each(function() {
			$(this).draggable({ 
				revert: 'invalid', 
				cursor: "move", 
				// The following defines the drag distance before a "drag" event is actually initiated. Helps for people who click while the mouse is slightly moving.
				distance:2,
				helper: 'clone',
				zIndex: 1000,
				start: function(e, ui) { 
					if ($.browser.msie) // Internet Explorer sucks and cannot do transparency
					$(this).css({'opacity':'0.4'});
				},
				stop: function (e, ui) {
					if ($.browser.msie)
						$(this).css({'opacity':'1'});
				}
			});
            $(this).hover(function() {
	                $(this).find('.dragHand').stop().animate({ opacity: 1.0 }, 150);
			    },
		        function() {
	            	$(this).find('.dragHand').stop().animate({ opacity: 0.35 }, 450);
           });
	    });
	}
	
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
	
	$('#tourautostart', context).each(launchtour); //Automatically launch tour
	
	//-------Filters Section-------//
	
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
	$('#morefilters',context).click(function(){
		$('.extra').show("slide",{direction: "up"},100);
		$(this).css('display','none');
		$('#lessfilters').css('display','block');
		return false;
	});
	
	//Hide Additional Features
	$('#lessfilters',context).click(function(){
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
				// These acceptable increments can be tweaked as necessary. Multiples of 5 and 10 look cleanest; 20 looks OK but 2 and 0.2 look weird.
				var acceptableincrements = [1000, 500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01];
				var increment = (rangemax - rangemin) / 100.0;
				for (var i = 0; i < acceptableincrements.length; i++) // Just so that it doesn't go off the scale for weird error case (increment == 0)
				{
					if ((increment * 1.1) < acceptableincrements[i])  // The fudge factor here is required.
						continue;
					else // so, for example, increment is 51 and increment is 100
						increment = acceptableincrements[i];
					// could do this with a state machine a bit cleaner but this works fine. After the first time that the increment is in range, stop the loop immediately
					break;
				}
				
				var realselectmin, realselectmax;
				var value = ui.value;
				var sliderno = -1;
				if(ui.value == ui.values[0])
					sliderno = 0;
				else
					sliderno = 1;
				$(this).slider('values', sliderno, value);
				realvalue = (parseFloat((ui.values[sliderno]/100))*(rangemax-rangemin))+rangemin;

				if (increment < 1) { 
					// floating point division has problems; avoid it 
					tempinc = parseInt(1.0 / increment);
					realvalue = parseInt(realvalue * tempinc) / tempinc;
				}
				else
					realvalue = parseInt(realvalue / increment) * increment;
				
				// This makes sure that when sliding to the extremes, you get back to the real starting points
				if (sliderno == 1 && ui.values[1] == 100)
					realvalue = rangemax;
				if (sliderno == 0 && ui.values[0] == 0)
					realvalue = rangemin;
					
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
				ajaxcall("/compare/filter", $("#filter_form").serialize());
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
		$(this).removeClass('ui-widget').removeClass('ui-widget-content').removeClass('ui-corner-all');
		$(this).find('a').each(function(){
			$(this).removeClass('ui-state-default').removeClass('ui-corner-all');
			$(this).unbind('mouseenter mouseleave');
		});
		
	});

}

//--------------------------------------//
//          document.ready()            //
//--------------------------------------//

$(document).ready(function() {
	// Due to a race condition in IE6, this must be before DBinit().
	
	var tokenizedArrayID = 0;
	if (savedProducts = readAllCookieValues('savedProductIDs'))
	{
		// There are saved products to display
		if ($.browser.msie) {
			fixedheight = ((savedProducts.length > 2) ? 80 : 160) + 'px';
			$("#savedproducts").css({"height" : fixedheight});
		}
		for (tokenizedArrayID = 0; tokenizedArrayID < savedProducts.length; tokenizedArrayID++)
		{	
			tokenizedArray = savedProducts[tokenizedArrayID].split(',');
			// In future, tokenizedArray[3] contains the product type. As of Feb 2010, each website has separate cookies, so it's not necessary to read this data.
			renderComparisonProducts(tokenizedArray[0], tokenizedArray[1], tokenizedArray[2]);
		}
		// There should be at least 1 saved item, so...
		// 1. show compare button	
		$("#compare_button").css("display", "block");
		// 2. hide 'add stuff here' message
		$("#deleteme").css("display", "none");
	}
	
	$.historyInit(ajaxsend);
	
	//Only load DBinit if it will not be loaded by the upcoming ajax call
	if (!$('#ajaxload'))
		DBinit();
	
	//Find product language
	language = (/^\s*English/.test($(".languageoptions:first").html())==true)?'en':'fr';

	//Decrypt encrypted links
	$('a.decrypt').each(function () {
		$(this).attr('href',$(this).attr('href').replace(/[a-zA-Z]/g, function(c){
			return String.fromCharCode((c<="Z"?90:122)>=(c=c.charCodeAt(0)+13)?c:c-26);
			}));
	});

	//Fadein
	$(".close").click(function(){
		fadein();
		return false;
	});
    
	if (IS_DRAG_DROP_ENABLED)
	{
		// Make savebar area droppable. jquery UI builtin.
		$("#savebar").each(function() {
			$(this).droppable({ 
				hoverClass: 'drop-box-hover',
				activeClass: 'ui-state-dragging', 
				accept: ".ui-draggable",
				drop: function (e, ui) {
					imgObj = $(ui.helper);
					saveProductForComparison(imgObj.attr('data-id'), imgObj.attr('src'), imgObj.attr('alt'));
				}
			 });
		});
	}
	
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
		fadeout('/direct_comparison/index/' + productIDs, null, 940, 530);/*star-h:580*/
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
	
	//Tour section
	
	$('.popupTour').each(function(){
		$(this).find('.deleteX').click(function(){
			$(this).parent().fadeOut("slow");
			clearStyles(["sim0", "filterbar", "savebar"], 'tourDrawAttention');
			return false;
		});
	});
	
	$('#popupTour1').find('a.popupnextbutton').click(function(){
		var middlefeatureposition = $("#filterbar").find(".feature:eq(3)").offset();
		$("#popupTour2").css({"position":"absolute", "top" : parseInt(middlefeatureposition.top) - 120, "left" : parseInt(middlefeatureposition.left) + 220}).fadeIn("slow");
		$("#popupTour1").fadeOut("slow");
		$("#filterbar").addClass('tourDrawAttention');
		$("#sim0").removeClass('tourDrawAttention');
	});

	$('#popupTour2').find('a.popupnextbutton').click(function(){
		var comparisonposition = $("#savebar").offset();
		$("#popupTour3").css({"position":"absolute", "top" : parseInt(comparisonposition.top) + 160, "left" : parseInt(comparisonposition.left) + 70}).fadeIn("slow");
		$("#popupTour2").fadeOut("slow");
		$("#savebar").addClass('tourDrawAttention');
		$("#filterbar").removeClass('tourDrawAttention');
	});
	
	$('#popupTour3').find('a.popupnextbutton').click(function(){
		$("#popupTour3").fadeOut("slow");
		$("#savebar").removeClass('tourDrawAttention');
	});
	
	// On escape press. Probably not needed anymore.
	$(document).keypress(function(e){
		if(e.keyCode==27){
			$(".popupTour").fadeOut("slow");
			clearStyles(["sim0", "filterbar", "savebar"], 'tourDrawAttention');
			if ($.browser.msie && $.browser.version == "7.0") $("#sim0").parent().removeClass('tourDrawAttention');
		}
	});

	//Autocomplete for searchterms
	$.ajax({
		type: "GET",
		data: "",
		url: "/compare/searchterms",
		success: function (data) {
			// autocomplete is expecting data like this:
			// "Lexmark[BRK]Metered[BRK]DeskJet"
			terms = data.split('[BRK]');
			$("#search").autocomplete(terms, {
				minChars: 1,
				max: 10,
				autoFill: false,
				mustMatch: false,
				matchContains: true,
				scrollHeight: 220
			});
		}
	});

	myspinner = new spinner("myspinner", 11, 20, 9, 5, "#000");
	
	$("#tourButton").click(launchtour); //Launch tour when this is clicked
	
	if ($.browser.msie) // If it's any version of IE, the transparency for the hands doesn't get done properly on page load.
	{
		$('.dragHand').each(function() {
			$(this).fadeTo("fast", 0.35);
		});
	}
});

