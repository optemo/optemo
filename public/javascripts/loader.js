var scriptSource = (function(scripts) { 
    var scripts = document.getElementsByTagName('script'), 
    script = scripts[scripts.length - 1]; 

    return (script.getAttribute.length !== undefined) ?
           //FF/Chrome/Safari 
           script.src : //(only FYI, this would work also in IE8)
           //IE 6/7/8
           script.getAttribute('src', 4); //using 4 (and not -1) see MSDN http://msdn.microsoft.com/en-us/library/ms536429(VS.85).aspx
}());
var temp_element = document.createElement("a");
temp_element.href = scriptSource;
optemo_french = (window.location.href.match(/fr-ca/i));
OPT_REMOTE = 'http://';
if (typeof(optemo_french) != undefined && optemo_french != null) OPT_REMOTE += "fr.";
OPT_REMOTE += temp_element.host;
//Lightweight JSONP fetcher - www.nonobtrusive.com
//Took out encodeURIComponent
var JSONP=(function(){var a=0,c,f,b,d=this;function e(j){var i=document.createElement("script"),h=false;i.src=j;i.async=true;i.onload=i.onreadystatechange=function(){if(!h&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){h=true;i.onload=i.onreadystatechange=null;if(i&&i.parentNode){i.parentNode.removeChild(i)}}};if(!c){c=document.getElementsByTagName("head")[0]}c.appendChild(i)}function g(h,j,k){f="?";j=j||{};for(b in j){if(j.hasOwnProperty(b)){f+=b+"="+j[b]+"&"}}var i="json"+(++a);d[i]=function(l){k(opt_parse_data_by_pattern(l, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, OPT_REMOTE + "$1");})));d[i]=null;try{delete d[i]}catch(m){}};e(h+f+"callback="+i);return i}return{get:g}}());
//Function for executing code at DOMReady
//function opt_s(f){/in/.test(document.readyState)?setTimeout('opt_s('+f+')',9):f()}
function opt_insert(d) {
    var opt_t = document.getElementById("optemo_embedder");
    if (opt_t) {
        var se = document.createElement("div");
        se.id = "opt_new";
        se.innerHTML = d;
        opt_t.appendChild(se);
        if (typeof optemo_module != "undefined") {
            optemo_module.domready();
        }
    } else
        setTimeout(function(){opt_insert(d);d=null;},10);
}
//Load the correct history on reload
var opt_history = location.hash.replace(/^#/, '');
// To get the category id that gets passed in, check the URL:
// http://www.bestbuy.ca/en-CA/digital-cameras.aspx maps to the category id 22474.
// This is ascertained by looking at the database, in the category_id_product_type_maps table.
// The regular expressions for all but the first entry (digital cameras) are assumed (as of July 6, 2011)

var category_id_hash = {'digital-cameras' : 22474,
                        'digital-tvs' : 21344, // The URL is probably not quite correct yet; this is a placeholder
                        'harddrives' : 20243,
                        'Drives-Storage' : 20243,
                        'lecteurs-et-stockage' : 20243};
// Allow for passing the category via url
var urlRegex = new RegExp("[\\?&]category_id=([^&#]*)");
var url_passed_category = urlRegex.exec(window.location.href);
if (url_passed_category == null)
  var opt_category_id = 0;
else
  var opt_category_id = url_passed_category[1] || 0;

//Check the URL for the categories in the category_hash  
for (var i in category_id_hash) {
    if (window.location.pathname.match(new RegExp(i,"i"))) {
        opt_category_id = category_id_hash[i];
        break;
    }
}
// Failsafe just in case nothing seems to match
if (opt_category_id == 0) {
    opt_category_id = 22474;
    if (typeof(console) != "undefined") console.warn("Product category not recognized - Cameras used as default");
}

if (opt_history.length > 0)
    var opt_options = {embedding:'true', hist: opt_history, category_id: opt_category_id};
else
    var opt_options = {embedding:'true', category_id: opt_category_id, landing: true};
JSONP.get(OPT_REMOTE, opt_options, function (data) {
    if ( !/MSIE/i.test(navigator.userAgent) || scriptSource.match(/localhost/) || scriptSource.match(/192.168/)) { // We need to do some additional work
        var regexp_pattern, data_to_add, data_to_append, scripts, headID = document.getElementsByTagName("head")[0], script_nodes_to_append, i, images;
        // Take out all the scripts, load them on the client (consumer) page in the HEAD tag, and put the data back together
        regexp_pattern = (/<script[^>]+>/g);
        scripts = data.match(regexp_pattern);
        if (scripts != null) {           
            // It's odd that we have to do this check: The difference between loader and loader_local used to be
            // the loading of javascript files, as below. However, in the current Best Buy embedding frame,
            // they have been putting bb_loader_packaged.js as a separate line, and so in order to match our local embedded
            // testing environment with the sandbox site, we do not currently have separate scripts to load.
            // Since this could easily change back, I've kept the below code so that we can switch back as necessary. ZAT July 20, 2011
            data_to_add = data.split(regexp_pattern);
            script_nodes_to_append = Array();
            for (i = 0; i < scripts.length; i++)
            {
                srcs = scripts[i].match(/src=["']([^'"]+)["']/); // Check is there is a src file linked
                if (srcs == null) {
                    scripts[i] = '<script type="text/javascript">';
        		    } else {
        		        if (srcs[1].match("http://")) //If complete URL use that
        		          script_nodes_to_append.push(srcs[1]);
        		        else //Otherwise, us the remote URL with the relative URL
                      script_nodes_to_append.push(OPT_REMOTE + "/" + srcs[1]);
                    scripts[i] = '';
                }
            // When zipping stuff back up, we want to take out the /script tag *unless* there was a null response.
            }

        	//Zipping data back up
            data_to_append = new Array();
            // This is basically a do-while loop in disguise. Put the zeroth element on first, go from there.
            data_to_append.push(data_to_add[0])
            for (i = 0; i < scripts.length; i++) {
                // Either put back the <script> tag that is required for inline scripts, or else take out the < /script> part from the start of data_to_add[i+1].
                // Each time, look at scripts[i]. If empty, we need to take out the /script part that starts the next block.
                if (scripts[i] == '') { // If empty, take out the "/script" part and push the next piece. Also, if it's the XDM script itself
                    data_to_append.push(data_to_add[i+1].replace(/<\/script>/,''));
                } else { // If not empty, we need to put the <script> back in
        			data_to_append.push(scripts[i]);
                    data_to_append.push(data_to_add[i+1]);
                }
            }
            // Now, we want to join all the data 
            data_to_append = data_to_append.join("\n");
        } else {
            data_to_append = data;
        }
        opt_insert(data_to_append);

    	// We have to load all scripts in order, but using labJS is too heavy. So, we do a recursive serial loader function.
    	// Although serial should == slow, the javascript we're loading should only be one file in production.
    	// The purpose of having this multiple-script functionality is for development mode.
        if (scripts != null) {
        	(function lazyloader(i) {
        	    // attach current script, using closure-scoped variable
        		var script = document.createElement("script");
                script.setAttribute("type", "text/javascript");
        	    // when finished loading, call lazyloader again on next script, if there is one.
                if ((i + 1) < script_nodes_to_append.length) {
                    if (script.readyState){  //IE
                        script.onreadystatechange = function(){
                            if (script.readyState == "loaded" ||
                                    script.readyState == "complete"){
                                script.onreadystatechange = null;
                                lazyloader(i + 1);
                            }
                        };
                    } else {  //Others
                        script.onload = function(){
                            lazyloader(i + 1);
                        };
                    }    
                } else {
               		if (script.readyState){  //IE
                        script.onreadystatechange = function(){
                            if (script.readyState == "loaded" ||
                                    script.readyState == "complete"){
                                script.onreadystatechange = null;
                            }
                        };
                    }
                }		    
                script.setAttribute("src", script_nodes_to_append[i]);
                document.getElementsByTagName("head")[0].appendChild(script);
            })(0);   
        } 
    } else {
        opt_insert(data);
    }
});
// Private function for the register_remote socket. Takes data, splits according to rules, does replace() according to rules.
function opt_parse_data_by_pattern(mydata, split_pattern_string, replacement_function) {
	var data_to_add, data_to_append, split_regexp = new RegExp(split_pattern_string, "gi");
    images = mydata.match(split_regexp);
    data_to_add = mydata.split(split_regexp);
    data_to_append = new Array();
    data_to_append.push(data_to_add[0]);
    for (i = 0; i < images.length; i++) {
        if (images[i].match(new RegExp("http:\/\/"))) 
            data_to_append.push(images[i]);
        else
            data_to_append.push(replacement_function(images[i]));
        data_to_append.push(data_to_add[i+1]);
    }
    return data_to_append.join("\n");
}
