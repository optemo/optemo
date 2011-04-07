/* To create a website that embeds the Optemo Assist or Direct interface, create an HTML file on any server and insert the following:

In the <head>: 
<script src="http://bbembed.optemo.com/optemo_embedder.js" type="text/javascript"></script>

In the <body>:
<div id="optemo_embedder"></div>

This script will auto-load various javascript files from the server, embed an iframe into the website, and load the interface via AJAX (not usually possible due to cross-site restrictions, but implemented using easyXDM, http://easyxdm.net/)

This script could be minified for better performance. The asset packager combines and compresses the application javascript, but this file
does not get minified by the capistrano deployment at the moment. */

window.embedding_flag = true; // This is used in application.js to decide whether to redefine the AJAX functions
// These static globals are used in application.js and below. 'remote' is defined so that application.js can call it later
var optemo_module, remote, REMOTE = 'http://bbembed.optemo.com';

// Wrapping this function and assigning it to a variable delays execution of evaluation
var optemo_socket_activator = (function () {
    /**
     * Request the use of the JSON object
     */
     if (jQuery && jQuery('#optemo_embedder_socket').length == 0) { // Sometimes the script will try to open the socket twice.
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
    		// To remove the hard-coded ast0.optemo.com in socket.html, you will need to pass
    		// in the appropriate server name here
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
    		    * Call the initial loading method on the other side; this gets the frame
    		    */
    			remote.initialLoad(); // try taking out empty function, maybe it's causing weirdness?
    		}
    	}, /** The interface configuration */ {
    		remote: {
    			initialLoad: {},
    		    iframecall: {},
    			quickiframecall: {}
    		},
    		local: {
    		    initialPageDelivery: function(data){ // This is the parser for the initial load. It's only used when an entire request comes back, <html> and all, probably from the optemo.html.erb layout.
    				embed_tag = jQuery('#optemo_embedder');
    				if (embed_tag.children().length > 0) 
    				{
    					embed_tag.children().each(function(){ jQuery(this).remove();});
    				}

    	            var regexp_pattern, data_to_add, data_to_append, scripts, headID = document.getElementsByTagName("head")[0], scripts_to_load, i, images;
    	            // Take out all the scripts, load them on the client (consumer) page in the HEAD tag, and put the data back together
    	            regexp_pattern = (/<script[^>]+>/g);
    	            scripts = data.match(regexp_pattern);
    	            data_to_add = data.split(regexp_pattern);
    	            script_nodes_to_append = Array();
    	            for (var i = 0; i < scripts.length; i++)
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

    				// We have to load all scripts in order, but using labJS is too heavy. So, we do a recursive serial loader function.
    				// Although serial should == slow, the javascript we're loading should only be one file in production.
    				// The purpose of having this multiple-script functionality is for development mode.    				
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
                                        finish_loading();
                                    }
                                };
                            } else {  //Others
                                script.onload = function(){
                                    finish_loading();
                                };
                            }
                        }		    
                        script.setAttribute("src", script_nodes_to_append[i]);
                        document.getElementsByTagName("head")[0].appendChild(script);
				    })(0);
    				
    				function finish_loading() {
        				// By this point we can guarantee that everything loaded serially.
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
        		                    // For now, take the CSS file out totally for laserprinterhub.com deployment.
        		                    headID.appendChild(tag);
        		                }
        		            }
        		            data_to_append = data_to_add.join("\n");
        				}
        	            // Process images next. To do this, just find all the images, split the data as before, and change the src tag.
        	            data_to_append = parse_data_by_pattern(data_to_append, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));

        				// Now strip out any erroneous tags.
        				regexp_patterns = ["<\/?html[^>]*>", "<!doctype[^>]+>", "<meta[^>]*>", "<\/?body[^>]*>", "<\/?head>", "<title>[^<]*<\/title>"];
        				for (i = 0; i < regexp_patterns.length; i++) {
        					data_to_append = data_to_append.replace(new RegExp(regexp_patterns[i], "gi"), '');
        				}
        				// Make that it's a normal return value the easy way, by looking for the word "filterbar," 
        				// which is supposed to come back with each rendering of ajax.html.erb
        				if (data_to_append.match(/filterbar/i)) {
            				embed_tag.append(data_to_append);
        				}
			
            			// Take the silkscreen and filter_bar_loading divs and move them to the main body tag.
            			// This is important for positioning if there are relative divs, because otherwise the absolute
            			// positioning is done relative to that div instead of the whole window. This deprecated code is kept here just in case it's an issue later.
                        // detaching_array = ['#silkscreen', '#filter_bar_loading', '#outsidecontainer', '#popupTour1', '#popupTour2', '#popupTour3', '#popupTour4'];
                        // for (var i = 0; i < detaching_array.length; i++) {
                        //     var element = jQuery(detaching_array[i]);
                        //     if (element.length > 0) element.detach().appendTo('body');
                        // }
                    
                        // The javascript is getting appended first, so that means these variables won't be initialized properly.
                        // To correct this, move variable initialization into DBinit() or else append HTML before loading scripts.
                        // Latter is a good idea because the user would see something load earlier than now.
                        // In that case, remove the following lines
                        
                        // Using setTimeout to fix an IE race condition. Spinner code will be redone hopefully sooner rather than later anyway, right?
                        setTimeout("myspinner = new optemo_module.spinner(\"myspinner\", 11, 20, 9, 5, \"#000\")", 800);
                        optemo_module.IS_DRAG_DROP_ENABLED = (jQuery("#dragDropEnabled").html() === 'true');
                        optemo_module.MODEL_NAME = jQuery("#modelname").html();
                        optemo_module.DIRECT_LAYOUT = (jQuery('#directLayout').html() == "true");                    
                        optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
                        // Do we need to copy over other variables? AB_TESTING_TYPE and a couple others are locally scoped to optemo_module
                    
                    }
    		    },
    			parseData: function (data) {
    	            var data_to_append = parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));
    				optemo_module.ajaxhandler(data_to_append);
    			},
    			parseDataThin: function (element_name, data, fn) {
    				var data = parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));
    				jQuery(element_name).html(data);
    				fn(); // This is probably DBInit(), but could be anything
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
	
	}		
});

