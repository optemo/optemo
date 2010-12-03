/* To create a website that embeds the Optemo Assist or Direct interface, create an HTML file on any server and insert the following:

In the <head>: 
<script src="http://assets.optemo.com:3000/optemo_embedder.js" type="text/javascript"></script>

In the <body>:
<div id="optemo_embedder"></div>

This script will auto-load various javascript files from the server, embed an iframe into the website, and load the interface via AJAX (not usually possible due to cross-site restrictions, but implemented using easyXDM, http://easyxdm.net/)

This script could be minified for better performance. */

/*! LAB.js (LABjs :: Loading And Blocking JavaScript)
    v1.0.4 (c) Kyle Simpson
    MIT License
*/
(function(p){var q="string",w="head",H="body",I="script",t="readyState",j="preloaddone",x="loadtrigger",J="srcuri",C="preload",Z="complete",y="done",z="which",K="preserve",D="onreadystatechange",ba="onload",L="hasOwnProperty",bb="script/cache",M="[object ",bw=M+"Function]",bx=M+"Array]",e=null,h=true,i=false,k=p.document,by=p.location,bc=p.ActiveXObject,A=p.setTimeout,bd=p.clearTimeout,N=function(a){return k.getElementsByTagName(a)},O=Object.prototype.toString,P=function(){},r={},Q={},be=/^[^?#]*\//.exec(by.href)[0],bf=/^\w+\:\/\/\/?[^\/]+/.exec(be)[0],bz=N(I),bg=p.opera&&O.call(p.opera)==M+"Opera]",bh=("MozAppearance"in k.documentElement.style),bi=(k.createElement(I).async===true),u={cache:!(bh||bg),order:bh||bg||bi,xhr:h,dupe:h,base:"",which:w};u[K]=i;u[C]=h;r[w]=k.head||N(w);r[H]=N(H);function R(a){return O.call(a)===bw}function S(a,b){var c=/^\w+\:\/\//,d;if(typeof a!=q)a="";if(typeof b!=q)b="";d=(c.test(a)?"":b)+a;return((c.test(d)?"":(d.charAt(0)==="/"?bf:be))+d)}function bA(a){return(S(a).indexOf(bf)===0)}function bB(a){var b,c=-1;while(b=bz[++c]){if(typeof b.src==q&&a===S(b.src)&&b.type!==bb)return h}return i}function E(v,l){v=!(!v);if(l==e)l=u;var bj=i,B=v&&l[C],bk=B&&l.cache,F=B&&l.order,bl=B&&l.xhr,bC=l[K],bD=l.which,bE=l.base,bm=P,T=i,G,s=h,m={},U=[],V=e;B=bk||bl||F;function bn(a,b){if((a[t]&&a[t]!==Z&&a[t]!=="loaded")||b[y]){return i}a[ba]=a[D]=e;return h}function W(a,b,c){c=!(!c);if(!c&&!(bn(a,b)))return;b[y]=h;for(var d in m){if(m[L](d)&&!(m[d][y]))return}bj=h;bm()}function bo(a){if(R(a[x])){a[x]();a[x]=e}}function bF(a,b){if(!bn(a,b))return;b[j]=h;A(function(){r[b[z]].removeChild(a);bo(b)},0)}function bG(a,b){if(a[t]===4){a[D]=P;b[j]=h;A(function(){bo(b)},0)}}function X(b,c,d,g,f,n){var o=b[z];A(function(){if("item"in r[o]){if(!r[o][0]){A(arguments.callee,25);return}r[o]=r[o][0]}var a=k.createElement(I);if(typeof d==q)a.type=d;if(typeof g==q)a.charset=g;if(R(f)){a[ba]=a[D]=function(){f(a,b)};a.src=c;if(bi){a.async=i}}r[o].insertBefore(a,(o===w?r[o].firstChild:e));if(typeof n==q){a.text=n;W(a,b,h)}},0)}function bp(a,b,c,d){Q[a[J]]=h;X(a,b,c,d,W)}function bq(a,b,c,d){var g=arguments;if(s&&a[j]==e){a[j]=i;X(a,b,bb,d,bF)}else if(!s&&a[j]!=e&&!a[j]){a[x]=function(){bq.apply(e,g)}}else if(!s){bp.apply(e,g)}}function br(a,b,c,d){var g=arguments,f;if(s&&a[j]==e){a[j]=i;f=a.xhr=(bc?new bc("Microsoft.XMLHTTP"):new p.XMLHttpRequest());f[D]=function(){bG(f,a)};f.open("GET",b);f.send("")}else if(!s&&a[j]!=e&&!a[j]){a[x]=function(){br.apply(e,g)}}else if(!s){Q[a[J]]=h;X(a,b,c,d,e,a.xhr.responseText);a.xhr=e}}function bs(a){if(a.allowDup==e)a.allowDup=l.dupe;var b=a.src,c=a.type,d=a.charset,g=a.allowDup,f=S(b,bE),n,o=bA(f);if(typeof d!=q)d=e;g=!(!g);if(!g&&((Q[f]!=e)||(s&&m[f])||bB(f))){if(m[f]!=e&&m[f][j]&&!m[f][y]&&o){W(e,m[f],h)}return}if(m[f]==e)m[f]={};n=m[f];if(n[z]==e)n[z]=bD;n[y]=i;n[J]=f;T=h;if(!F&&bl&&o)br(n,f,c,d);else if(!F&&bk)bq(n,f,c,d);else bp(n,f,c,d)}function bt(a){U.push(a)}function Y(a){if(v&&!F)bt(a);if(!v||B)a()}function bu(a){var b=[],c;for(c=-1;++c<a.length;){if(O.call(a[c])===bx)b=b.concat(bu(a[c]));else b[b.length]=a[c]}return b}G={script:function(){bd(V);var a=bu(arguments),b=G,c;if(bC){for(c=-1;++c<a.length;){if(c===0){Y(function(){bs((typeof a[0]==q)?{src:a[0]}:a[0])})}else b=b.script(a[c]);b=b.wait()}}else{Y(function(){for(c=-1;++c<a.length;){bs((typeof a[c]==q)?{src:a[c]}:a[c])}})}V=A(function(){s=i},5);return b},wait:function(a){bd(V);s=i;if(!R(a))a=P;var b=E(h,l),c=b.trigger,d=function(){try{a()}catch(err){}c()};delete b.trigger;var g=function(){if(T&&!bj)bm=d;else d()};if(v&&!T)bt(g);else Y(g);return b}};if(v){G.trigger=function(){var a,b=-1;while(a=U[++b])a();U=[]}}return G}function bv(a){var b,c={},d={"UseCachePreload":"cache","UseLocalXHR":"xhr","UsePreloading":C,"AlwaysPreserveOrder":K,"AllowDuplicates":"dupe"},g={"AppendTo":z,"BasePath":"base"};for(b in d)g[b]=d[b];c.order=!(!u.order);for(b in g){if(g[L](b)&&u[g[b]]!=e)c[g[b]]=(a[b]!=e)?a[b]:u[g[b]]}for(b in d){if(d[L](b))c[d[b]]=!(!c[d[b]])}if(!c[C])c.cache=c.order=c.xhr=i;c.which=(c.which===w||c.which===H)?c.which:w;return c}p.$LAB={setGlobalDefaults:function(a){u=bv(a)},setOptions:function(a){return E(i,bv(a))},script:function(){return E().script.apply(e,arguments)},wait:function(){return E().wait.apply(e,arguments)}};(function(a,b,c){if(k[t]==e&&k[a]){k[t]="loading";k[a](b,c=function(){k.removeEventListener(b,c,i);k[t]=Z},i)}})("addEventListener","DOMContentLoaded")})(window);

window.embedding_flag = true;
var optemo_module, remote, REMOTE = 'http://ast0.optemo.com'; // static globals

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
		remote: REMOTE + "/socket.html?serverName="+ escape(REMOTE.replace(/http:\/\//,'')),
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
					embed_tag.children().each(function(){ jQuery(this).remove();});
				}

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
	                } else if (typeof(srcs) == "object" && srcs[0] && srcs[0].match(/easyXDM/)){
						 scripts[i] = ''; // so it will get taken out completely later
					} else {
	                    script_nodes_to_append.push(REMOTE + "/" + srcs);
	                    scripts[i] = '';
	                }
	            // When zipping stuff back up, we want to take out the /script tag *unless* there was a null response.
	            }

				// We have to load all scripts in order, hence the call to labJS wait() function
                $LAB.script(script_nodes_to_append).wait(function () {
    				optemo_module.embeddedString = REMOTE;
    				optemo_module.FilterAndSearchInit();
    				optemo_module.DBinit();                    
                });


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
		                if (srcs == null) { // no stylesheets
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
	            data_to_append = parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));

				// Now strip out any erroneous tags.
				regexp_patterns = ["<\/?html[^>]*>", "<!doctype[^>]+>", "<meta[^>]*>", "<\/?body[^>]*>", "<\/?head>", "<title>[^<]*<\/title>"];
				for (i = 0; i < regexp_patterns.length; i++) {
					data_to_append = data_to_append.replace(new RegExp(regexp_patterns[i], "gi"), '');
				}
				// Make that it's a normal return value the easy way, by looking for the word "filterbar," 
				// which is supposed to come back with each rendering of ajax.html.erb
				if (data_to_append.match(/filterbar/i)) 
    				embed_tag.append(data_to_append);
    			
    			// Take the silkscreen and filter_bar_loading divs and move them to the main body tag.
    			// This is important for positioning if there are relative divs, because otherwise the absolute
    			// positioning is done relative to that div instead of the whole window. This deprecated code is kept here just in case it's an issue later.
    			
                // detaching_array = ['#silkscreen', '#filter_bar_loading', '#outsidecontainer', '#popupTour1', '#popupTour2', '#popupTour3', '#popupTour4'];
                // for (var i = 0; i < detaching_array.length; i++) {
                //     var element = jQuery(detaching_array[i]);
                //     if (element.length > 0) element.detach().appendTo('body');
                // }
		    },
			parseData: function (data) {
	            data_to_append = parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));
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
            if (images[i].match(new RegExp("http:\/\/"))) 
                data_to_append.push(images[i]);
            else
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
} catch(err) {
    var jQueryIsLoaded = false;
}

if(jQueryIsLoaded) {
    $LAB.script(REMOTE + '/javascripts/easyXDM.min.js').wait(function () {
        optemo_socket_activator(); 
    });
} else {
    $LAB.script('http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js').script(REMOTE + '/javascripts/easyXDM.min.js').wait(function () {
        optemo_socket_activator();
    });
}

// This is the call that gets the socket open. It's important to do this serially, in three steps:
// (1) Load XDM, (2) load jQuery, if necessary, (3) load everything else. This is for dependency reasons (eliminate race conditions).
