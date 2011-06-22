//Lightweight JSONP fetcher - www.nonobtrusive.com
optemo_french = (window.location.pathname.match(/^\/fr-CA/)), OPT_REMOTE = 'http://' + ((optemo_french) ? "fr." : "") + 'sandbox.optemo.com';
var JSONP=(function(){var a=0,c,f,b,d=this;function e(j){var i=document.createElement("script"),h=false;i.src=j;i.async=true;i.onload=i.onreadystatechange=function(){if(!h&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){h=true;i.onload=i.onreadystatechange=null;if(i&&i.parentNode){i.parentNode.removeChild(i)}}};if(!c){c=document.getElementsByTagName("head")[0]}c.appendChild(i)}function g(h,j,k){f="?";j=j||{};for(b in j){if(j.hasOwnProperty(b)){f+=encodeURIComponent(b)+"="+encodeURIComponent(j[b])+"&"}}var i="json"+(++a);d[i]=function(l){k(opt_parse_data_by_pattern(l, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, OPT_REMOTE + "$1");})));d[i]=null;try{delete d[i]}catch(m){}};e(h+f+"callback="+i);return i}return{get:g}}());
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
if (opt_history.length > 0)
    var opt_options = {embedding:'true',hist:opt_history};
else
    var opt_options = {embedding:'true'};
JSONP.get(OPT_REMOTE, opt_options, opt_insert);
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