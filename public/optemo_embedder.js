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
var optemo_module, remote, optemo_french = (window.location.pathname.match(/^\/fr-CA/)), REMOTE = 'http://' + ((optemo_french) ? "fr." : "") + 'bbembed.optemo.com';

// Wrapping this function and assigning it to a variable delays execution of evaluation
var optemo_socket_activator = (function () {
    /**
     * Request the use of the JSON object
     */
     if ($('#optemo_embedder_socket').length == 0) { // Sometimes the script will try to open the socket twice.
        $('body').append('<div style="display:none" id="optemo_embedder_socket"></div>');
    	remote = new easyXDM.Rpc(/** The channel configuration */{
    		/**
    		 * Register the url to hash.html, this must be an absolute path
    		 * or a path relative to the root.
    		 * @field
    		 */
    		local: "/name.html",
    		swf: REMOTE + "/easyxdm.swf",
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
    		//container: "optemo_embedder_socket",
    		onReady: function(){
    		   /**
    		    * Call the initial loading method on the other side; this gets the frame. Pass in the location hash in case we need to re-run a search
    		    */
    			remote.initialLoad(location.hash.replace(/^#/, ''));
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
    	                srcs = scripts[i].match(/javascripts[^"]+/); // We might want to make a check for src instead.
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

                        function append_and_initialize() {
                        	if (data_to_append.match(/filterbar/i)) {
                				embed_tag.append(data_to_append);
            				}
			
                            // The javascript is getting appended first, so that means these variables won't be initialized properly.
                            // To correct this, move variable initialization into DBinit() or else append HTML before loading scripts.
                            // Latter is a good idea because the user would see something load earlier than now.
                            // In that case, remove the following lines
                            // Using livequery instead of a setTimeout. This should be better.
                            
                            optemo_module.initiateModuleVariables();
							optemo_module.loadSavedProductsFromCookie();
                            optemo_module.FilterAndSearchInit(); optemo_module.DBinit();    
                        }
                        
                        if ($('#optemo_embedder').length != 0) {
                            append_and_initialize();
                        } else {
                            $('#optemo_embedder').livequery(append_and_initialize());
                        }
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
(function(K,c,m,H,h,E){var b=this;var k=Math.floor(Math.random()*10000);var n=Function.prototype;var N=/^((http.?:)\/\/([^:\/\s]+)(:\d+)*)/;var O=/[\-\w]+\/\.\.\//;var C=/([^:])\/\//g;var F="";var l={};var J=K.easyXDM;var R="easyXDM_";var B;var v=false;function z(V,X){var W=typeof V[X];return W=="function"||(!!(W=="object"&&V[X]))||W=="unknown"}function r(V,W){return !!(typeof(V[W])=="object"&&V[W])}function o(V){return Object.prototype.toString.call(V)==="[object Array]"}function T(W){try{var V=new ActiveXObject(W);V=null;return true}catch(X){return false}}var s,u;if(z(K,"addEventListener")){s=function(X,V,W){X.addEventListener(V,W,false)};u=function(X,V,W){X.removeEventListener(V,W,false)}}else{if(z(K,"attachEvent")){s=function(V,X,W){V.attachEvent("on"+X,W)};u=function(V,X,W){V.detachEvent("on"+X,W)}}else{throw new Error("Browser not supported")}}var U=false,G=[],I;if("readyState" in c){I=c.readyState;U=I=="complete"||(~navigator.userAgent.indexOf("AppleWebKit/")&&(I=="loaded"||I=="interactive"))}else{U=!!c.body}function p(){if(U){return}U=true;for(var V=0;V<G.length;V++){G[V]()}G.length=0}if(!U){if(z(K,"addEventListener")){s(c,"DOMContentLoaded",p)}else{s(c,"readystatechange",function(){if(c.readyState=="complete"){p()}});if(c.documentElement.doScroll&&K===top){(function f(){if(U){return}try{c.documentElement.doScroll("left")}catch(V){H(f,1);return}p()}())}}s(K,"load",p)}function D(W,V){if(U){W.call(V);return}G.push(function(){W.call(V)})}function j(){var X=parent;if(F!==""){for(var V=0,W=F.split(".");V<W.length;V++){X=X[W[V]]}}return X.easyXDM}function d(V){K.easyXDM=J;F=V;if(F){R="easyXDM_"+F.replace(".","_")+"_"}return l}function w(V){return V.match(N)[3]}function e(V){return V.match(N)[4]||""}function g(X){var V=X.match(N);var Y=V[2],Z=V[3],W=V[4]||"";if((Y=="http:"&&W==":80")||(Y=="https:"&&W==":443")){W=""}return Y+"//"+Z+W}function y(V){V=V.replace(C,"$1/");if(!V.match(/^(http||https):\/\//)){var W=(V.substring(0,1)==="/")?"":m.pathname;if(W.substring(W.length-1)!=="/"){W=W.substring(0,W.lastIndexOf("/")+1)}V=m.protocol+"//"+m.host+W+V}while(O.test(V)){V=V.replace(O,"")}return V}function M(V,Y){var aa="",X=V.indexOf("#");if(X!==-1){aa=V.substring(X);V=V.substring(0,X)}var Z=[];for(var W in Y){if(Y.hasOwnProperty(W)){Z.push(W+"="+E(Y[W]))}}return V+(v?"#":(V.indexOf("?")==-1?"?":"&"))+Z.join("&")+aa}var P=(function(V){V=V.substring(1).split("&");var X={},Y,W=V.length;while(W--){Y=V[W].split("=");X[Y[0]]=h(Y[1])}return X}(/xdm_e=/.test(m.search)?m.search:m.hash));function q(V){return typeof V==="undefined"}var L=function(){var W={};var X={a:[1,2,3]},V='{"a":[1,2,3]}';if(typeof JSON!="undefined"&&typeof JSON.stringify==="function"&&JSON.stringify(X).replace((/\s/g),"")===V){return JSON}if(Object.toJSON){if(Object.toJSON(X).replace((/\s/g),"")===V){W.stringify=Object.toJSON}}if(typeof String.prototype.evalJSON==="function"){X=V.evalJSON();if(X.a&&X.a.length===3&&X.a[2]===3){W.parse=function(Y){return Y.evalJSON()}}}if(W.stringify&&W.parse){L=function(){return W};return W}return null};function Q(V,W,X){var Z;for(var Y in W){if(W.hasOwnProperty(Y)){if(Y in V){Z=W[Y];if(typeof Z==="object"){Q(V[Y],Z,X)}else{if(!X){V[Y]=W[Y]}}}else{V[Y]=W[Y]}}}return V}function a(){var V=c.createElement("iframe");V.name=R+"TEST";Q(V.style,{position:"absolute",left:"-2000px",top:"0px"});c.body.appendChild(V);B=V.contentWindow!==K.frames[V.name];c.body.removeChild(V)}function x(V){if(q(B)){a()}var X;if(B){X=c.createElement('<iframe name="'+V.props.name+'"/>')}else{X=c.createElement("IFRAME");X.name=V.props.name}X.id=X.name=V.props.name;delete V.props.name;if(V.onLoad){s(X,"load",V.onLoad)}if(typeof V.container=="string"){V.container=c.getElementById(V.container)}if(!V.container){X.style.position="absolute";X.style.top="-2000px";V.container=c.body}var W=V.props.src;delete V.props.src;Q(X,V.props);X.border=X.frameBorder=0;V.container.appendChild(X);X.src=W;V.props.src=W;return X}function S(Y,X){if(typeof Y=="string"){Y=[Y]}var W,V=Y.length;while(V--){W=Y[V];W=new RegExp(W.substr(0,1)=="^"?W:("^"+W.replace(/(\*)/g,".$1").replace(/\?/g,".")+"$"));if(W.test(X)){return true}}return false}function i(X){var ac=X.protocol,W;X.isHost=X.isHost||q(P.xdm_p);v=X.hash||false;if(!X.props){X.props={}}if(!X.isHost){X.channel=P.xdm_c;X.secret=P.xdm_s;X.remote=P.xdm_e;ac=P.xdm_p;if(X.acl&&!S(X.acl,X.remote)){throw new Error("Access denied for "+X.remote)}}else{X.remote=y(X.remote);X.channel=X.channel||"default"+k++;X.secret=Math.random().toString(16).substring(2);if(q(ac)){if(g(m.href)==g(X.remote)){ac="4"}else{if(z(K,"postMessage")||z(c,"postMessage")){ac="1"}else{if(z(K,"ActiveXObject")&&T("ShockwaveFlash.ShockwaveFlash")){ac="6"}else{if(navigator.product==="Gecko"&&"frameElement" in K&&navigator.userAgent.indexOf("WebKit")==-1){ac="5"}else{if(X.remoteHelper){X.remoteHelper=y(X.remoteHelper);ac="2"}else{ac="0"}}}}}}}switch(ac){case"0":Q(X,{interval:100,delay:2000,useResize:true,useParent:false,usePolling:false},true);if(X.isHost){if(!X.local){var aa=m.protocol+"//"+m.host,V=c.body.getElementsByTagName("img"),ab;var Y=V.length;while(Y--){ab=V[Y];if(ab.src.substring(0,aa.length)===aa){X.local=ab.src;break}}if(!X.local){X.local=K}}var Z={xdm_c:X.channel,xdm_p:0};if(X.local===K){X.usePolling=true;X.useParent=true;X.local=m.protocol+"//"+m.host+m.pathname+m.search;Z.xdm_e=X.local;Z.xdm_pa=1}else{Z.xdm_e=y(X.local)}if(X.container){X.useResize=false;Z.xdm_po=1}X.remote=M(X.remote,Z)}else{Q(X,{channel:P.xdm_c,remote:P.xdm_e,useParent:!q(P.xdm_pa),usePolling:!q(P.xdm_po),useResize:X.useParent?false:X.useResize})}W=[new l.stack.HashTransport(X),new l.stack.ReliableBehavior({}),new l.stack.QueueBehavior({encode:true,maxLength:4000-X.remote.length}),new l.stack.VerifyBehavior({initiate:X.isHost})];break;case"1":W=[new l.stack.PostMessageTransport(X)];break;case"2":W=[new l.stack.NameTransport(X),new l.stack.QueueBehavior(),new l.stack.VerifyBehavior({initiate:X.isHost})];break;case"3":W=[new l.stack.NixTransport(X)];break;case"4":W=[new l.stack.SameOriginTransport(X)];break;case"5":W=[new l.stack.FrameElementTransport(X)];break;case"6":if(!X.swf){X.swf="../../tools/easyxdm.swf"}W=[new l.stack.FlashTransport(X)];break}W.push(new l.stack.QueueBehavior({lazy:X.lazy,remove:true}));return W}function A(Y){var Z,X={incoming:function(ab,aa){this.up.incoming(ab,aa)},outgoing:function(aa,ab){this.down.outgoing(aa,ab)},callback:function(aa){this.up.callback(aa)},init:function(){this.down.init()},destroy:function(){this.down.destroy()}};for(var W=0,V=Y.length;W<V;W++){Z=Y[W];Q(Z,X,true);if(W!==0){Z.down=Y[W-1]}if(W!==V-1){Z.up=Y[W+1]}}return Z}function t(V){V.up.down=V.down;V.down.up=V.up;V.up=V.down=null}Q(l,{version:"2.4.13.0",query:P,stack:{},apply:Q,getJSONObject:L,whenReady:D,noConflict:d});l.DomHelper={on:s,un:u,requiresJSON:function(V){if(!r(K,"JSON")){c.write('<script type="text/javascript" src="'+V+'"><\/script>')}}};(function(){var V={};l.Fn={set:function(W,X){V[W]=X},get:function(X,W){var Y=V[X];if(W){delete V[X]}return Y}}}());l.Socket=function(W){var V=A(i(W).concat([{incoming:function(Z,Y){W.onMessage(Z,Y)},callback:function(Y){if(W.onReady){W.onReady(Y)}}}])),X=g(W.remote);this.origin=g(W.remote);this.destroy=function(){V.destroy()};this.postMessage=function(Y){V.outgoing(Y,X)};V.init()};l.Rpc=function(X,W){if(W.local){for(var Z in W.local){if(W.local.hasOwnProperty(Z)){var Y=W.local[Z];if(typeof Y==="function"){W.local[Z]={method:Y}}}}}var V=A(i(X).concat([new l.stack.RpcBehavior(this,W),{callback:function(aa){if(X.onReady){X.onReady(aa)}}}]));this.origin=g(X.remote);this.destroy=function(){V.destroy()};V.init()};l.stack.SameOriginTransport=function(W){var X,Z,Y,V;return(X={outgoing:function(ab,ac,aa){Y(ab);if(aa){aa()}},destroy:function(){if(Z){Z.parentNode.removeChild(Z);Z=null}},onDOMReady:function(){V=g(W.remote);if(W.isHost){Q(W.props,{src:M(W.remote,{xdm_e:m.protocol+"//"+m.host+m.pathname,xdm_c:W.channel,xdm_p:4}),name:R+W.channel+"_provider"});Z=x(W);l.Fn.set(W.channel,function(aa){Y=aa;H(function(){X.up.callback(true)},0);return function(ab){X.up.incoming(ab,V)}})}else{Y=j().Fn.get(W.channel,true)(function(aa){X.up.incoming(aa,V)});H(function(){X.up.callback(true)},0)}},init:function(){D(X.onDOMReady,X)}})};l.stack.FlashTransport=function(Y){var aa,V,Z,ab,W,ac;function ad(af,ae){H(function(){aa.up.incoming(af,ab)},0)}function X(ah){var ae=Y.swf+"?host="+Y.isHost;var ag="easyXDM_swf_"+Math.floor(Math.random()*10000);l.Fn.set("flash_loaded",function(){l.stack.FlashTransport.__swf=W=ac.firstChild;ah()});ac=c.createElement("div");Q(ac.style,{height:"1px",width:"1px",position:"absolute",left:0,top:0});c.body.appendChild(ac);var af="proto="+b.location.protocol+"&domain="+w(b.location.href)+"&port="+e(b.location.href)+"&ns="+F;ac.innerHTML="<object height='1' width='1' type='application/x-shockwave-flash' id='"+ag+"' data='"+ae+"'><param name='allowScriptAccess' value='always'></param><param name='wmode' value='transparent'><param name='movie' value='"+ae+"'></param><param name='flashvars' value='"+af+"'></param><embed type='application/x-shockwave-flash' FlashVars='"+af+"' allowScriptAccess='always' wmode='transparent' src='"+ae+"' height='1' width='1'></embed></object>"}return(aa={outgoing:function(af,ag,ae){W.postMessage(Y.channel,af.toString());if(ae){ae()}},destroy:function(){try{W.destroyChannel(Y.channel)}catch(ae){}W=null;if(V){V.parentNode.removeChild(V);V=null}},onDOMReady:function(){ab=Y.remote;W=l.stack.FlashTransport.__swf;l.Fn.set("flash_"+Y.channel+"_init",function(){H(function(){aa.up.callback(true)})});l.Fn.set("flash_"+Y.channel+"_onMessage",ad);var ae=function(){W.createChannel(Y.channel,Y.secret,g(Y.remote),Y.isHost);if(Y.isHost){Q(Y.props,{src:M(Y.remote,{xdm_e:g(m.href),xdm_c:Y.channel,xdm_p:6,xdm_s:Y.secret}),name:R+Y.channel+"_provider"});V=x(Y)}};if(W){ae()}else{X(ae)}},init:function(){D(aa.onDOMReady,aa)}})};l.stack.PostMessageTransport=function(Y){var aa,ab,W,X;function V(ac){if(ac.origin){return g(ac.origin)}if(ac.uri){return g(ac.uri)}if(ac.domain){return m.protocol+"//"+ac.domain}throw"Unable to retrieve the origin of the event"}function Z(ad){var ac=V(ad);if(ac==X&&ad.data.substring(0,Y.channel.length+1)==Y.channel+" "){aa.up.incoming(ad.data.substring(Y.channel.length+1),ac)}}return(aa={outgoing:function(ad,ae,ac){W.postMessage(Y.channel+" "+ad,ae||X);if(ac){ac()}},destroy:function(){u(K,"message",Z);if(ab){W=null;ab.parentNode.removeChild(ab);ab=null}},onDOMReady:function(){X=g(Y.remote);if(Y.isHost){var ac=function(ad){if(ad.data==Y.channel+"-ready"){W=("postMessage" in ab.contentWindow)?ab.contentWindow:ab.contentWindow.document;u(K,"message",ac);s(K,"message",Z);H(function(){aa.up.callback(true)},0)}};s(K,"message",ac);Q(Y.props,{src:M(Y.remote,{xdm_e:g(m.href),xdm_c:Y.channel,xdm_p:1}),name:R+Y.channel+"_provider"});ab=x(Y)}else{s(K,"message",Z);W=("postMessage" in K.parent)?K.parent:K.parent.document;W.postMessage(Y.channel+"-ready",X);H(function(){aa.up.callback(true)},0)}},init:function(){D(aa.onDOMReady,aa)}})};l.stack.FrameElementTransport=function(W){var X,Z,Y,V;return(X={outgoing:function(ab,ac,aa){Y.call(this,ab);if(aa){aa()}},destroy:function(){if(Z){Z.parentNode.removeChild(Z);Z=null}},onDOMReady:function(){V=g(W.remote);if(W.isHost){Q(W.props,{src:M(W.remote,{xdm_e:g(m.href),xdm_c:W.channel,xdm_p:5}),name:R+W.channel+"_provider"});Z=x(W);Z.fn=function(aa){delete Z.fn;Y=aa;H(function(){X.up.callback(true)},0);return function(ab){X.up.incoming(ab,V)}}}else{if(c.referrer&&g(c.referrer)!=P.xdm_e){K.top.location=P.xdm_e}Y=K.frameElement.fn(function(aa){X.up.incoming(aa,V)});X.up.callback(true)}},init:function(){D(X.onDOMReady,X)}})};l.stack.NameTransport=function(Z){var aa;var ac,ag,Y,ae,af,W,V;function ad(aj){var ai=Z.remoteHelper+(ac?"#_3":"#_2")+Z.channel;ag.contentWindow.sendMessage(aj,ai)}function ab(){if(ac){if(++ae===2||!ac){aa.up.callback(true)}}else{ad("ready");aa.up.callback(true)}}function ah(ai){aa.up.incoming(ai,W)}function X(){if(af){H(function(){af(true)},0)}}return(aa={outgoing:function(aj,ak,ai){af=ai;ad(aj)},destroy:function(){ag.parentNode.removeChild(ag);ag=null;if(ac){Y.parentNode.removeChild(Y);Y=null}},onDOMReady:function(){ac=Z.isHost;ae=0;W=g(Z.remote);Z.local=y(Z.local);if(ac){l.Fn.set(Z.channel,function(aj){if(ac&&aj==="ready"){l.Fn.set(Z.channel,ah);ab()}});V=M(Z.remote,{xdm_e:Z.local,xdm_c:Z.channel,xdm_p:2});Q(Z.props,{src:V+"#"+Z.channel,name:R+Z.channel+"_provider"});Y=x(Z)}else{Z.remoteHelper=Z.remote;l.Fn.set(Z.channel,ah)}ag=x({props:{src:Z.local+"#_4"+Z.channel},onLoad:function ai(){var aj=ag||this;u(aj,"load",ai);l.Fn.set(Z.channel+"_load",X);(function ak(){if(typeof aj.contentWindow.sendMessage=="function"){ab()}else{H(ak,50)}}())}})},init:function(){D(aa.onDOMReady,aa)}})};l.stack.HashTransport=function(X){var aa;var af=this,ad,Y,V,ab,ak,Z,aj;var ae,W;function ai(am){if(!aj){return}var al=X.remote+"#"+(ak++)+"_"+am;((ad||!ae)?aj.contentWindow:aj).location=al}function ac(al){ab=al;aa.up.incoming(ab.substring(ab.indexOf("_")+1),W)}function ah(){if(!Z){return}var al=Z.location.href,an="",am=al.indexOf("#");if(am!=-1){an=al.substring(am)}if(an&&an!=ab){ac(an)}}function ag(){Y=setInterval(ah,V)}return(aa={outgoing:function(al,am){ai(al)},destroy:function(){K.clearInterval(Y);if(ad||!ae){aj.parentNode.removeChild(aj)}aj=null},onDOMReady:function(){ad=X.isHost;V=X.interval;ab="#"+X.channel;ak=0;ae=X.useParent;W=g(X.remote);if(ad){X.props={src:X.remote,name:R+X.channel+"_provider"};if(ae){X.onLoad=function(){Z=K;ag();aa.up.callback(true)}}else{var an=0,al=X.delay/50;(function am(){if(++an>al){throw new Error("Unable to reference listenerwindow")}try{Z=aj.contentWindow.frames[R+X.channel+"_consumer"]}catch(ao){}if(Z){ag();aa.up.callback(true)}else{H(am,50)}}())}aj=x(X)}else{Z=K;ag();if(ae){aj=parent;aa.up.callback(true)}else{Q(X,{props:{src:X.remote+"#"+X.channel+new Date(),name:R+X.channel+"_consumer"},onLoad:function(){aa.up.callback(true)}});aj=x(X)}}},init:function(){D(aa.onDOMReady,aa)}})};l.stack.ReliableBehavior=function(W){var Y,aa;var Z=0,V=0,X="";return(Y={incoming:function(ad,ab){var ac=ad.indexOf("_"),ae=ad.substring(0,ac).split(",");ad=ad.substring(ac+1);if(ae[0]==Z){X="";if(aa){aa(true)}}if(ad.length>0){Y.down.outgoing(ae[1]+","+Z+"_"+X,ab);if(V!=ae[1]){V=ae[1];Y.up.incoming(ad,ab)}}},outgoing:function(ad,ab,ac){X=ad;aa=ac;Y.down.outgoing(V+","+(++Z)+"_"+ad,ab)}})};l.stack.QueueBehavior=function(X){var aa,ab=[],ae=true,Y="",ad,V=0,W=false,Z=false;function ac(){if(X.remove&&ab.length===0){t(aa);return}if(ae||ab.length===0||ad){return}ae=true;var af=ab.shift();aa.down.outgoing(af.data,af.origin,function(ag){ae=false;if(af.callback){H(function(){af.callback(ag)},0)}ac()})}return(aa={init:function(){if(q(X)){X={}}if(X.maxLength){V=X.maxLength;Z=true}if(X.lazy){W=true}else{aa.down.init()}},callback:function(ag){ae=false;var af=aa.up;ac();af.callback(ag)},incoming:function(ai,ag){if(Z){var ah=ai.indexOf("_"),af=parseInt(ai.substring(0,ah),10);Y+=ai.substring(ah+1);if(af===0){if(X.encode){Y=h(Y)}aa.up.incoming(Y,ag);Y=""}}else{aa.up.incoming(ai,ag)}},outgoing:function(aj,ag,ai){if(X.encode){aj=E(aj)}var af=[],ah;if(Z){while(aj.length!==0){ah=aj.substring(0,V);aj=aj.substring(ah.length);af.push(ah)}while((ah=af.shift())){ab.push({data:af.length+"_"+ah,origin:ag,callback:af.length===0?ai:null})}}else{ab.push({data:aj,origin:ag,callback:ai})}if(W){aa.down.init()}else{ac()}},destroy:function(){ad=true;aa.down.destroy()}})};l.stack.VerifyBehavior=function(Z){var aa,Y,W,X=false;function V(){Y=Math.random().toString(16).substring(2);aa.down.outgoing(Y)}return(aa={incoming:function(ad,ab){var ac=ad.indexOf("_");if(ac===-1){if(ad===Y){aa.up.callback(true)}else{if(!W){W=ad;if(!Z.initiate){V()}aa.down.outgoing(ad)}}}else{if(ad.substring(0,ac)===W){aa.up.incoming(ad.substring(ac+1),ab)}}},outgoing:function(ad,ab,ac){aa.down.outgoing(Y+"_"+ad,ab,ac)},callback:function(ab){if(Z.initiate){V()}}})};l.stack.RpcBehavior=function(ab,W){var Y,ad=W.serializer||L();var ac=0,aa={};function V(ae){ae.jsonrpc="2.0";Y.down.outgoing(ad.stringify(ae))}function Z(ae,ag){var af=Array.prototype.slice;return function(){var ah=arguments.length,aj,ai={method:ag};if(ah>0&&typeof arguments[ah-1]==="function"){if(ah>1&&typeof arguments[ah-2]==="function"){aj={success:arguments[ah-2],error:arguments[ah-1]};ai.params=af.call(arguments,0,ah-2)}else{aj={success:arguments[ah-1]};ai.params=af.call(arguments,0,ah-1)}aa[""+(++ac)]=aj;ai.id=ac}else{ai.params=af.call(arguments,0)}if(ae.namedParams&&ai.params.length===1){ai.params=ai.params[0]}V(ai)}}function X(al,ak,ag,aj){if(!ag){if(ak){V({id:ak,error:{code:-32601,message:"Procedure not found."}})}return}var ai,af;if(ak){ai=function(am){ai=n;V({id:ak,result:am})};af=function(am,an){af=n;var ao={id:ak,error:{code:-32099,message:am}};if(an){ao.error.data=an}V(ao)}}else{ai=af=n}if(!o(aj)){aj=[aj]}try{var ae=ag.method.apply(ag.scope,aj.concat([ai,af]));if(!q(ae)){ai(ae)}}catch(ah){af(ah.message)}}return(Y={incoming:function(af,ae){var ag=ad.parse(af);if(ag.method){if(W.handle){W.handle(ag,V)}else{X(ag.method,ag.id,W.local[ag.method],ag.params)}}else{var ah=aa[ag.id];if(ag.error){if(ah.error){ah.error(ag.error)}}else{if(ah.success){ah.success(ag.result)}}delete aa[ag.id]}},init:function(){if(W.remote){for(var ae in W.remote){if(W.remote.hasOwnProperty(ae)){ab[ae]=Z(W.remote[ae],ae)}}}Y.down.init()},destroy:function(){for(var ae in W.remote){if(W.remote.hasOwnProperty(ae)&&ab.hasOwnProperty(ae)){delete ab[ae]}}Y.down.destroy()}})};b.easyXDM=l})(window,document,location,window.setTimeout,decodeURIComponent,encodeURIComponent);

// Load jQuery if it's not already loaded.
// The purpose of using a try/catch loop is to avoid Internet Explorer 8 from crashing when assigning an undefined variable.
try {
    var jqueryIsLoaded = jQuery;
    jQueryIsLoaded = true;
} catch(err) {
    var jQueryIsLoaded = false;
}

if(jQueryIsLoaded) {
	if ($.browser.msie)
		setTimeout(function () { optemo_socket_activator(); }, 3000);
	else
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

