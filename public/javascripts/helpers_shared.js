/*   Helper functions. All of these are used in application.js. These are also shared with all views (Direct/Assist/Mobile).
opt_appendStringWithToken(items, newitem, token)  -  For lists like this: "318*124*19"
opt_removeStringWithToken(items, rem, token)  -  As above, for removal
*/

// Add an item to a list with a supplied token
function opt_appendStringWithToken(items, newitem, token)
{
	return ((items == "") ? newitem : items+token+newitem);
}

// Remove an item from a list with a supplied token
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
