/* To create a website that embeds the Optemo Assist or Direct interface, create an HTML file on any server and insert the following:

In the <head>: 
<script src="http://ast0.optemo.com/optemo_embedder.js" type="text/javascript"></script>

In the <body>:
<div id="optemo_embedder"></div>

This script will auto-load various javascript files from the server, embed an iframe into the website, and load the interface via AJAX (not usually possible due to cross-site restrictions, but implemented using easyXDM, http://easyxdm.net/)

This script could be minified for better performance. The asset packager combines and compresses the application javascript, but this file
does not get minified by the capistrano deployment at the moment. */

window.embedding_flag = true;
var optemo_module, remote, REMOTE = 'http://ast0.optemo.com'; // static globals

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
        				optemo_module.embeddedString = REMOTE;

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
        		                    // For now, take the CSS file out totally for laserprinterhub.com deployment.
//        		                    headID.appendChild(tag);
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
                    
                        optemo_module.IS_DRAG_DROP_ENABLED = (jQuery("#dragDropEnabled").html() === 'true');
                        optemo_module.MODEL_NAME = jQuery("#modelname").html();
                        optemo_module.DIRECT_LAYOUT = (jQuery('#directLayout').html() == "true");                    
                        optemo_module.FilterAndSearchInit(); optemo_module.DBinit();
                    
                    
                    }
    		    },
    			parseData: function (data) {
    	            data_to_append = parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));
    				optemo_module.ajaxhandler(data_to_append);
    			},
    			parseDataThin: function (element_name, data, fn) {
    				data = parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));
    				jQuery(element_name).html(data); // This seems unsafe. Fix this?
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
    script.setAttribute("src", 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js');
    document.getElementsByTagName("head")[0].appendChild(script);
}

/*
 * easyXDM 
 * http://easyxdm.net/
 * Copyright(c) 2009, Øyvind Sean Kinsey, oyvind@kinsey.no.
 * 
 * MIT Licensed - http://easyxdm.net/license/mit.txt
 * 
 */

