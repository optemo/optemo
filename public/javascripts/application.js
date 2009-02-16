// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function fadeout(id)
{
	$('fade').style.height = (getDocHeight())+'px';
	$('fade').setStyle({display: 'inline'});
	$('info').style.left = ((document.body.clientWidth-800)/2)+'px';
	$('info').setStyle({display: 'inline'});
	loadinfo(id);
}

function fadein()
{
	$('fade').setStyle({display: 'none'});
	$('info').setStyle({display: 'none'});
	
}

function loadinfo(id)
{
	new Ajax.Updater('info','/cameras/show/'+id+'?plain=true', {method:	'get'});
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

/*http://james.padolsey.com/javascript/get-document-height-cross-browser/*/
function getDocHeight() {
    var D = document;
    return Math.max(
        Math.max(D.body.scrollHeight, D.documentElement.scrollHeight),
        Math.max(D.body.offsetHeight, D.documentElement.offsetHeight),
        Math.max(D.body.clientHeight, D.documentElement.clientHeight)
    );
}