/*Omniture fix for Error: Attribute only valid on v:image */
/*Reference: http://groups.google.com/group/raphaeljs/browse_thread/thread/f41f4db37846e468 */

var omniture_fix = (function() {
   if (typeof s == "undefined")
        setTimeout("omniture_fix",1000);
   else {
   var old = s.ot;
   s.ot = function(el) {
       return el.tagUrn ? '' : old(el);
   };
   }
});
setTimeout("omniture_fix",1000);