(function(D,c,i,C,f,A){if("easyXDM" in D){return}var b=this;var h=0;var j=Function.prototype;var G=/^(http.?:\/\/([^\/\s]+))/;var H=/[\-\w]+\/\.\.\//;var y=/([^:])\/\//g;var K="easyXDM_";var x;function v(M,O){var N=typeof M[O];return N=="function"||(!!(N=="object"&&M[O]))||N=="unknown"}function o(M,N){return !!(typeof(M[N])=="object"&&M[N])}function l(M){return Object.prototype.toString.call(M)==="[object Array]"}var p,r;if(v(D,"addEventListener")){p=function(O,M,N){O.addEventListener(M,N,false)};r=function(O,M,N){O.removeEventListener(M,N,false)}}else{if(v(D,"attachEvent")){p=function(M,O,N){M.attachEvent("on"+O,N)};r=function(M,O,N){M.detachEvent("on"+O,N)}}else{throw new Error("Browser not supported")}}var k=false,B=[];if("readyState" in c){k=c.readyState=="complete"}else{if(c.body){k=true}}function m(){m=j;k=true;for(var M=0;M<B.length;M++){B[M]()}B.length=0}if(!k){if(v(D,"addEventListener")){p(c,"DOMContentLoaded",m)}else{p(c,"readystatechange",function(){if(c.readyState=="complete"){m()}});if(c.documentElement.doScroll&&D===top){(function d(){if(k){return}try{c.documentElement.doScroll("left")}catch(M){C(d,1);return}m()}())}}p(D,"load",m)}function z(N,M){if(k){N.call(M);return}B.push(function(){N.call(M)})}function s(M){return M.match(G)[2]}function e(M){return M.match(G)[1]}function u(M){M=M.replace(y,"$1/");if(!M.match(/^(http||https):\/\//)){var N=(M.substring(0,1)==="/")?"":i.pathname;if(N.substring(N.length-1)!=="/"){N=N.substring(0,N.lastIndexOf("/")+1)}M=i.protocol+"//"+i.host+N+M}while(H.test(M)){M=M.replace(H,"")}return M}function F(M,P){var R="",O=M.indexOf("#");if(O!==-1){R=M.substring(O);M=M.substring(0,O)}var Q=[];for(var N in P){if(P.hasOwnProperty(N)){Q.push(N+"="+A(P[N]))}}return M+((M.indexOf("?")===-1)?"?":"&")+Q.join("&")+R}var I=(function(){var O={},P,N=i.search.substring(1).split("&"),M=N.length;while(M--){P=N[M].split("=");O[P[0]]=f(P[1])}return O}());function n(M){return typeof M==="undefined"}function E(){var N={};var O={a:[1,2,3]},M='{"a":[1,2,3]}';if(JSON&&typeof JSON.stringify==="function"&&JSON.stringify(O).replace((/\s/g),"")===M){return JSON}if(Object.toJSON){if(Object.toJSON(O).replace((/\s/g),"")===M){N.stringify=Object.toJSON}}if(typeof String.prototype.evalJSON==="function"){O=M.evalJSON();if(O.a&&O.a.length===3&&O.a[2]===3){N.parse=function(P){return P.evalJSON()}}}if(N.stringify&&N.parse){E=function(){return N};return N}return null}function J(M,N,O){var Q;for(var P in N){if(N.hasOwnProperty(P)){if(P in M){Q=N[P];if(typeof Q==="object"){J(M[P],Q,O)}else{if(!O){M[P]=N[P]}}}else{M[P]=N[P]}}}return M}function a(){var M=c.createElement("iframe");M.name="easyXDM_TEST";J(M.style,{position:"absolute",left:"-2000px",top:"0px"});c.body.appendChild(M);x=!(M.contentWindow===D.frames[M.name]);c.body.removeChild(M)}function t(M){if(n(x)){a()}var N;if(x){N=c.createElement('<iframe name="'+M.props.name+'"/>')}else{N=c.createElement("IFRAME");N.name=M.props.name}N.id=N.name=M.props.name;delete M.props.name;if(M.onLoad){p(N,"load",M.onLoad)}if(typeof M.container=="string"){M.container=c.getElementById(M.container)}if(!M.container){N.style.position="absolute";N.style.left="-2000px";N.style.top="0px";M.container=c.body}N.border=N.frameBorder=0;M.container.insertBefore(N,M.container.firstChild);J(N,M.props);return N}function L(P,O){if(typeof P=="string"){P=[P]}var N,M=P.length;while(M--){N=P[M];N=new RegExp(N.substr(0,1)=="^"?N:("^"+N.replace(/(\*)/g,".$1").replace(/\?/g,".")+"$"));if(N.test(O)){return true}}return false}function g(O){var T=O.protocol,N;O.isHost=O.isHost||n(I.xdm_p);if(!O.props){O.props={}}if(!O.isHost){O.channel=I.xdm_c;O.secret=I.xdm_s;O.remote=I.xdm_e;T=I.xdm_p;if(O.acl&&!L(O.acl,O.remote)){throw new Error("Access denied for "+O.remote)}}else{O.remote=u(O.remote);O.channel=O.channel||"default"+h++;O.secret=Math.random().toString(16).substring(2);if(n(T)){if(e(i.href)==e(O.remote)){T="4"}else{if(v(D,"postMessage")||v(c,"postMessage")){T="1"}else{if(v(D,"ActiveXObject")&&v(D,"execScript")){T="3"}else{if(navigator.product==="Gecko"&&"frameElement" in D&&navigator.userAgent.indexOf("WebKit")==-1){T="5"}else{if(O.remoteHelper){O.remoteHelper=u(O.remoteHelper);T="2"}else{T="0"}}}}}}}switch(T){case"0":J(O,{interval:100,delay:2000,useResize:true,useParent:false,usePolling:false},true);if(O.isHost){if(!O.local){var R=i.protocol+"//"+i.host,M=c.body.getElementsByTagName("img"),S;var P=M.length;while(P--){S=M[P];if(S.src.substring(0,R.length)===R){O.local=S.src;break}}if(!O.local){O.local=D}}var Q={xdm_c:O.channel,xdm_p:0};if(O.local===D){O.usePolling=true;O.useParent=true;O.local=i.protocol+"//"+i.host+i.pathname+i.search;Q.xdm_e=O.local;Q.xdm_pa=1}else{Q.xdm_e=u(O.local)}if(O.container){O.useResize=false;Q.xdm_po=1}O.remote=F(O.remote,Q)}else{J(O,{channel:I.xdm_c,remote:I.xdm_e,useParent:!n(I.xdm_pa),usePolling:!n(I.xdm_po),useResize:O.useParent?false:O.useResize})}N=[new easyXDM.stack.HashTransport(O),new easyXDM.stack.ReliableBehavior({}),new easyXDM.stack.QueueBehavior({encode:true,maxLength:4000-O.remote.length}),new easyXDM.stack.VerifyBehavior({initiate:O.isHost})];break;case"1":N=[new easyXDM.stack.PostMessageTransport(O)];break;case"2":N=[new easyXDM.stack.NameTransport(O),new easyXDM.stack.QueueBehavior(),new easyXDM.stack.VerifyBehavior({initiate:O.isHost})];break;case"3":N=[new easyXDM.stack.NixTransport(O)];break;case"4":N=[new easyXDM.stack.SameOriginTransport(O)];break;case"5":N=[new easyXDM.stack.FrameElementTransport(O)];break}N.push(new easyXDM.stack.QueueBehavior({lazy:O.lazy,remove:true}));return N}function w(P){var Q,O={incoming:function(S,R){this.up.incoming(S,R)},outgoing:function(R,S){this.down.outgoing(R,S)},callback:function(R){this.up.callback(R)},init:function(){this.down.init()},destroy:function(){this.down.destroy()}};for(var N=0,M=P.length;N<M;N++){Q=P[N];J(Q,O,true);if(N!==0){Q.down=P[N-1]}if(N!==M-1){Q.up=P[N+1]}}return Q}function q(M){M.up.down=M.down;M.down.up=M.up;M.up=M.down=null}b.easyXDM={version:"2.4.9.102",query:I,stack:{},apply:J,getJSONObject:E,whenReady:z};easyXDM.DomHelper={on:p,un:r,requiresJSON:function(M){if(!o(D,"JSON")){c.write('<script type="text/javascript" src="'+M+'"><\/script>')}}};(function(){var M={};easyXDM.Fn={set:function(N,O){M[N]=O},get:function(O,N){var P=M[O];if(N){delete M[O]}return P}}}());easyXDM.Socket=function(N){var M=w(g(N).concat([{incoming:function(Q,P){N.onMessage(Q,P)},callback:function(P){if(N.onReady){N.onReady(P)}}}])),O=e(N.remote);this.origin=e(N.remote);this.destroy=function(){M.destroy()};this.postMessage=function(P){M.outgoing(P,O)};M.init()};easyXDM.Rpc=function(O,N){if(N.local){for(var Q in N.local){if(N.local.hasOwnProperty(Q)){var P=N.local[Q];if(typeof P==="function"){N.local[Q]={method:P}}}}}var M=w(g(O).concat([new easyXDM.stack.RpcBehavior(this,N),{callback:function(R){if(O.onReady){O.onReady(R)}}}]));this.origin=e(O.remote);this.destroy=function(){M.destroy()};M.init()};easyXDM.stack.SameOriginTransport=function(N){var O,Q,P,M;return(O={outgoing:function(S,T,R){P(S);if(R){R()}},destroy:function(){if(Q){Q.parentNode.removeChild(Q);Q=null}},onDOMReady:function(){M=e(N.remote);if(N.isHost){J(N.props,{src:F(N.remote,{xdm_e:i.protocol+"//"+i.host+i.pathname,xdm_c:N.channel,xdm_p:4}),name:K+N.channel+"_provider"});Q=t(N);easyXDM.Fn.set(N.channel,function(R){P=R;C(function(){O.up.callback(true)},0);return function(S){O.up.incoming(S,M)}})}else{P=parent.easyXDM.Fn.get(N.channel,true)(function(R){O.up.incoming(R,M)});C(function(){O.up.callback(true)},0)}},init:function(){z(O.onDOMReady,O)}})};easyXDM.stack.PostMessageTransport=function(P){var R,S,N,O;function M(T){if(T.origin){return T.origin}if(T.uri){return e(T.uri)}if(T.domain){return i.protocol+"//"+T.domain}throw"Unable to retrieve the origin of the event"}function Q(U){var T=M(U);if(T==O&&U.data.substring(0,P.channel.length+1)==P.channel+" "){R.up.incoming(U.data.substring(P.channel.length+1),T)}}return(R={outgoing:function(U,V,T){N.postMessage(P.channel+" "+U,V||O);if(T){T()}},destroy:function(){r(D,"message",Q);if(S){N=null;S.parentNode.removeChild(S);S=null}},onDOMReady:function(){O=e(P.remote);if(P.isHost){p(D,"message",function T(U){if(U.data==P.channel+"-ready"){N=("postMessage" in S.contentWindow)?S.contentWindow:S.contentWindow.document;r(D,"message",T);p(D,"message",Q);C(function(){R.up.callback(true)},0)}});J(P.props,{src:F(P.remote,{xdm_e:i.protocol+"//"+i.host,xdm_c:P.channel,xdm_p:1}),name:K+P.channel+"_provider"});S=t(P)}else{p(D,"message",Q);N=("postMessage" in D.parent)?D.parent:D.parent.document;N.postMessage(P.channel+"-ready",O);C(function(){R.up.callback(true)},0)}},init:function(){z(R.onDOMReady,R)}})};easyXDM.stack.FrameElementTransport=function(N){var O,Q,P,M;return(O={outgoing:function(S,T,R){P.call(this,S);if(R){R()}},destroy:function(){if(Q){Q.parentNode.removeChild(Q);Q=null}},onDOMReady:function(){M=e(N.remote);if(N.isHost){J(N.props,{src:F(N.remote,{xdm_e:i.protocol+"//"+i.host+i.pathname+i.search,xdm_c:N.channel,xdm_p:5}),name:K+N.channel+"_provider"});Q=t(N);Q.fn=function(R){delete Q.fn;P=R;C(function(){O.up.callback(true)},0);return function(S){O.up.incoming(S,M)}}}else{if(c.referrer&&c.referrer!=I.xdm_e){D.parent.location=I.xdm_e}else{if(c.referrer!=I.xdm_e){D.parent.location=I.xdm_e}P=D.frameElement.fn(function(R){O.up.incoming(R,M)});O.up.callback(true)}}},init:function(){z(O.onDOMReady,O)}})};easyXDM.stack.NixTransport=function(N){var P,R,Q,M,O;return(P={outgoing:function(T,U,S){Q(T);if(S){S()}},destroy:function(){O=null;if(R){R.parentNode.removeChild(R);R=null}},onDOMReady:function(){M=e(N.remote);if(N.isHost){try{if(!v(D,"getNixProxy")){D.execScript("Class NixProxy\n    Private m_parent, m_child, m_Auth\n\n    Public Sub SetParent(obj, auth)\n        If isEmpty(m_Auth) Then m_Auth = auth\n        SET m_parent = obj\n    End Sub\n    Public Sub SetChild(obj)\n        SET m_child = obj\n        m_parent.ready()\n    End Sub\n\n    Public Sub SendToParent(data, auth)\n        If m_Auth = auth Then m_parent.send(CStr(data))\n    End Sub\n    Public Sub SendToChild(data, auth)\n        If m_Auth = auth Then m_child.send(CStr(data))\n    End Sub\nEnd Class\nFunction getNixProxy()\n    Set GetNixProxy = New NixProxy\nEnd Function\n","vbscript")}O=getNixProxy();O.SetParent({send:function(U){P.up.incoming(U,M)},ready:function(){C(function(){P.up.callback(true)},0)}},N.secret);Q=function(U){O.SendToChild(U,N.secret)}}catch(T){throw new Error("Could not set up VBScript NixProxy:"+T.message)}J(N.props,{src:F(N.remote,{xdm_e:i.protocol+"//"+i.host+i.pathname+i.search,xdm_c:N.channel,xdm_s:N.secret,xdm_p:3}),name:K+N.channel+"_provider"});R=t(N);R.contentWindow.opener=O}else{if(c.referrer&&c.referrer!=I.xdm_e){D.parent.location=I.xdm_e}else{if(c.referrer!=I.xdm_e){D.parent.location=I.xdm_e}try{O=D.opener}catch(S){throw new Error("Cannot access window.opener")}O.SetChild({send:function(U){b.setTimeout(function(){P.up.incoming(U,M)},0)}});Q=function(U){O.SendToParent(U,N.secret)};C(function(){P.up.callback(true)},0)}}},init:function(){z(P.onDOMReady,P)}})};easyXDM.stack.NameTransport=function(Q){var R;var T,X,P,V,W,N,M;function U(aa){var Z=Q.remoteHelper+(T?"#_3":"#_2")+Q.channel;X.contentWindow.sendMessage(aa,Z)}function S(){if(T){if(++V===2||!T){R.up.callback(true)}}else{U("ready");R.up.callback(true)}}function Y(Z){R.up.incoming(Z,N)}function O(){if(W){C(function(){W(true)},0)}}return(R={outgoing:function(aa,ab,Z){W=Z;U(aa)},destroy:function(){X.parentNode.removeChild(X);X=null;if(T){P.parentNode.removeChild(P);P=null}},onDOMReady:function(){T=Q.isHost;V=0;N=e(Q.remote);Q.local=u(Q.local);if(T){easyXDM.Fn.set(Q.channel,function(aa){if(T&&aa==="ready"){easyXDM.Fn.set(Q.channel,Y);S()}});M=F(Q.remote,{xdm_e:Q.local,xdm_c:Q.channel,xdm_p:2});J(Q.props,{src:M+"#"+Q.channel,name:K+Q.channel+"_provider"});P=t(Q)}else{Q.remoteHelper=Q.remote;easyXDM.Fn.set(Q.channel,Y)}X=t({props:{src:Q.local+"#_4"+Q.channel},onLoad:function Z(){r(X,"load",Z);easyXDM.Fn.set(Q.channel+"_load",O);(function aa(){if(typeof X.contentWindow.sendMessage=="function"){S()}else{C(aa,50)}}())}})},init:function(){z(R.onDOMReady,R)}})};easyXDM.stack.HashTransport=function(O){var R;var W=this,U,P,M,S,ab,Q,aa;var V,N;function Z(ad){if(!aa){return}var ac=O.remote+"#"+(ab++)+"_"+ad;((U||!V)?aa.contentWindow:aa).location=ac}function T(ac){S=ac;R.up.incoming(S.substring(S.indexOf("_")+1),N)}function Y(){if(!Q){return}var ac=Q.location.href,ae="",ad=ac.indexOf("#");if(ad!=-1){ae=ac.substring(ad)}if(ae&&ae!=S){T(ae)}}function X(){P=setInterval(Y,M)}return(R={outgoing:function(ac,ad){Z(ac)},destroy:function(){D.clearInterval(P);if(U||!V){aa.parentNode.removeChild(aa)}aa=null},onDOMReady:function(){U=O.isHost;M=O.interval;S="#"+O.channel;ab=0;V=O.useParent;N=e(O.remote);if(U){O.props={src:O.remote,name:K+O.channel+"_provider"};if(V){O.onLoad=function(){Q=D;X();R.up.callback(true)}}else{var ae=0,ac=O.delay/50;(function ad(){if(++ae>ac){throw new Error("Unable to reference listenerwindow")}try{Q=aa.contentWindow.frames[K+O.channel+"_consumer"]}catch(af){}if(Q){X();R.up.callback(true)}else{C(ad,50)}}())}aa=t(O)}else{Q=D;X();if(V){aa=parent;R.up.callback(true)}else{J(O,{props:{src:O.remote+"#"+O.channel+new Date(),name:K+O.channel+"_consumer"},onLoad:function(){R.up.callback(true)}});aa=t(O)}}},init:function(){z(R.onDOMReady,R)}})};easyXDM.stack.ReliableBehavior=function(N){var P,R;var Q=0,M=0,O="";return(P={incoming:function(U,S){var T=U.indexOf("_"),V=U.substring(0,T).split(",");U=U.substring(T+1);if(V[0]==Q){O="";if(R){R(true)}}if(U.length>0){P.down.outgoing(V[1]+","+Q+"_"+O,S);if(M!=V[1]){M=V[1];P.up.incoming(U,S)}}},outgoing:function(U,S,T){O=U;R=T;P.down.outgoing(M+","+(++Q)+"_"+U,S)}})};easyXDM.stack.QueueBehavior=function(O){var R,S=[],V=true,P="",U,M=0,N=false,Q=false;function T(){if(O.remove&&S.length===0){q(R);return}if(V||S.length===0||U){return}V=true;var W=S.shift();R.down.outgoing(W.data,W.origin,function(X){V=false;if(W.callback){C(function(){W.callback(X)},0)}T()})}return(R={init:function(){if(n(O)){O={}}if(O.maxLength){M=O.maxLength;Q=true}if(O.lazy){N=true}else{R.down.init()}},callback:function(X){V=false;var W=R.up;T();W.callback(X)},incoming:function(Z,X){if(Q){var Y=Z.indexOf("_"),W=parseInt(Z.substring(0,Y),10);P+=Z.substring(Y+1);if(W===0){if(O.encode){P=f(P)}R.up.incoming(P,X);P=""}}else{R.up.incoming(Z,X)}},outgoing:function(aa,X,Z){if(O.encode){aa=A(aa)}var W=[],Y;if(Q){while(aa.length!==0){Y=aa.substring(0,M);aa=aa.substring(Y.length);W.push(Y)}while((Y=W.shift())){S.push({data:W.length+"_"+Y,origin:X,callback:W.length===0?Z:null})}}else{S.push({data:aa,origin:X,callback:Z})}if(N){R.down.init()}else{T()}},destroy:function(){U=true;R.down.destroy()}})};easyXDM.stack.VerifyBehavior=function(Q){var R,P,N,O=false;function M(){P=Math.random().toString(16).substring(2);R.down.outgoing(P)}return(R={incoming:function(U,S){var T=U.indexOf("_");if(T===-1){if(U===P){R.up.callback(true)}else{if(!N){N=U;if(!Q.initiate){M()}R.down.outgoing(U)}}}else{if(U.substring(0,T)===N){R.up.incoming(U.substring(T+1),S)}}},outgoing:function(U,S,T){R.down.outgoing(P+"_"+U,S,T)},callback:function(S){if(Q.initiate){M()}}})};easyXDM.stack.RpcBehavior=function(S,N){var P,U=N.serializer||E();var T=0,R={};function M(V){V.jsonrpc="2.0";P.down.outgoing(U.stringify(V))}function Q(V,X){var W=Array.prototype.slice;return function(){var Y=arguments.length,aa,Z={method:X};if(Y>0&&typeof arguments[Y-1]==="function"){if(Y>1&&typeof arguments[Y-2]==="function"){aa={success:arguments[Y-2],error:arguments[Y-1]};Z.params=W.call(arguments,0,Y-2)}else{aa={success:arguments[Y-1]};Z.params=W.call(arguments,0,Y-1)}R[""+(++T)]=aa;Z.id=T}else{Z.params=W.call(arguments,0)}if(V.namedParams&&Z.params.length===1){Z.params=Z.params[0]}M(Z)}}function O(ac,ab,X,aa){if(!X){if(ab){M({id:ab,error:{code:-32601,message:"Procedure not found."}})}return}var Z,W;if(ab){Z=function(ad){Z=j;M({id:ab,result:ad})};W=function(ad,ae){W=j;var af={id:ab,error:{code:-32099,message:ad}};if(ae){af.error.data=ae}M(af)}}else{Z=W=j}if(!l(aa)){aa=[aa]}try{var V=X.method.apply(X.scope,aa.concat([Z,W]));if(!n(V)){Z(V)}}catch(Y){W(Y.message)}}return(P={incoming:function(W,V){var X=U.parse(W);if(X.method){if(N.handle){N.handle(X,M)}else{O(X.method,X.id,N.local[X.method],X.params)}}else{var Y=R[X.id];if(X.error){if(Y.error){Y.error(X.error)}}else{if(Y.success){Y.success(X.result)}}delete R[X.id]}},init:function(){if(N.remote){for(var V in N.remote){if(N.remote.hasOwnProperty(V)){S[V]=Q(N.remote[V],V)}}}P.down.init()},destroy:function(){for(var V in N.remote){if(N.remote.hasOwnProperty(V)&&S.hasOwnProperty(V)){delete S[V]}}P.down.destroy()}})}})(window,document,location,window.setTimeout,decodeURIComponent,encodeURIComponent);

