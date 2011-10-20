//--------------------------------------//
//              Cookies                 //
//--------------------------------------//
var optemo_module;
optemo_module = (function (my){
  //****Public Functions****
  // This should return all cookie values in an array.
  my.readAllCookieValues = function(name) {
      var skus, cookie = readCookie(name);
      if (cookie) {
        //Remove items that don't match the current product class
        var c_product_type = $('#main').attr('data-product_type');
        skus = $.grep(cookie.split('*'), function(value) {
          return value.split(',')[1] == c_product_type;
        });
        //Remove product_type from cookie values
        skus = $.map(skus, function(value) {
          return value.split(',')[0];
        });
      } else {
        // Fix for cookie not saving but some product checkboxes are checked. Issue found in IE6.
        skus = [];
        $(".optemo_compare_checkbox:checked").each (function (index) {
            skus.push($(this).attr('data-sku'));
        });
      }
      return skus;
  };
  
  my.addValueToCookie = function(name, value, days) {
      var savedData = readCookie(name), numDays = days || 30;
      if (savedData) {
          // Cookie exists, add additional values with * as the token.
          savedData = opt_appendStringWithToken(savedData, value, '*');
          createCookie(name, savedData, numDays);
      } else {
          // Cookie does not exist, so just create with the bare value
          createCookie(name, value, numDays);
      }
  }
  
  my.removeValueFromCookie = function(name, value, days) {
      var savedData = readCookie(name), numDays = days || 30;
      if (savedData) {
          savedData = opt_removeStringWithToken(savedData, value, '*');
          if (savedData == "") { // No values left to store
              my.eraseCookie(name);
          } else {
              createCookie(name, savedData, numDays);
          }
      }
      // else do nothing
  }
  my.eraseCookie = function(name) {
      createCookie(name,"",-1);
  }
  
  //****Private Functions****
  // Add an item to a list with a supplied token - For lists like this: "318*124*19"
  function opt_appendStringWithToken(items, newitem, token)
  {
  	return ((items == "") ? newitem : items+token+newitem);
  }

  // Remove an item from a list with a supplied token - As above, for removal
  function opt_removeStringWithToken(items, rem, token)
  {
  	i = items.split(token);
  	var newArray = [];
  	for (j in i)
  	{
  		if (i[j].match(new RegExp("^" + rem )))
  			continue;
  		newArray.push(i[j]);
  	}
  	return newArray.join(token);
  }

  function createCookie(name,value,days) {
      if (days) {
          var date = new Date();
          date.setTime(date.getTime()+(days*24*60*60*1000));
          var expires = "; expires="+date.toGMTString();
      }
      else var expires = "";
      document.cookie = name+"="+value+expires+"; path=/";
  }

  function readCookie(name) {
      var nameEQ = name + "=";
      var ca = document.cookie.split(';');
      for(var i=0;i < ca.length;i++) {
          var c = ca[i];
          while (c.charAt(0)==' ') c = c.substring(1,c.length);
          if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
      }
      return null;
  }

  return my;
})(optemo_module || {});