/*   Helper functions. All of these are used in application.js.
-------- AJAX ---------
ajaxsend(hash,myurl,mydata)  -  Does AJAX call through jquery, returns through ajaxhandler(data)
ajaxhandler(data)  -  Splits up data from the ajax call in a thoroughly undocumented manner
ajaxerror() - Displays error message if the ajax send call fails
ajaxcall(myurl,mydata) - adds a hash with the number of searches to the history path
flashError(str)  -  Puts an error message on a specific part of the screen

-------- Layout -------
getDocHeight()  -  Returns an array of scroll, offset, and client heights

-------- Data -------
getAllShownProductIds()  -  Returns currently displayed product IDs.
getShortProductName(name)  -  Returns the shorter product name for printers. This should be extended in future.
appendStringWithToken(items, newitem, token)  -  For lists like this: "318*124*19"
removeStringWithToken(items, rem, token)  -  As above, for removal

------- Spinner -------
spinner(holderid, R1, R2, count, stroke_width, colour)  -  returns a spinner object
showspinner()
hidespinner()

-------- Cookies -------
addValueToCookie(name, value)  -  Add a value to the cookie "name" or create a cookie if none exists.
removeValueFromCookie(name, value)  -  Remove a value from the cookie, and delete the cookie if it's empty.
readAllCookieValues(name)  -  Returns an array of cookie values.

createCookie(name,value,days)  -  Try not to use this or the two below directly if possible, they are like private methods.
readCookie(name)  -  Gets raw cookie 'value' data.
eraseCookie(name)
*/

//The loading spinner object with a dummy function to start
var myspinner = {
	begin: function(){},
	end: function(){}
};

//--------------------------------------//
//                AJAX                  //
//--------------------------------------//

/* Does a relatively generic ajax call and returns data to the handler below */
function ajaxsend(hash,myurl,mydata,hidespinner) {
	if (hidespinner != true)
		showspinner();
	if (myurl != null)
	{
	$.ajax({
		type: (mydata==null)?"GET":"POST",
		data: (mydata==null)?"":mydata,
		url: myurl,
		success: ajaxhandler,
		error: ajaxerror
	});
	}
	else if (typeof(hash) != "undefined" && hash != null)
	{
		$.ajax({
			type: "GET",
			url: "/compare/compare/?hist="+hash,
			success: ajaxhandler,
			error: ajaxerror
		});
	}
}

/* The ajax handler takes data from the ajax call and processes it according to some (unknown) rules. */
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
		FilterAndSearchInit(); DBinit();
		return 0;
	}
}

function ajaxerror(){
	//if (language=="fr")
	//	flashError('<div class="poptitle">&nbsp;</div><p class="error">Désolé! Une erreur s’est produite sur le serveur.</p><p>Vous pouvez <a href="" class="popuplink">réinitialiser</a> l’outil et constater si le problème persiste.</p>');
	//else
	flashError('<div class="poptitle">&nbsp;</div><p class="error">Sorry! An error has occured on the server.</p><p>You can <a href="/compare/">reset</a> the tool and see if the problem is resolved.</p>');
}

function ajaxcall(myurl,mydata)
{
	numactions = parseInt($("#actioncount").html()) + 1;
	$.history.load(numactions.toString(),myurl,mydata);
}

/* Puts an ajax-related error message in a specific part of the screen */
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
	ErrorInit();
}

//--------------------------------------//
//               Layout                 //
//--------------------------------------//

/* This is used to get the document height for doing layout properly. */
/*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
function getDocHeight() {
    var D = document;
    return Math.max(
        Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
        Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
        Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    );
}

// Takes an array of div IDs and removes either inline styles or a named class style from all of them.
function clearStyles(nameArray, styleclassname)
{
	if (nameArray.constructor == Array)
	{
		if (styleclassname != '') // We have a style name, so remove it from each div id that was passed in
		{
			for (i in nameArray) // iterate over all elements of array
			{
				if ($('#' + nameArray[i]).length) // the element exists
				{
					$("#" + nameArray[i]).removeClass(styleclassname);
				}
			}
		}
		else // No style name. Take out inline styles.
		{
			for (i in nameArray) // iterate over all elements of array
			{
				if ($('#' + nameArray[i]).length) // the element exists
				{
					$("#" + nameArray[i]).removeAttr('style');
				}
			}
		}
	}
	else if (nameArray != '') // there could be a single string passed also
	{
		if ($('#' + nameArray).length) // the element exists
		{
			if (styleclassname != '') // There is a style name for a single element.
			{
				$('#' + nameArray).removeClass(styleclassname);
			}
			else // Remove the inline styling by default
			{
				$('#' + nameArray).removeAttr('style');
			}
		}
		// If the element doesn't exist, don't try to access it via jquery, just do nothing.
	}
	else
	{
		// There is no array or string passed. Do nothing.
	}
}

//--------------------------------------//
//                Data                  //
//--------------------------------------//

/* This gets the currently displayed product ids client-side from the text beneath the product images. */
function getAllShownProductIds(){
	var currentIds = "";
	$('#main .easylink').each(function(i){
		currentIds += $(this).attr('data-id') + ',';
	});
	return currentIds;
}

