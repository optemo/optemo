/*function checkUserLoggedIn()
{
	if(FB.Connect.get_status().result == FB.ConnectState.connected)
	{
		alert("redirecting...");
		window.location = "/products";
	}
}*/
/*	FB.ensureInit(function(){	// Required, since FB.init runs asynchronously
		if(FB.Connect.get_status().result == FB.ConnectState.connected)
		{
			window.location=targetLocationString();
		}
	}); */	

/*function user_logout()
{
//	FB.Connect.logoutAndRedirect("/products");
	FB.Connect.logout(function() { FB.XFBML.Host.parseDomTree(); });

}*/

function user_logged_in(backtoaddress)
{
	if (backtoaddress.length!=0)
	{
		window.location = backtoaddress;
	}
	else
	{
		window.location = '/products';
	}
}

function targetLocationString()
{
	qstring = window.location.search.substring(1);
	var backTo = qstring.split("=");
	if(backTo == null)
		return "/products";
	else
		return backTo;
}		
   