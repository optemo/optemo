//Lightweight JSONP fetcher - www.nonobtrusive.com
var REMOTE = 'http://192.168.5.100:3000';
var JSONP=(function(){var a=0,c,f,b,d=this;function e(j){var i=document.createElement("script"),h=false;i.src=j;i.async=true;i.onload=i.onreadystatechange=function(){if(!h&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){h=true;i.onload=i.onreadystatechange=null;if(i&&i.parentNode){i.parentNode.removeChild(i)}}};if(!c){c=document.getElementsByTagName("head")[0]}c.appendChild(i)}function g(h,j,k){f="?";j=j||{};for(b in j){if(j.hasOwnProperty(b)){f+=encodeURIComponent(b)+"="+encodeURIComponent(j[b])+"&"}}var i="json"+(++a);d[i]=function(l){k(l);d[i]=null;try{delete d[i]}catch(m){}};e(h+f+"callback="+i);return i}return{get:g}}());
function opt_s(f){/in/.test(document.readyState)?setTimeout('opt_s('+f+')',9):f()}
JSONP.get(REMOTE, {embedding:'true', param2:'456'}, function(data){
        //Fix relative urls
        data = opt_parse_data_by_pattern(data, "<img[^>]+>", (function(mystring){return mystring.replace(/(\/images\/[^?]+)/, REMOTE + "$1");}));
        
        var se = document.createElement("div");
        se.setAttribute("style","display:none;");
        se.id = "opt_new";
        document.body.appendChild(se);
        se.innerHTML = data;
        opt_s(function(){
            var n = document.getElementById("opt_new");
            document.getElementById("optemo_embedder").appendChild(n);
            n.setAttribute("style","display:block;");
        });
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