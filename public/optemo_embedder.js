/* To create a website that embeds the Optemo Assist or Direct interface, create an HTML file on any server and insert the following:

In the <head>: 
<script src="http://assets.optemo.com:3000/optemo_embedder.js" type="text/javascript"></script>

In the <body>:
<div id="optemo_embedder"></div>

This script will auto-load various javascript files from the server, embed an iframe into the website, and load the interface via AJAX (not usually possible due to cross-site restrictions, but implemented using easyXDM, http://easyxdm.net/)

This script could be minified for better performance. */

/* LazyLoad courtesy of http://github.com/rgrove/lazyload/ already minified */
LazyLoad=function(){var f=document,g,b={},e={css:[],js:[]},a;function j(l,k){var m=f.createElement(l),d;for(d in k){if(k.hasOwnProperty(d)){m.setAttribute(d,k[d])}}return m}function h(d){var l=b[d];if(!l){return}var m=l.callback,k=l.urls;k.shift();if(!k.length){if(m){m.call(l.scope||window,l.obj)}b[d]=null;if(e[d].length){i(d)}}}function c(){if(a){return}var k=navigator.userAgent,l=parseFloat,d;a={gecko:0,ie:0,opera:0,webkit:0};d=k.match(/AppleWebKit\/(\S*)/);if(d&&d[1]){a.webkit=l(d[1])}else{d=k.match(/MSIE\s([^;]*)/);if(d&&d[1]){a.ie=l(d[1])}else{if((/Gecko\/(\S*)/).test(k)){a.gecko=1;d=k.match(/rv:([^\s\)]*)/);if(d&&d[1]){a.gecko=l(d[1])}}else{if(d=k.match(/Opera\/(\S*)/)){a.opera=l(d[1])}}}}}function i(r,q,s,m,t){var n,o,l,k,d;c();if(q){q=q.constructor===Array?q:[q];if(r==="css"||a.gecko||a.opera){e[r].push({urls:[].concat(q),callback:s,obj:m,scope:t})}else{for(n=0,o=q.length;n<o;++n){e[r].push({urls:[q[n]],callback:n===o-1?s:null,obj:m,scope:t})}}}if(b[r]||!(k=b[r]=e[r].shift())){return}g=g||f.getElementsByTagName("head")[0];q=k.urls;for(n=0,o=q.length;n<o;++n){d=q[n];if(r==="css"){l=j("link",{href:d,rel:"stylesheet",type:"text/css"})}else{l=j("script",{src:d})}if(a.ie){l.onreadystatechange=function(){var p=this.readyState;if(p==="loaded"||p==="complete"){this.onreadystatechange=null;h(r)}}}else{if(r==="css"&&(a.gecko||a.webkit)){setTimeout(function(){h(r)},50*o)}else{l.onload=l.onerror=function(){h(r)}}}g.appendChild(l)}}return{css:function(l,m,k,d){i("css",l,m,k,d)},js:function(l,m,k,d){i("js",l,m,k,d)}}}();

window.embedding_flag = true;
var optemo_module, remote, REMOTE = 'http://assets.optemo.com:3000'; // static globals