// This must be loaded first in IE and Opera 10.1
if (!(typeof(window["JSON"]) == 'object' && window["JSON"])) {
    // JSON evaluated directly rather than as a separate file to avoid race conditions
    if(!this.JSON){this.JSON={};}
    (function(){function f(n){return n<10?'0'+n:n;}
    if(typeof Date.prototype.toJSON!=='function'){Date.prototype.toJSON=function(key){return isFinite(this.valueOf())?this.getUTCFullYear()+'-'+
    f(this.getUTCMonth()+1)+'-'+
    f(this.getUTCDate())+'T'+
    f(this.getUTCHours())+':'+
    f(this.getUTCMinutes())+':'+
    f(this.getUTCSeconds())+'Z':null;};String.prototype.toJSON=Number.prototype.toJSON=Boolean.prototype.toJSON=function(key){return this.valueOf();};}
    var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={'\b':'\\b','\t':'\\t','\n':'\\n','\f':'\\f','\r':'\\r','"':'\\"','\\':'\\\\'},rep;function quote(string){escapable.lastIndex=0;return escapable.test(string)?'"'+string.replace(escapable,function(a){var c=meta[a];return typeof c==='string'?c:'\\u'+('0000'+a.charCodeAt(0).toString(16)).slice(-4);})+'"':'"'+string+'"';}
    function str(key,holder){var i,k,v,length,mind=gap,partial,value=holder[key];if(value&&typeof value==='object'&&typeof value.toJSON==='function'){value=value.toJSON(key);}
    if(typeof rep==='function'){value=rep.call(holder,key,value);}
    switch(typeof value){case'string':return quote(value);case'number':return isFinite(value)?String(value):'null';case'boolean':case'null':return String(value);case'object':if(!value){return'null';}
    gap+=indent;partial=[];if(Object.prototype.toString.apply(value)==='[object Array]'){length=value.length;for(i=0;i<length;i+=1){partial[i]=str(i,value)||'null';}
    v=partial.length===0?'[]':gap?'[\n'+gap+
    partial.join(',\n'+gap)+'\n'+
    mind+']':'['+partial.join(',')+']';gap=mind;return v;}
    if(rep&&typeof rep==='object'){length=rep.length;for(i=0;i<length;i+=1){k=rep[i];if(typeof k==='string'){v=str(k,value);if(v){partial.push(quote(k)+(gap?': ':':')+v);}}}}else{for(k in value){if(Object.hasOwnProperty.call(value,k)){v=str(k,value);if(v){partial.push(quote(k)+(gap?': ':':')+v);}}}}
    v=partial.length===0?'{}':gap?'{\n'+gap+partial.join(',\n'+gap)+'\n'+
    mind+'}':'{'+partial.join(',')+'}';gap=mind;return v;}}
    if(typeof JSON.stringify!=='function'){JSON.stringify=function(value,replacer,space){var i;gap='';indent='';if(typeof space==='number'){for(i=0;i<space;i+=1){indent+=' ';}}else if(typeof space==='string'){indent=space;}
    rep=replacer;if(replacer&&typeof replacer!=='function'&&(typeof replacer!=='object'||typeof replacer.length!=='number')){throw new Error('JSON.stringify');}
    return str('',{'':value});};}
    if(typeof JSON.parse!=='function'){JSON.parse=function(text,reviver){var j;function walk(holder,key){var k,v,value=holder[key];if(value&&typeof value==='object'){for(k in value){if(Object.hasOwnProperty.call(value,k)){v=walk(value,k);if(v!==undefined){value[k]=v;}else{delete value[k];}}}}
    return reviver.call(holder,key,value);}
    text=String(text);cx.lastIndex=0;if(cx.test(text)){text=text.replace(cx,function(a){return'\\u'+
    ('0000'+a.charCodeAt(0).toString(16)).slice(-4);});}
    if(/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,'@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,']').replace(/(?:^|:|,)(?:\s*\[)+/g,''))){j=eval('('+text+')');return typeof reviver==='function'?walk({'':j},''):j;}
    throw new SyntaxError('JSON.parse');};}}());
}

