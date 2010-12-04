/* To create a website that embeds the Optemo Assist or Direct interface, create an HTML file on any server and insert the following:

In the <head>: 
<script src="http://ast0.optemo.com/optemo_embedder.js" type="text/javascript"></script>

In the <body>:
<div id="optemo_embedder"></div>

This script will auto-load various javascript files from the server, embed an iframe into the website, and load the interface via AJAX (not usually possible due to cross-site restrictions, but implemented using easyXDM, http://easyxdm.net/)

This script could be minified for better performance. The asset packager combines and compresses the application javascript, but this file
does not get minified by the capistrano deployment at the moment. */

/*
 * easyXDM 
 * http://easyxdm.net/
 * Copyright(c) 2009, Øyvind Sean Kinsey, oyvind@kinsey.no.
 * 
 * MIT Licensed - http://easyxdm.net/license/mit.txt
 * 
 */
 (function(E,c,i,D,f,B){var b=this;var h=0;var k=Function.prototype;var H=/^(http.?:\/\/([^\/\s]+))/;var I=/[\-\w]+\/\.\.\//;var z=/([^:])\/\//g;var L="easyXDM_";var y;function w(N,P){var O=typeof N[P];return O=="function"||(!!(O=="object"&&N[P]))||O=="unknown"}function p(N,O){return !!(typeof(N[O])=="object"&&N[O])}function n(N){return Object.prototype.toString.call(N)==="[object Array]"}var q,s;if(w(E,"addEventListener")){q=function(P,N,O){P.addEventListener(N,O,false)};s=function(Q,O,P,N){Q.removeEventListener(O,P,N)}}else{if(w(E,"attachEvent")){q=function(N,P,O){N.attachEvent("on"+P,O)};s=function(N,P,O){N.detachEvent("on"+P,O)}}else{throw new Error("Browser not supported")}}var m=false,C=[];if(c.body){m=true}function l(){if(m){return}m=true;for(var N=0;N<C.length;N++){C[N]()}C.length=0;s(E,"DOMContentLoaded",l);s(c,"DOMContentLoaded",l);if(w(E,"ActiveXObject")){s(E,"load",l)}}function j(){if(c.readyState=="complete"){l();s(c,"readystatechange",j)}}if(!m){q(E,"DOMContentLoaded",l);q(c,"DOMContentLoaded",l);if(w(E,"ActiveXObject")){q(c,"readystatechange",j);q(E,"load",l);if(E===top){(function d(){if(m){return}try{c.documentElement.doScroll("left")}catch(N){D(d,1);return}l()}())}}}function A(O,N){if(m){O.call(N);return}C.push(function(){O.call(N)})}function t(N){return N.match(H)[2]}function e(N){return N.match(H)[1]}function v(N){N=N.replace(z,"$1/");if(!N.match(/^(http||https):\/\//)){var O=(N.substring(0,1)==="/")?"":i.pathname;if(O.substring(O.length-1)!=="/"){O=O.substring(0,O.lastIndexOf("/")+1)}N=i.protocol+"//"+i.host+O+N}while(I.test(N)){N=N.replace(I,"")}return N}function G(N,Q){var S="",P=N.indexOf("#");if(P!==-1){S=N.substring(P);N=N.substring(0,P)}var R=[];for(var O in Q){if(Q.hasOwnProperty(O)){R.push(O+"="+B(Q[O]))}}return N+((N.indexOf("?")===-1)?"?":"&")+R.join("&")+S}var J=(function(){var P={},Q,O=i.search.substring(1).split("&"),N=O.length;while(N--){Q=O[N].split("=");P[Q[0]]=f(Q[1])}return P}());function o(N){return typeof N==="undefined"}function F(){var O={};var P={a:[1,2,3]},N='{"a":[1,2,3]}';if(JSON&&typeof JSON.stringify==="function"&&JSON.stringify(P).replace((/\s/g),"")===N){return JSON}if(Object.toJSON){if(Object.toJSON(P).replace((/\s/g),"")===N){O.stringify=Object.toJSON}}if(typeof String.prototype.evalJSON==="function"){P=N.evalJSON();if(P.a&&P.a.length===3&&P.a[2]===3){O.parse=function(Q){return Q.evalJSON()}}}if(O.stringify&&O.parse){F=function(){return O};return O}return null}function K(N,O,P){var R;for(var Q in O){if(O.hasOwnProperty(Q)){if(Q in N){R=O[Q];if(typeof R==="object"){K(N[Q],R,P)}else{if(!P){N[Q]=O[Q]}}}else{N[Q]=O[Q]}}}return N}function a(){var N=c.createElement("iframe");N.name="easyXDM_TEST";K(N.style,{position:"absolute",left:"-2000px",top:"0px"});c.body.appendChild(N);y=!(N.contentWindow===E.frames[N.name]);c.body.removeChild(N)}function u(N){if(o(y)){a()}var O;if(y){O=c.createElement('<iframe name="'+N.props.name+'"/>')}else{O=c.createElement("IFRAME");O.name=N.props.name}O.id=O.name=N.props.name;delete N.props.name;if(N.onLoad){q(O,"load",N.onLoad)}if(typeof N.container=="string"){N.container=c.getElementById(N.container)}if(!N.container){O.style.position="absolute";O.style.left="-2000px";O.style.top="0px";N.container=c.body}O.border=O.frameBorder=0;N.container.insertBefore(O,N.container.firstChild);K(O,N.props);return O}function M(Q,P){if(typeof Q=="string"){Q=[Q]}var O,N=Q.length;while(N--){O=Q[N];O=new RegExp(O.substr(0,1)=="^"?O:("^"+O.replace(/(\*)/g,".$1").replace(/\?/g,".")+"$"));if(O.test(P)){return true}}return false}function g(P){var U=P.protocol,O;P.isHost=P.isHost||o(J.xdm_p);if(!P.props){P.props={}}if(!P.isHost){P.channel=J.xdm_c;P.secret=J.xdm_s;P.remote=J.xdm_e;U=J.xdm_p;if(P.acl&&!M(P.acl,P.remote)){throw new Error("Access denied for "+P.remote)}}else{P.remote=v(P.remote);P.channel=P.channel||"default"+h++;P.secret=Math.random().toString(16).substring(2);if(o(U)){if(e(i.href)==e(P.remote)){U="4"}else{if(w(E,"postMessage")||w(c,"postMessage")){U="1"}else{if(w(E,"ActiveXObject")&&w(E,"execScript")){U="3"}else{if(navigator.product==="Gecko"&&"frameElement" in E&&navigator.userAgent.indexOf("WebKit")==-1){U="5"}else{if(P.remoteHelper){P.remoteHelper=v(P.remoteHelper);U="2"}else{U="0"}}}}}}}switch(U){case"0":K(P,{interval:100,delay:2000,useResize:true,useParent:false,usePolling:false},true);if(P.isHost){if(!P.local){var S=i.protocol+"//"+i.host,N=c.body.getElementsByTagName("img"),T;var Q=N.length;while(Q--){T=N[Q];if(T.src.substring(0,S.length)===S){P.local=T.src;break}}if(!P.local){P.local=E}}var R={xdm_c:P.channel,xdm_p:0};if(P.local===E){P.usePolling=true;P.useParent=true;P.local=i.protocol+"//"+i.host+i.pathname+i.search;R.xdm_e=P.local;R.xdm_pa=1}else{R.xdm_e=v(P.local)}if(P.container){P.useResize=false;R.xdm_po=1}P.remote=G(P.remote,R)}else{K(P,{channel:J.xdm_c,remote:J.xdm_e,useParent:!o(J.xdm_pa),usePolling:!o(J.xdm_po),useResize:P.useParent?false:P.useResize})}O=[new easyXDM.stack.HashTransport(P),new easyXDM.stack.ReliableBehavior({}),new easyXDM.stack.QueueBehavior({encode:true,maxLength:4000-P.remote.length}),new easyXDM.stack.VerifyBehavior({initiate:P.isHost})];break;case"1":O=[new easyXDM.stack.PostMessageTransport(P)];break;case"2":O=[new easyXDM.stack.NameTransport(P),new easyXDM.stack.QueueBehavior(),new easyXDM.stack.VerifyBehavior({initiate:P.isHost})];break;case"3":O=[new easyXDM.stack.NixTransport(P)];break;case"4":O=[new easyXDM.stack.SameOriginTransport(P)];break;case"5":O=[new easyXDM.stack.FrameElementTransport(P)];break}O.push(new easyXDM.stack.QueueBehavior({lazy:P.lazy,remove:true}));return O}function x(Q){var R,P={incoming:function(T,S){this.up.incoming(T,S)},outgoing:function(S,T){this.down.outgoing(S,T)},callback:function(S){this.up.callback(S)},init:function(){this.down.init()},destroy:function(){this.down.destroy()}};for(var O=0,N=Q.length;O<N;O++){R=Q[O];K(R,P,true);if(O!==0){R.down=Q[O-1]}if(O!==N-1){R.up=Q[O+1]}}return R}function r(N){N.up.down=N.down;N.down.up=N.up;N.up=N.down=null}b.easyXDM={version:"2.4.8.101",query:J,stack:{},apply:K,getJSONObject:F,whenReady:A};easyXDM.DomHelper={on:q,un:s,requiresJSON:function(N){if(!p(E,"JSON")){c.write('<script type="text/javascript" src="'+N+'"><\/script>')}}};(function(){var N={};easyXDM.Fn={set:function(O,P){N[O]=P},get:function(P,O){var Q=N[P];if(O){delete N[P]}return Q}}}());easyXDM.Socket=function(O){var N=x(g(O).concat([{incoming:function(R,Q){O.onMessage(R,Q)},callback:function(Q){if(O.onReady){O.onReady(Q)}}}])),P=e(O.remote);this.destroy=function(){N.destroy()};this.postMessage=function(Q){N.outgoing(Q,P)};N.init()};easyXDM.Rpc=function(P,O){if(O.local){for(var R in O.local){if(O.local.hasOwnProperty(R)){var Q=O.local[R];if(typeof Q==="function"){O.local[R]={method:Q}}}}}var N=x(g(P).concat([new easyXDM.stack.RpcBehavior(this,O),{callback:function(S){if(P.onReady){P.onReady(S)}}}]));this.destroy=function(){N.destroy()};N.init()};easyXDM.stack.SameOriginTransport=function(O){var P,R,Q,N;return(P={outgoing:function(T,U,S){Q(T);if(S){S()}},destroy:function(){if(R){R.parentNode.removeChild(R);R=null}},onDOMReady:function(){N=e(O.remote);if(O.isHost){K(O.props,{src:G(O.remote,{xdm_e:i.protocol+"//"+i.host+i.pathname,xdm_c:O.channel,xdm_p:4}),name:L+O.channel+"_provider"});R=u(O);easyXDM.Fn.set(O.channel,function(S){Q=S;D(function(){P.up.callback(true)},0);return function(T){P.up.incoming(T,N)}})}else{Q=parent.easyXDM.Fn.get(O.channel,true)(function(S){P.up.incoming(S,N)});D(function(){P.up.callback(true)},0)}},init:function(){A(P.onDOMReady,P)}})};easyXDM.stack.PostMessageTransport=function(Q){var S,T,O,P;function N(U){if(U.origin){return U.origin}if(U.uri){return e(U.uri)}if(U.domain){return i.protocol+"//"+U.domain}throw"Unable to retrieve the origin of the event"}function R(V){var U=N(V);if(U==P&&V.data.substring(0,Q.channel.length+1)==Q.channel+" "){S.up.incoming(V.data.substring(Q.channel.length+1),U)}}return(S={outgoing:function(V,W,U){O.postMessage(Q.channel+" "+V,W||P);if(U){U()}},destroy:function(){s(E,"message",R);if(T){O=null;T.parentNode.removeChild(T);T=null}},onDOMReady:function(){P=e(Q.remote);if(Q.isHost){q(E,"message",function U(V){if(V.data==Q.channel+"-ready"){O=("postMessage" in T.contentWindow)?T.contentWindow:T.contentWindow.document;s(E,"message",U);q(E,"message",R);D(function(){S.up.callback(true)},0)}});K(Q.props,{src:G(Q.remote,{xdm_e:i.protocol+"//"+i.host,xdm_c:Q.channel,xdm_p:1}),name:L+Q.channel+"_provider"});T=u(Q)}else{q(E,"message",R);O=("postMessage" in E.parent)?E.parent:E.parent.document;O.postMessage(Q.channel+"-ready",P);D(function(){S.up.callback(true)},0)}},init:function(){A(S.onDOMReady,S)}})};easyXDM.stack.FrameElementTransport=function(O){var P,R,Q,N;return(P={outgoing:function(T,U,S){Q.call(this,T);if(S){S()}},destroy:function(){if(R){R.parentNode.removeChild(R);R=null}},onDOMReady:function(){N=e(O.remote);if(O.isHost){K(O.props,{src:G(O.remote,{xdm_e:i.protocol+"//"+i.host+i.pathname+i.search,xdm_c:O.channel,xdm_p:5}),name:L+O.channel+"_provider"});R=u(O);R.fn=function(S){delete R.fn;Q=S;D(function(){P.up.callback(true)},0);return function(T){P.up.incoming(T,N)}}}else{if(c.referrer&&c.referrer!=J.xdm_e){E.parent.location=J.xdm_e}else{if(c.referrer!=J.xdm_e){E.parent.location=J.xdm_e}Q=E.frameElement.fn(function(S){P.up.incoming(S,N)});P.up.callback(true)}}},init:function(){A(P.onDOMReady,P)}})};easyXDM.stack.NixTransport=function(O){var Q,S,R,N,P;return(Q={outgoing:function(U,V,T){R(U);if(T){T()}},destroy:function(){P=null;if(S){S.parentNode.removeChild(S);S=null}},onDOMReady:function(){N=e(O.remote);if(O.isHost){try{if(!w(E,"getNixProxy")){E.execScript("Class NixProxy\n    Private m_parent, m_child, m_Auth\n\n    Public Sub SetParent(obj, auth)\n        If isEmpty(m_Auth) Then m_Auth = auth\n        SET m_parent = obj\n    End Sub\n    Public Sub SetChild(obj)\n        SET m_child = obj\n        m_parent.ready()\n    End Sub\n\n    Public Sub SendToParent(data, auth)\n        If m_Auth = auth Then m_parent.send(CStr(data))\n    End Sub\n    Public Sub SendToChild(data, auth)\n        If m_Auth = auth Then m_child.send(CStr(data))\n    End Sub\nEnd Class\nFunction getNixProxy()\n    Set GetNixProxy = New NixProxy\nEnd Function\n","vbscript")}P=getNixProxy();P.SetParent({send:function(V){Q.up.incoming(V,N)},ready:function(){D(function(){Q.up.callback(true)},0)}},O.secret);R=function(V){P.SendToChild(V,O.secret)}}catch(U){throw new Error("Could not set up VBScript NixProxy:"+U.message)}K(O.props,{src:G(O.remote,{xdm_e:i.protocol+"//"+i.host+i.pathname+i.search,xdm_c:O.channel,xdm_s:O.secret,xdm_p:3}),name:L+O.channel+"_provider"});S=u(O);S.contentWindow.opener=P}else{if(c.referrer&&c.referrer!=J.xdm_e){E.parent.location=J.xdm_e}else{if(c.referrer!=J.xdm_e){E.parent.location=J.xdm_e}try{P=E.opener}catch(T){throw new Error("Cannot access window.opener")}P.SetChild({send:function(V){b.setTimeout(function(){Q.up.incoming(V,N)},0)}});R=function(V){P.SendToParent(V,O.secret)};D(function(){Q.up.callback(true)},0)}}},init:function(){A(Q.onDOMReady,Q)}})};easyXDM.stack.NameTransport=function(R){var S;var U,Y,Q,W,X,O,N;function V(ab){var aa=R.remoteHelper+(U?"#_3":"#_2")+R.channel;Y.contentWindow.sendMessage(ab,aa)}function T(){if(U){if(++W===2||!U){S.up.callback(true)}}else{V("ready");S.up.callback(true)}}function Z(aa){S.up.incoming(aa,O)}function P(){if(X){D(function(){X(true)},0)}}return(S={outgoing:function(ab,ac,aa){X=aa;V(ab)},destroy:function(){Y.parentNode.removeChild(Y);Y=null;if(U){Q.parentNode.removeChild(Q);Q=null}},onDOMReady:function(){U=R.isHost;W=0;O=e(R.remote);R.local=v(R.local);if(U){easyXDM.Fn.set(R.channel,function(ab){if(U&&ab==="ready"){easyXDM.Fn.set(R.channel,Z);T()}});N=G(R.remote,{xdm_e:R.local,xdm_c:R.channel,xdm_p:2});K(R.props,{src:N+"#"+R.channel,name:L+R.channel+"_provider"});Q=u(R)}else{R.remoteHelper=R.remote;easyXDM.Fn.set(R.channel,Z)}Y=u({props:{src:R.local+"#_4"+R.channel},onLoad:function aa(){s(Y,"load",aa);easyXDM.Fn.set(R.channel+"_load",P);(function ab(){if(typeof Y.contentWindow.sendMessage=="function"){T()}else{D(ab,50)}}())}})},init:function(){A(S.onDOMReady,S)}})};easyXDM.stack.HashTransport=function(P){var S;var X=this,V,Q,N,T,ac,R,ab;var W,O;function aa(ae){if(!ab){return}var ad=P.remote+"#"+(ac++)+"_"+ae;((V||!W)?ab.contentWindow:ab).location=ad}function U(ad){T=ad;S.up.incoming(T.substring(T.indexOf("_")+1),O)}function Z(){if(!R){return}var ad=R.location.href,af="",ae=ad.indexOf("#");if(ae!=-1){af=ad.substring(ae)}if(af&&af!=T){U(af)}}function Y(){Q=setInterval(Z,N)}return(S={outgoing:function(ad,ae){aa(ad)},destroy:function(){E.clearInterval(Q);if(V||!W){ab.parentNode.removeChild(ab)}ab=null},onDOMReady:function(){V=P.isHost;N=P.interval;T="#"+P.channel;ac=0;W=P.useParent;O=e(P.remote);if(V){P.props={src:P.remote,name:L+P.channel+"_provider"};if(W){P.onLoad=function(){R=E;Y();S.up.callback(true)}}else{var af=0,ad=P.delay/50;(function ae(){if(++af>ad){throw new Error("Unable to reference listenerwindow")}try{R=ab.contentWindow.frames[L+P.channel+"_consumer"]}catch(ag){}if(R){Y();S.up.callback(true)}else{D(ae,50)}}())}ab=u(P)}else{R=E;Y();if(W){ab=parent;S.up.callback(true)}else{K(P,{props:{src:P.remote+"#"+P.channel+new Date(),name:L+P.channel+"_consumer"},onLoad:function(){S.up.callback(true)}});ab=u(P)}}},init:function(){A(S.onDOMReady,S)}})};easyXDM.stack.ReliableBehavior=function(O){var Q,S;var R=0,N=0,P="";return(Q={incoming:function(V,T){var U=V.indexOf("_"),W=V.substring(0,U).split(",");V=V.substring(U+1);if(W[0]==R){P="";if(S){S(true)}}if(V.length>0){Q.down.outgoing(W[1]+","+R+"_"+P,T);if(N!=W[1]){N=W[1];Q.up.incoming(V,T)}}},outgoing:function(V,T,U){P=V;S=U;Q.down.outgoing(N+","+(++R)+"_"+V,T)}})};easyXDM.stack.QueueBehavior=function(P){var S,T=[],W=true,Q="",V,N=0,O=false,R=false;function U(){if(P.remove&&T.length===0){r(S);return}if(W||T.length===0||V){return}W=true;var X=T.shift();S.down.outgoing(X.data,X.origin,function(Y){W=false;if(X.callback){D(function(){X.callback(Y)},0)}U()})}return(S={init:function(){if(o(P)){P={}}if(P.maxLength){N=P.maxLength;R=true}if(P.lazy){O=true}else{S.down.init()}},callback:function(Y){W=false;var X=S.up;U();X.callback(Y)},incoming:function(aa,Y){if(R){var Z=aa.indexOf("_"),X=parseInt(aa.substring(0,Z),10);Q+=aa.substring(Z+1);if(X===0){if(P.encode){Q=f(Q)}S.up.incoming(Q,Y);Q=""}}else{S.up.incoming(aa,Y)}},outgoing:function(ab,Y,aa){if(P.encode){ab=B(ab)}var X=[],Z;if(R){while(ab.length!==0){Z=ab.substring(0,N);ab=ab.substring(Z.length);X.push(Z)}while((Z=X.shift())){T.push({data:X.length+"_"+Z,origin:Y,callback:X.length===0?aa:null})}}else{T.push({data:ab,origin:Y,callback:aa})}if(O){S.down.init()}else{U()}},destroy:function(){V=true;S.down.destroy()}})};easyXDM.stack.VerifyBehavior=function(R){var S,Q,O,P=false;function N(){Q=Math.random().toString(16).substring(2);S.down.outgoing(Q)}return(S={incoming:function(V,T){var U=V.indexOf("_");if(U===-1){if(V===Q){S.up.callback(true)}else{if(!O){O=V;if(!R.initiate){N()}S.down.outgoing(V)}}}else{if(V.substring(0,U)===O){S.up.incoming(V.substring(U+1),T)}}},outgoing:function(V,T,U){S.down.outgoing(Q+"_"+V,T,U)},callback:function(T){if(R.initiate){N()}}})};easyXDM.stack.RpcBehavior=function(T,O){var Q,V=O.serializer||F();var U=0,S={};function N(W){W.jsonrpc="2.0";Q.down.outgoing(V.stringify(W))}function R(W,Y){var X=Array.prototype.slice;return function(){var Z=arguments.length,ab,aa={method:Y};if(Z>0&&typeof arguments[Z-1]==="function"){if(Z>1&&typeof arguments[Z-2]==="function"){ab={success:arguments[Z-2],error:arguments[Z-1]};aa.params=X.call(arguments,0,Z-2)}else{ab={success:arguments[Z-1]};aa.params=X.call(arguments,0,Z-1)}S[""+(++U)]=ab;aa.id=U}else{aa.params=X.call(arguments,0)}if(W.namedParams&&aa.params.length===1){aa.params=aa.params[0]}N(aa)}}function P(W,Y,ab,Z){if(!ab){if(Y){N({id:Y,error:{code:-32601,message:"Procedure not found."}})}return}var ad=false,ac,aa;if(Y){ac=function(af){if(ad){return}ad=true;N({id:Y,result:af})};aa=function(af){if(ad){return}ad=true;var ag={id:Y,error:{code:-32099,message:"Application error: "+af}};if(typeof af=="object"&&"data" in af){ag.error.data=af.data}N(ag)}}else{ac=aa=k}if(!n(Z)){Z=[Z]}try{var ae=ab.method.apply(ab.scope,Z.concat([ac,aa]));if(!o(ae)){ac(ae)}}catch(X){aa(X.message)}}return(Q={incoming:function(X,W){var Y=V.parse(X);if(Y.method){if(O.handle){O.handle(Y,N)}else{P(Y.method,Y.id,O.local[Y.method],Y.params)}}else{var Z=S[Y.id];if(Y.error){if(Z.error){Z.error(Y.error)}}else{if(Z.success){Z.success(Y.result)}}delete S[Y.id]}},init:function(){if(O.remote){for(var W in O.remote){if(O.remote.hasOwnProperty(W)){T[W]=R(O.remote[W],W)}}}Q.down.init()},destroy:function(){for(var W in O.remote){if(O.remote.hasOwnProperty(W)&&T.hasOwnProperty(W)){delete T[W]}}Q.down.destroy()}})}})(window,document,location,window.setTimeout,decodeURIComponent,encodeURIComponent);

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
    var tag = document.createElement("script");
    tag.setAttribute("src", 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js');
    tag.setAttribute("type", "text/javascript");
    document.getElementsByTagName("head")[0].appendChild(tag);
    optemo_socket_activator();
}