var optemo_socket_activator = (function () {
    /**
     * Request the use of the JSON object
     */
    jQuery('body').append('<div style="display:none" id="optemo_embedder_socket"></div>');
	remote = new easyXDM.Rpc(/** The channel configuration */{
		/**
		 * Register the url to hash.html, this must be an absolute path
		 * or a path relative to the root.
		 * @field
		 */
		local: "/name.html",
		/**
		 * Register the url to the remote interface
		 * @field
		 */
		remote: REMOTE + "/socket.html",
		remoteHelper: REMOTE + "/name.html",
		/**
		 * Register the DOMElement that the generated IFrame should be inserted into
		 */
		container: "optemo_embedder_socket",
		props: {
		    style: {
		        border: "2px dotted red",
		        height: "200px",
				display: "none"
		    }
		},
		onReady: function(){
		   /**
		    * Call a method on the other side
		    */
			remote.initialLoad(function(result){ 
			    // Seems to be designed to take a function as a return. 
			    // The socket on the other side will automatically call the appropriate local parsing function when appopriate, so do nothing.

			});
		}
	}, /** The interface configuration */ {
		remote: {
			initialLoad: {},
		    iframecall: {},
			quickiframecall: {}
		},
		local: {
		    initialPageDelivery: function(result){ // This is the parser for the initial load. It's only used when an entire request comes back, <html> and all, probably from the optemo.html.erb layout.
				embed_tag = jQuery('#optemo_embedder');
				if (embed_tag.children().length > 0) 
				{
					first_inject = false;
					embed_tag.children().each(function(){ jQuery(this).remove();});
				}
				var first_inject = true; // On the first injection, move the scripts. Afterward, delete all scripts.

	            var d = result, regexp_pattern, data_to_add, data_to_append, scripts, headID = document.getElementsByTagName("head")[0], scripts_to_load, i, images;
	            regexp_pattern = (/<script[^>]+>/g);
	            scripts = d.match(regexp_pattern);
	            data_to_add = d.split(regexp_pattern);
	            script_nodes_to_append = Array();
	            for (i = 0; i < scripts.length; i++)
	            {
	                srcs = scripts[i].match(/javascripts[^?]+/); // We might want to make a check for src instead.
	                if (srcs == null) {
	                    scripts[i] = '<script type="text/javascript">';
	                } else if (first_inject && (typeof(srcs) == "object" && srcs[0] && srcs[0].match(/easyXDM/))){
						 scripts[i] = ''; // so it will get taken out completely later
					} else {
	                    script_nodes_to_append.push(REMOTE + "/" + srcs);
	                    scripts[i] = '';
	                }
	            // When zipping stuff back up, we want to take out the /script tag *unless* there was a null response.
	            }

				// We have to do it in order. What is happening is that this callback gets called on *EVERY LOAD* otherwise.
				(function recursive_loader(i) { 
					LazyLoad.js(script_nodes_to_append[i], function () {
						i++; 
						if (i < script_nodes_to_append.length) {
							recursive_loader(i); 
						} else { // No more scripts to load. That means application.js has been parsed, and the optemo_module object has been instantiated.
							optemo_module.embeddedString = REMOTE;
							optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
						}
						return 0;
					});
				})(0);

				// By this point we can guarantee that everything loaded serially.
	            data_to_append = new Array();
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

	            // Process the stylesheets next:
	            regexp_pattern = (/<link[^>]+>/g);
	            styles = data_to_append.match(regexp_pattern);
				if (styles) {
		            data_to_add = data_to_append.split(regexp_pattern);
		            for (i = 0; i < styles.length; i++) {
		                srcs = styles[i].match(/stylesheets[^?]+/)
		                if (!first_inject || srcs == null) { // If we have already loaded once, the javascript and styles are already in place.
		                    // Do nothing
		                } else {
		                    var tag = document.createElement("link");
		                    tag.setAttribute("href", REMOTE + "/" + srcs);
		                    tag.setAttribute("type", "text/css");
		                    tag.setAttribute("rel", "stylesheet");
		                    headID.appendChild(tag);
		                }
		            }
		            data_to_append = data_to_add.join("\n");
				}
	            // Process images next. To do this, just find all the images, split the data as before, and change the src tag.
	            regexp_pattern = (/<img[^>]+>/g);
	            images = data_to_append.match(regexp_pattern);
	            data_to_add = data_to_append.split(regexp_pattern);
	            data_to_append = new Array();
	            data_to_append.push(data_to_add[0]);
	            for (i = 0; i < images.length; i++) {
	                data_to_append.push(images[i].replace(/(\/images\/[^?]+)/, REMOTE + "$1"));
	                data_to_append.push(data_to_add[i+1]);
	            }

	            data_to_append = data_to_append.join("\n");

				// Now strip out any erroneous tags.
				regexp_patterns = ["<\/?html[^>]*>", "<!doctype[^>]+>", "<meta[^>]*>", "<\/?body[^>]*>", "<\/?head>", "<title>[^<]*<\/title>"];
				for (i = 0; i < regexp_patterns.length; i++) {
					data_to_append = data_to_append.replace(new RegExp(regexp_patterns[i], "gi"), '');
				}
				embed_tag.append(data_to_append);
		    },
			parseData: function (data) {
				regexp_pattern = (/<img[^>]+>/g);
	            images = data.match(regexp_pattern);
	            data_to_add = data.split(regexp_pattern);
	            data_to_append = new Array();
	            data_to_append.push(data_to_add[0]);
	            for (i = 0; i < images.length; i++) {
	                data_to_append.push(images[i].replace(/(\/images\/[^?]+)/, REMOTE + "$1"));
	                data_to_append.push(data_to_add[i+1]);
	            }
	            data_to_append = data_to_append.join("\n");
				optemo_module.ajaxhandler(data_to_append);
			},
			parseDataThin: function (element_name, data, fn) {
				data = parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));
				jQuery(element_name).html(data); // This seems unsafe. Fix this?
				fn(); // This is probably DBInit(), but could be anything;
			}
		}
	});
	// Private function for the register_remote socket. Takes data, splits according to rules, does replace() according to rules.
	function parse_data_by_pattern(mydata, split_pattern_string, replacement_function) {
		var data_to_add, data_to_append, split_regexp = new RegExp(split_pattern_string, "gi");
        images = mydata.match(split_regexp);
        data_to_add = mydata.split(split_regexp);
        data_to_append = new Array();
        data_to_append.push(data_to_add[0]);
        for (i = 0; i < images.length; i++) {
            data_to_append.push(replacement_function(images[i]));
            data_to_append.push(data_to_add[i+1]);
        }
        return data_to_append.join("\n");
	}			
});

// This must be loaded first in IE and Opera 10.1
if (!(typeof(window["JSON"]) == 'object' && window["JSON"])) {
    var script_element = document.createElement('script');
    script_element.type = 'text/javascript';
    script_element.src = REMOTE + "/javascripts/json2.js";
    document.getElementsByTagName('head')[0].appendChild(script_element);
}

// Load jQuery if it's not already loaded.
// The purpose of using a try/catch loop is to avoid Internet Explorer 8 from crashing when assigning an undefined variable.
try {
    var jqueryIsLoaded = jQuery;
    jQueryIsLoaded = true;
}
catch(err) {
    var jQueryIsLoaded = false;
}
if(jQueryIsLoaded) {
    LazyLoad.js(REMOTE + '/javascripts/easyXDM.min.js', (function (){
        optemo_socket_activator(); 
    }));
} else {
    LazyLoad.js(['http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js', REMOTE + '/javascripts/easyXDM.min.js'], (function (){
        optemo_socket_activator();
    }));
}

// This is the call that gets the socket open. It's important to do this serially, in three steps:
// (1) Load XDM, (2) load jQuery, if necessary, (3) load everything else. This is for dependency reasons (eliminate race conditions).