/**
 * easyXDM
 * http://easyxdm.net/
 * Copyright(c) 2009-2011, Øyvind Sean Kinsey, oyvind@kinsey.no.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
(function(J,c,l,G,g,D){var b=this;var j=Math.floor(Math.random()*100)*100;var m=Function.prototype;var M=/^((http.?:)\/\/([^:\/\s]+)(:\d+)*)/;var N=/[\-\w]+\/\.\.\//;var B=/([^:])\/\//g;var E="";var k={};var I=J.easyXDM;var Q="easyXDM_";var A;var u=false;function y(T,V){var U=typeof T[V];return U=="function"||(!!(U=="object"&&T[V]))||U=="unknown"}function q(T,U){return !!(typeof(T[U])=="object"&&T[U])}function n(T){return Object.prototype.toString.call(T)==="[object Array]"}var r,t;if(y(J,"addEventListener")){r=function(V,T,U){V.addEventListener(T,U,false)};t=function(V,T,U){V.removeEventListener(T,U,false)}}else{if(y(J,"attachEvent")){r=function(T,V,U){T.attachEvent("on"+V,U)};t=function(T,V,U){T.detachEvent("on"+V,U)}}else{throw new Error("Browser not supported")}}var S=false,F=[],H;if("readyState" in c){H=c.readyState;S=H=="complete"||(~navigator.userAgent.indexOf("AppleWebKit/")&&(H=="loaded"||H=="interactive"))}else{S=!!c.body}function o(){o=m;S=true;for(var T=0;T<F.length;T++){F[T]()}F.length=0}if(!S){if(y(J,"addEventListener")){r(c,"DOMContentLoaded",o)}else{r(c,"readystatechange",function(){if(c.readyState=="complete"){o()}});if(c.documentElement.doScroll&&J===top){(function e(){if(S){return}try{c.documentElement.doScroll("left")}catch(T){G(e,1);return}o()}())}}r(J,"load",o)}function C(U,T){if(S){U.call(T);return}F.push(function(){U.call(T)})}function i(){var V=parent;if(E!==""){for(var T=0,U=E.split(".");T<U.length;T++){V=V[U[T]]}}return V.easyXDM}function d(T){J.easyXDM=I;E=T;if(E){Q="easyXDM_"+E.replace(".","_")+"_"}return k}function v(T){return T.match(M)[3]}function f(V){var T=V.match(M);var W=T[2],X=T[3],U=T[4]||"";if((W=="http:"&&U==":80")||(W=="https:"&&U==":443")){U=""}return W+"//"+X+U}function x(T){T=T.replace(B,"$1/");if(!T.match(/^(http||https):\/\//)){var U=(T.substring(0,1)==="/")?"":l.pathname;if(U.substring(U.length-1)!=="/"){U=U.substring(0,U.lastIndexOf("/")+1)}T=l.protocol+"//"+l.host+U+T}while(N.test(T)){T=T.replace(N,"")}return T}function L(T,W){var Y="",V=T.indexOf("#");if(V!==-1){Y=T.substring(V);T=T.substring(0,V)}var X=[];for(var U in W){if(W.hasOwnProperty(U)){X.push(U+"="+D(W[U]))}}return T+(u?"#":(T.indexOf("?")==-1?"?":"&"))+X.join("&")+Y}var O=(function(T){T=T.substring(1).split("&");var V={},W,U=T.length;while(U--){W=T[U].split("=");V[W[0]]=g(W[1])}return V}(/xdm_e=/.test(l.search)?l.search:l.hash));function p(T){return typeof T==="undefined"}function K(){var U={};var V={a:[1,2,3]},T='{"a":[1,2,3]}';if(JSON&&typeof JSON.stringify==="function"&&JSON.stringify(V).replace((/\s/g),"")===T){return JSON}if(Object.toJSON){if(Object.toJSON(V).replace((/\s/g),"")===T){U.stringify=Object.toJSON}}if(typeof String.prototype.evalJSON==="function"){V=T.evalJSON();if(V.a&&V.a.length===3&&V.a[2]===3){U.parse=function(W){return W.evalJSON()}}}if(U.stringify&&U.parse){K=function(){return U};return U}return null}function P(T,U,V){var X;for(var W in U){if(U.hasOwnProperty(W)){if(W in T){X=U[W];if(typeof X==="object"){P(T[W],X,V)}else{if(!V){T[W]=U[W]}}}else{T[W]=U[W]}}}return T}function a(){var T=c.createElement("iframe");T.name=Q+"TEST";P(T.style,{position:"absolute",left:"-2000px",top:"0px"});c.body.appendChild(T);A=!(T.contentWindow===J.frames[T.name]);c.body.removeChild(T)}function w(T){if(p(A)){a()}var V;if(A){V=c.createElement('<iframe name="'+T.props.name+'"/>')}else{V=c.createElement("IFRAME");V.name=T.props.name}V.id=V.name=T.props.name;delete T.props.name;if(T.onLoad){r(V,"load",T.onLoad)}if(typeof T.container=="string"){T.container=c.getElementById(T.container)}if(!T.container){V.style.position="absolute";V.style.top="-2000px";T.container=c.body}var U=T.props.src;delete T.props.src;P(V,T.props);V.border=V.frameBorder=0;T.container.appendChild(V);V.src=U;T.props.src=U;return V}function R(W,V){if(typeof W=="string"){W=[W]}var U,T=W.length;while(T--){U=W[T];U=new RegExp(U.substr(0,1)=="^"?U:("^"+U.replace(/(\*)/g,".$1").replace(/\?/g,".")+"$"));if(U.test(V)){return true}}return false}function h(V){var aa=V.protocol,U;V.isHost=V.isHost||p(O.xdm_p);u=V.hash||false;if(!V.props){V.props={}}if(!V.isHost){V.channel=O.xdm_c;V.secret=O.xdm_s;V.remote=O.xdm_e;aa=O.xdm_p;if(V.acl&&!R(V.acl,V.remote)){throw new Error("Access denied for "+V.remote)}}else{V.remote=x(V.remote);V.channel=V.channel||"default"+j++;V.secret=Math.random().toString(16).substring(2);if(p(aa)){if(f(l.href)==f(V.remote)){aa="4"}else{if(y(J,"postMessage")||y(c,"postMessage")){aa="1"}else{if(y(J,"ActiveXObject")&&y(J,"execScript")){aa="3"}else{if(navigator.product==="Gecko"&&"frameElement" in J&&navigator.userAgent.indexOf("WebKit")==-1){aa="5"}else{if(V.remoteHelper){V.remoteHelper=x(V.remoteHelper);aa="2"}else{aa="0"}}}}}}}switch(aa){case"0":P(V,{interval:100,delay:2000,useResize:true,useParent:false,usePolling:false},true);if(V.isHost){if(!V.local){var Y=l.protocol+"//"+l.host,T=c.body.getElementsByTagName("img"),Z;var W=T.length;while(W--){Z=T[W];if(Z.src.substring(0,Y.length)===Y){V.local=Z.src;break}}if(!V.local){V.local=J}}var X={xdm_c:V.channel,xdm_p:0};if(V.local===J){V.usePolling=true;V.useParent=true;V.local=l.protocol+"//"+l.host+l.pathname+l.search;X.xdm_e=V.local;X.xdm_pa=1}else{X.xdm_e=x(V.local)}if(V.container){V.useResize=false;X.xdm_po=1}V.remote=L(V.remote,X)}else{P(V,{channel:O.xdm_c,remote:O.xdm_e,useParent:!p(O.xdm_pa),usePolling:!p(O.xdm_po),useResize:V.useParent?false:V.useResize})}U=[new k.stack.HashTransport(V),new k.stack.ReliableBehavior({}),new k.stack.QueueBehavior({encode:true,maxLength:4000-V.remote.length}),new k.stack.VerifyBehavior({initiate:V.isHost})];break;case"1":U=[new k.stack.PostMessageTransport(V)];break;case"2":U=[new k.stack.NameTransport(V),new k.stack.QueueBehavior(),new k.stack.VerifyBehavior({initiate:V.isHost})];break;case"3":U=[new k.stack.NixTransport(V)];break;case"4":U=[new k.stack.SameOriginTransport(V)];break;case"5":U=[new k.stack.FrameElementTransport(V)];break}U.push(new k.stack.QueueBehavior({lazy:V.lazy,remove:true}));return U}function z(W){var X,V={incoming:function(Z,Y){this.up.incoming(Z,Y)},outgoing:function(Y,Z){this.down.outgoing(Y,Z)},callback:function(Y){this.up.callback(Y)},init:function(){this.down.init()},destroy:function(){this.down.destroy()}};for(var U=0,T=W.length;U<T;U++){X=W[U];P(X,V,true);if(U!==0){X.down=W[U-1]}if(U!==T-1){X.up=W[U+1]}}return X}function s(T){T.up.down=T.down;T.down.up=T.up;T.up=T.down=null}P(k,{version:"2.4.11.104",query:O,stack:{},apply:P,getJSONObject:K,whenReady:C,noConflict:d});k.DomHelper={on:r,un:t,requiresJSON:function(T){if(!q(J,"JSON")){c.write('<script type="text/javascript" src="'+T+'"><\/script>')}}};(function(){var T={};k.Fn={set:function(U,V){T[U]=V},get:function(V,U){var W=T[V];if(U){delete T[V]}return W}}}());k.Socket=function(U){var T=z(h(U).concat([{incoming:function(X,W){U.onMessage(X,W)},callback:function(W){if(U.onReady){U.onReady(W)}}}])),V=f(U.remote);this.origin=f(U.remote);this.destroy=function(){T.destroy()};this.postMessage=function(W){T.outgoing(W,V)};T.init()};k.Rpc=function(V,U){if(U.local){for(var X in U.local){if(U.local.hasOwnProperty(X)){var W=U.local[X];if(typeof W==="function"){U.local[X]={method:W}}}}}var T=z(h(V).concat([new k.stack.RpcBehavior(this,U),{callback:function(Y){if(V.onReady){V.onReady(Y)}}}]));this.origin=f(V.remote);this.destroy=function(){T.destroy()};T.init()};k.stack.SameOriginTransport=function(U){var V,X,W,T;return(V={outgoing:function(Z,aa,Y){W(Z);if(Y){Y()}},destroy:function(){if(X){X.parentNode.removeChild(X);X=null}},onDOMReady:function(){T=f(U.remote);if(U.isHost){P(U.props,{src:L(U.remote,{xdm_e:l.protocol+"//"+l.host+l.pathname,xdm_c:U.channel,xdm_p:4}),name:Q+U.channel+"_provider"});X=w(U);k.Fn.set(U.channel,function(Y){W=Y;G(function(){V.up.callback(true)},0);return function(Z){V.up.incoming(Z,T)}})}else{W=i().Fn.get(U.channel,true)(function(Y){V.up.incoming(Y,T)});G(function(){V.up.callback(true)},0)}},init:function(){C(V.onDOMReady,V)}})};k.stack.PostMessageTransport=function(W){var Y,Z,U,V;function T(aa){if(aa.origin){return f(aa.origin)}if(aa.uri){return f(aa.uri)}if(aa.domain){return l.protocol+"//"+aa.domain}throw"Unable to retrieve the origin of the event"}function X(ab){var aa=T(ab);if(aa==V&&ab.data.substring(0,W.channel.length+1)==W.channel+" "){Y.up.incoming(ab.data.substring(W.channel.length+1),aa)}}return(Y={outgoing:function(ab,ac,aa){U.postMessage(W.channel+" "+ab,ac||V);if(aa){aa()}},destroy:function(){t(J,"message",X);if(Z){U=null;Z.parentNode.removeChild(Z);Z=null}},onDOMReady:function(){V=f(W.remote);if(W.isHost){r(J,"message",function aa(ab){if(ab.data==W.channel+"-ready"){U=("postMessage" in Z.contentWindow)?Z.contentWindow:Z.contentWindow.document;t(J,"message",aa);r(J,"message",X);G(function(){Y.up.callback(true)},0)}});P(W.props,{src:L(W.remote,{xdm_e:f(l.href),xdm_c:W.channel,xdm_p:1}),name:Q+W.channel+"_provider"});Z=w(W)}else{r(J,"message",X);U=("postMessage" in J.parent)?J.parent:J.parent.document;U.postMessage(W.channel+"-ready",V);G(function(){Y.up.callback(true)},0)}},init:function(){C(Y.onDOMReady,Y)}})};k.stack.FrameElementTransport=function(U){var V,X,W,T;return(V={outgoing:function(Z,aa,Y){W.call(this,Z);if(Y){Y()}},destroy:function(){if(X){X.parentNode.removeChild(X);X=null}},onDOMReady:function(){T=f(U.remote);if(U.isHost){P(U.props,{src:L(U.remote,{xdm_e:f(l.href),xdm_c:U.channel,xdm_p:5}),name:Q+U.channel+"_provider"});X=w(U);X.fn=function(Y){delete X.fn;W=Y;G(function(){V.up.callback(true)},0);return function(Z){V.up.incoming(Z,T)}}}else{if(c.referrer&&f(c.referrer)!=O.xdm_e){J.parent.location=O.xdm_e}W=J.frameElement.fn(function(Y){V.up.incoming(Y,T)});V.up.callback(true)}},init:function(){C(V.onDOMReady,V)}})};k.stack.NixTransport=function(U){var W,Y,X,T,V;return(W={outgoing:function(aa,ab,Z){X(aa);if(Z){Z()}},destroy:function(){V=null;if(Y){Y.parentNode.removeChild(Y);Y=null}},onDOMReady:function(){T=f(U.remote);if(U.isHost){try{if(!y(J,"getNixProxy")){J.execScript("Class NixProxy\n    Private m_parent, m_child, m_Auth\n\n    Public Sub SetParent(obj, auth)\n        If isEmpty(m_Auth) Then m_Auth = auth\n        SET m_parent = obj\n    End Sub\n    Public Sub SetChild(obj)\n        SET m_child = obj\n        m_parent.ready()\n    End Sub\n\n    Public Sub SendToParent(data, auth)\n        If m_Auth = auth Then m_parent.send(CStr(data))\n    End Sub\n    Public Sub SendToChild(data, auth)\n        If m_Auth = auth Then m_child.send(CStr(data))\n    End Sub\nEnd Class\nFunction getNixProxy()\n    Set GetNixProxy = New NixProxy\nEnd Function\n","vbscript")}V=getNixProxy();V.SetParent({send:function(ab){W.up.incoming(ab,T)},ready:function(){G(function(){W.up.callback(true)},0)}},U.secret);X=function(ab){V.SendToChild(ab,U.secret)}}catch(aa){throw new Error("Could not set up VBScript NixProxy:"+aa.message)}P(U.props,{src:L(U.remote,{xdm_e:f(l.href),xdm_c:U.channel,xdm_s:U.secret,xdm_p:3}),name:Q+U.channel+"_provider"});Y=w(U);Y.contentWindow.opener=V}else{if(c.referrer&&f(c.referrer)!=O.xdm_e){J.parent.location=O.xdm_e}try{V=J.opener}catch(Z){throw new Error("Cannot access window.opener")}V.SetChild({send:function(ab){b.setTimeout(function(){W.up.incoming(ab,T)},0)}});X=function(ab){V.SendToParent(ab,U.secret)};G(function(){W.up.callback(true)},0)}},init:function(){C(W.onDOMReady,W)}})};k.stack.NameTransport=function(X){var Y;var aa,ae,W,ac,ad,U,T;function ab(ah){var ag=X.remoteHelper+(aa?"#_3":"#_2")+X.channel;ae.contentWindow.sendMessage(ah,ag)}function Z(){if(aa){if(++ac===2||!aa){Y.up.callback(true)}}else{ab("ready");Y.up.callback(true)}}function af(ag){Y.up.incoming(ag,U)}function V(){if(ad){G(function(){ad(true)},0)}}return(Y={outgoing:function(ah,ai,ag){ad=ag;ab(ah)},destroy:function(){ae.parentNode.removeChild(ae);ae=null;if(aa){W.parentNode.removeChild(W);W=null}},onDOMReady:function(){aa=X.isHost;ac=0;U=f(X.remote);X.local=x(X.local);if(aa){k.Fn.set(X.channel,function(ah){if(aa&&ah==="ready"){k.Fn.set(X.channel,af);Z()}});T=L(X.remote,{xdm_e:X.local,xdm_c:X.channel,xdm_p:2});P(X.props,{src:T+"#"+X.channel,name:Q+X.channel+"_provider"});W=w(X)}else{X.remoteHelper=X.remote;k.Fn.set(X.channel,af)}ae=w({props:{src:X.local+"#_4"+X.channel},onLoad:function ag(){var ah=ae||this;t(ah,"load",ag);k.Fn.set(X.channel+"_load",V);(function ai(){if(typeof ah.contentWindow.sendMessage=="function"){Z()}else{G(ai,50)}}())}})},init:function(){C(Y.onDOMReady,Y)}})};k.stack.HashTransport=function(V){var Y;var ad=this,ab,W,T,Z,ai,X,ah;var ac,U;function ag(ak){if(!ah){return}var aj=V.remote+"#"+(ai++)+"_"+ak;((ab||!ac)?ah.contentWindow:ah).location=aj}function aa(aj){Z=aj;Y.up.incoming(Z.substring(Z.indexOf("_")+1),U)}function af(){if(!X){return}var aj=X.location.href,al="",ak=aj.indexOf("#");if(ak!=-1){al=aj.substring(ak)}if(al&&al!=Z){aa(al)}}function ae(){W=setInterval(af,T)}return(Y={outgoing:function(aj,ak){ag(aj)},destroy:function(){J.clearInterval(W);if(ab||!ac){ah.parentNode.removeChild(ah)}ah=null},onDOMReady:function(){ab=V.isHost;T=V.interval;Z="#"+V.channel;ai=0;ac=V.useParent;U=f(V.remote);if(ab){V.props={src:V.remote,name:Q+V.channel+"_provider"};if(ac){V.onLoad=function(){X=J;ae();Y.up.callback(true)}}else{var al=0,aj=V.delay/50;(function ak(){if(++al>aj){throw new Error("Unable to reference listenerwindow")}try{X=ah.contentWindow.frames[Q+V.channel+"_consumer"]}catch(am){}if(X){ae();Y.up.callback(true)}else{G(ak,50)}}())}ah=w(V)}else{X=J;ae();if(ac){ah=parent;Y.up.callback(true)}else{P(V,{props:{src:V.remote+"#"+V.channel+new Date(),name:Q+V.channel+"_consumer"},onLoad:function(){Y.up.callback(true)}});ah=w(V)}}},init:function(){C(Y.onDOMReady,Y)}})};k.stack.ReliableBehavior=function(U){var W,Y;var X=0,T=0,V="";return(W={incoming:function(ab,Z){var aa=ab.indexOf("_"),ac=ab.substring(0,aa).split(",");ab=ab.substring(aa+1);if(ac[0]==X){V="";if(Y){Y(true)}}if(ab.length>0){W.down.outgoing(ac[1]+","+X+"_"+V,Z);if(T!=ac[1]){T=ac[1];W.up.incoming(ab,Z)}}},outgoing:function(ab,Z,aa){V=ab;Y=aa;W.down.outgoing(T+","+(++X)+"_"+ab,Z)}})};k.stack.QueueBehavior=function(V){var Y,Z=[],ac=true,W="",ab,T=0,U=false,X=false;function aa(){if(V.remove&&Z.length===0){s(Y);return}if(ac||Z.length===0||ab){return}ac=true;var ad=Z.shift();Y.down.outgoing(ad.data,ad.origin,function(ae){ac=false;if(ad.callback){G(function(){ad.callback(ae)},0)}aa()})}return(Y={init:function(){if(p(V)){V={}}if(V.maxLength){T=V.maxLength;X=true}if(V.lazy){U=true}else{Y.down.init()}},callback:function(ae){ac=false;var ad=Y.up;aa();ad.callback(ae)},incoming:function(ag,ae){if(X){var af=ag.indexOf("_"),ad=parseInt(ag.substring(0,af),10);W+=ag.substring(af+1);if(ad===0){if(V.encode){W=g(W)}Y.up.incoming(W,ae);W=""}}else{Y.up.incoming(ag,ae)}},outgoing:function(ah,ae,ag){if(V.encode){ah=D(ah)}var ad=[],af;if(X){while(ah.length!==0){af=ah.substring(0,T);ah=ah.substring(af.length);ad.push(af)}while((af=ad.shift())){Z.push({data:ad.length+"_"+af,origin:ae,callback:ad.length===0?ag:null})}}else{Z.push({data:ah,origin:ae,callback:ag})}if(U){Y.down.init()}else{aa()}},destroy:function(){ab=true;Y.down.destroy()}})};k.stack.VerifyBehavior=function(X){var Y,W,U,V=false;function T(){W=Math.random().toString(16).substring(2);Y.down.outgoing(W)}return(Y={incoming:function(ab,Z){var aa=ab.indexOf("_");if(aa===-1){if(ab===W){Y.up.callback(true)}else{if(!U){U=ab;if(!X.initiate){T()}Y.down.outgoing(ab)}}}else{if(ab.substring(0,aa)===U){Y.up.incoming(ab.substring(aa+1),Z)}}},outgoing:function(ab,Z,aa){Y.down.outgoing(W+"_"+ab,Z,aa)},callback:function(Z){if(X.initiate){T()}}})};k.stack.RpcBehavior=function(Z,U){var W,ab=U.serializer||K();var aa=0,Y={};function T(ac){ac.jsonrpc="2.0";W.down.outgoing(ab.stringify(ac))}function X(ac,ae){var ad=Array.prototype.slice;return function(){var af=arguments.length,ah,ag={method:ae};if(af>0&&typeof arguments[af-1]==="function"){if(af>1&&typeof arguments[af-2]==="function"){ah={success:arguments[af-2],error:arguments[af-1]};ag.params=ad.call(arguments,0,af-2)}else{ah={success:arguments[af-1]};ag.params=ad.call(arguments,0,af-1)}Y[""+(++aa)]=ah;ag.id=aa}else{ag.params=ad.call(arguments,0)}if(ac.namedParams&&ag.params.length===1){ag.params=ag.params[0]}T(ag)}}function V(aj,ai,ae,ah){if(!ae){if(ai){T({id:ai,error:{code:-32601,message:"Procedure not found."}})}return}var ag,ad;if(ai){ag=function(ak){ag=m;T({id:ai,result:ak})};ad=function(ak,al){ad=m;var am={id:ai,error:{code:-32099,message:ak}};if(al){am.error.data=al}T(am)}}else{ag=ad=m}if(!n(ah)){ah=[ah]}try{var ac=ae.method.apply(ae.scope,ah.concat([ag,ad]));if(!p(ac)){ag(ac)}}catch(af){ad(af.message)}}return(W={incoming:function(ad,ac){var ae=ab.parse(ad);if(ae.method){if(U.handle){U.handle(ae,T)}else{V(ae.method,ae.id,U.local[ae.method],ae.params)}}else{var af=Y[ae.id];if(ae.error){if(af.error){af.error(ae.error)}}else{if(af.success){af.success(ae.result)}}delete Y[ae.id]}},init:function(){if(U.remote){for(var ac in U.remote){if(U.remote.hasOwnProperty(ac)){Z[ac]=X(U.remote[ac],ac)}}}W.down.init()},destroy:function(){for(var ac in U.remote){if(U.remote.hasOwnProperty(ac)&&Z.hasOwnProperty(ac)){delete Z[ac]}}W.down.destroy()}})};b.easyXDM=k})(window,document,location,window.setTimeout,decodeURIComponent,encodeURIComponent);

// Load jQuery if it's not already loaded.
// The purpose of using a try/catch loop is to avoid Internet Explorer 8 from crashing when assigning an undefined variable.
try {
    var jqueryIsLoaded = jQuery;
    jQueryIsLoaded = true;
} catch(err) {
    var jQueryIsLoaded = false;
}

if(jQueryIsLoaded) {
    optemo_socket_activator(); 
} else {
    var script = document.createElement("script");
    script.setAttribute("type", "text/javascript");
    if (script.readyState){  //IE
        script.onreadystatechange = function(){
            if (script.readyState == "loaded" ||
                    script.readyState == "complete"){
                script.onreadystatechange = null;
                optemo_socket_activator();
            }
        };
    } else {  //Others
        script.onload = function(){
            optemo_socket_activator();
        };
    }    
    script.setAttribute("src", 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js');
    document.getElementsByTagName("head")[0].appendChild(script);
}

