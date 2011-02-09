//Code to test for duplicates in the BBY API
var skus = [];
$.get("http://www.bestbuy.ca/en-CA/api/search/products(categoryPath.id=20218)?page=1&pageSize=1000").done(function(data){
	var d = jQuery.parseJSON(data);
	var totalPages = parseFloat(d.totalPages);
	for (var i=0; i < d.products.length; i++)
	{
		skus.push(d.products[i].sku);
	}
	var currentPage = 2;
	//Find the duplicates
	sorted = skus.sort();
	var previous;
	var duplicates = [];
	for (var i=0; i < sorted.length; i++)
	{
		if (sorted[i] == previous) duplicates.push(sorted[i]);
		previous = sorted[i];
	}
	alert("Number of results in the digital camera department: " + skus.length + "\n" + "with " + duplicates.length + " duplicates: \n" + duplicates.join("\n"));
	
	var reqs = [];
	for (var cp = 2; cp <= totalPages; cp++)
	{
		reqs.push($.get("http://www.bestbuy.ca/en-CA/api/search/products(categoryPath.id=20218)?page="+cp));
	}
	
	$.when.apply(this,reqs).done(function(){
		for (var j = 0; j < arguments.length; j++)
		{
			var d = jQuery.parseJSON(arguments[j][0]);
			for (var i=0; i < d.products.length; i++)
			{
				skus.push(d.products[i].sku);
			}
		}
		
		
	});
});