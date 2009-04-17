// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function fadeout(id)
{
	$('fade').style.height = (getDocHeight())+'px';
	$('fade').setStyle({display: 'inline'});
	//IE Compatibility
	var iebody=(document.compatMode && document.compatMode != "BackCompat")? document.documentElement : document.body
	var dsoctop=document.all? iebody.scrollTop : pageYOffset
	$('info').style.left = ((document.body.clientWidth-800)/2)+'px';
	$('info').style.top = (dsoctop+5)+'px';
	$('info').setStyle({display: 'inline'});
	$('myfilter_brand').setStyle({visibility: 'hidden'});
	loadinfo(id);
}

function fadein()
{
	$('myfilter_brand').setStyle({visibility: 'visible'});
	$('fade').setStyle({display: 'none'});
	$('info').setStyle({display: 'none'});
	
}

function loadinfo(id)
{
	new Ajax.Updater('info','/products/show/'+id+'?plain=true', {method:	'get'});
}

function saveit(id)
{
	if ($('deleteme')){$('deleteme').remove()}
	new Ajax.Updater({success:'savebar_content'}, '/saveds/create/'+id, {
	  method: 'get',
	  insertion: Insertion.Bottom
	  });
}

function remove(id)
{
	new Ajax.Request('/saveds/destroy/'+id, {
	  method: 'get'
	});
	$('c'+id).remove();
}

function removeBrand(str)
{
	$('myfilter_Xbrand').value = str;
	$('brand_form').submit();
}


/*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
function getDocHeight() {
    var D = document;
    return Math.max(
        Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
        Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
        Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    );
}

function resetFilter() {
	//$('myfilter_brand').selectedIndex = "All Brands";
	var disp = $('filterbar').getElementsByClassName('disp');
	var slider = $('filterbar').getElementsByClassName('slider');
	for (i=0;i<mysliders.length;i++)
	{
		var name = slider[i].id.substr(0,slider[i].id.length-6);
		$('myfilter_'+name+'_min').value = mysliders[i].minimum;
		$('myfilter_'+name+'_max').value = mysliders[i].maximum;
		disp[i].innerHTML = mysliders[i].minimum + "-" + mysliders[i].maximum;
		mysliders[i].setValue(mysliders[i].minimum, 0);
		mysliders[i].setValue(mysliders[i].maximum, 1);
	}
	//alert(mysliders.length)
	//i.setValue(0);
	//i.setValue(20);
	//alert(array[i].id)
}