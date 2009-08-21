string preClustering(map<const string, int>productNames, string productName, string* conFeatureNames, string* catFeatureNames, string* boolFeatureNames, string* indicatorNames, string region){

	string filteringCommand;
	
	string brand = "";
	string var;
	catFeatureNames[0]= "brand";
	conFeatureNames[0]= "price";
	switch(productNames[productName]){
		case 1:
				//conFeatureNames[1]= "itemweight";  
			    conFeatureNames[2]= "opticalzoom";
			    conFeatureNames[3]= "maximumresolution";
				conFeatureNames[1] = "displaysize";
			//	conFeatureNames[5] = "minimumfocallength";
			//	conFeatureNames[6] = "maximumfocallength";
			//	conFeatureNames[7] = "minimumshutterspeed";
			//	conFeatureNames[8] = "maximumshutterspeed";
			//	boolFeatureNames[0] = "slr";
			//	boolFeatureNames[1] = "waterproof";
			//	boolFeatureNames[2] = "bulb";
			
			
				
				
				indicatorNames[0] = "Price";
			//	indicatorNames[1] = "Item Weight";
				indicatorNames[2] = "Optical Zoom";
				indicatorNames[3] = "MegaPixels";
				filteringCommand = "SELECT * FROM ";
				filteringCommand += productName;
				filteringCommand += "s where instock=1;";
				break;
		case 2:	
				conFeatureNames[1]= "ppm";  
			    conFeatureNames[2]= "itemwidth";
			    conFeatureNames[3]= "paperinput";
				conFeatureNames[4] = "resolutionmax";
				boolFeatureNames[0] = "scanner";
				boolFeatureNames[1] = "printserver";
				
				indicatorNames[0]="price";
				indicatorNames[1]= "ppm";  
			    indicatorNames[2]= "itemwidth";
			    indicatorNames[3]= "paperinput";
				indicatorNames[4] = "Maximum Resolution";
				indicatorNames[5] = "scanner";
				indicatorNames[6] = "printserver";
				
				filteringCommand = "SELECT * FROM ";
				filteringCommand += productName;
				if (region == "us"){
					filteringCommand += "s where (instock=1 and (scanner IS NOT NULL) and (printserver IS NOT NULL) and ";
				}else if(region == "ca"){
					filteringCommand += "s where (instock_ca=1 and (scanner IS NOT NULL) and (printserver IS NOT NULL) and ";
				}
					
				filteringCommand += "(resolutionmax >0) and (ppm >0 ) and (itemwidth > 0) and (paperinput > 0))";
			
				break;
		default: 
				break;
	}
	return filteringCommand;
	
}
