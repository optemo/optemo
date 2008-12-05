// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function fadeout(id)
{
	$('fade').setStyle({display: 'inline'});
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
	new Ajax.Updater('info','/cameras/show/'+id, {method:	'get'});
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