function getShortProductName(name) 
{
	// This is the corresponding Ruby function.
	// I modified it slightly, since word breaks are a bit too arbitrary.
	// [brand.gsub("Hewlett-Packard","HP"),model.split(' ')[0]].join(' ')
	name = name.replace("Hewlett-Packard", "HP");
	var shortname = name.substring(0,16);
	if (name != shortname)
		return shortname + "...";
	else
		return shortname;
}

// Add an item to a list with a supplied token
function appendStringWithToken(items, newitem, token)
{
	return ((items == "") ? newitem : items+token+newitem);
}

// Remove an item from a list with a supplied token
function removeStringWithToken(items, rem, token)
{
	i = items.split(token);
	var newArray = [];
	for (j in i)
	{
		if (i[j].match(new RegExp("^" + rem )))
			continue;
		newArray.push(i[j]);
	}
	return newArray.join(token);
}

//--------------------------------------//
//              Spinner                 //
//--------------------------------------//

/* This sets up a spinning wheel, typically used for sections of the webpage that are loading */
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
	this.runspinner = false;
	this.begin = function() {
		this.runspinner = true;
		setTimeout(ticker, 1000 / sectorsCount);
	};
	this.end = function() {
		this.runspinner = false;
	};
	function ticker() {
	    opacity.unshift(opacity.pop());
	    for (var i = 0; i < sectorsCount; i++) {
	        sectors[i].attr("opacity", opacity[i]);
	    }
	    r.safari();
		if (myspinner.runspinner)
	    	setTimeout(ticker, 1000 / sectorsCount);
	};
}

function showspinner()
{
	myspinner.begin();
	$('#loading').css('display', 'inline');
}

function hidespinner()
{
	$('#loading').css('display', 'none');
	myspinner.end();
}

//--------------------------------------//
//              Cookies                 //
//--------------------------------------//

function addValueToCookie(name, value)
{
	var savedData = readCookie(name), numDays = 30;
	if (savedData)
	{
		// Cookie exists, add additional values with * as the token.
		savedData = appendStringWithToken(savedData, value, '*');
		createCookie(name, savedData, numDays);
	}
	else
	{
		// Cookie does not exist, so just create with the bare value
		createCookie(name, value, numDays);
	}
}

function removeValueFromCookie(name, value)
{
	var savedData = readCookie(name), numDays = 30;
	if (savedData)
	{
		savedData = removeStringWithToken(savedData, value, '*')
		if (savedData == "") // No values left to store
		{ 
			eraseCookie(name);
		}
		else
		{
			createCookie(name, savedData, numDays);	
		}
	}
	// else do nothing
}
// This should return all cookie values in an array.
function readAllCookieValues(name) 
{
	// Must error check for empty cookie
	return (readCookie(name) ? readCookie(name).split('*') : 0);
}

function createCookie(name,value,days) {  
    if (days) {  
        var date = new Date();  
        date.setTime(date.getTime()+(days*24*60*60*1000));  
        var expires = "; expires="+date.toGMTString();  
    }  
    else var expires = "";  
    document.cookie = name+"="+value+expires+"; path=/";  
}  
  
function readCookie(name) {  
    var nameEQ = name + "=";  
    var ca = document.cookie.split(';');  
    for(var i=0;i < ca.length;i++) {  
        var c = ca[i];  
        while (c.charAt(0)==' ') c = c.substring(1,c.length);  
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);  
    }  
    return null;  
}  
  
function eraseCookie(name) {  
    createCookie(name,"",-1);  
}
