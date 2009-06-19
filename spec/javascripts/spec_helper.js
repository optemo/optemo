
function additem(id, el)
{
	var saveme = 	'<div class="saveditem" id="c' + id + '"/>'
	
	//TODO
	
	/*
					+ '<img width="52" height="50" src="http://ecx.images-amazon.com/images/I/41937WFPE3L._SL160_.jpg" '
					+ 'onclick="fadeout(' + id + ');" alt="41937wfpe3l"/>'
					+ '<p class="smalldesc">'
					+  '<a href="javascript:fadeout('+id+');">Brother HL-6050D<\/a><\/p>'
		 			+ '<a class="deleteX" href="javascript:remove('+id+')">'
	 				+ '<img src="/images/close.gif?1243827323" alt="Close"\/><\/a>' 
		 			+ "<\/div>");
		*/ 
		
		
		
	el.append(saveme);
	
	
	
	/*
	$('#savebar_content').append('<div class="saveditem" id="c51">'+
		'<img width="52" height="50" src="http://ecx.images-amazon.com/images/I/41937WFPE3L._SL160_.jpg" onclick="fadeout(51);" alt="41937wfpe3l"/>'
		+'<p class="smalldesc"><a href="javascript:fadeout(51);">Brother HL-6050D</a></p>'
		+'<a class="deleteX" href="javascript:remove(51)"><img src="/images/close.gif?1243827323" alt="Close"/></a>'
		+'</div>');
		*/

}