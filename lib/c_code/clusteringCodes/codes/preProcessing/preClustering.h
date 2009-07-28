string preClustering(string* varNames, map<const string, int>productNames, string productName, string* conFeatureNames, string* catFeatureNames, string* boolFeatureNames, string* indicatorNames, string region){
	
	string filteringCommand;
	
	string brand = "";
	string var;
	catFeatureNames[0]= "brand";
	conFeatureNames[0]= "price";
	
	switch(productNames[productName]){
		case 1:
				conFeatureNames[1]= "displaysize";  
			    conFeatureNames[2]= "opticalzoom";
			    conFeatureNames[3]= "maximumresolution";
				varNames[0] = "layer";
				varNames[1] = "camid";
				varNames[2] = "brand";
				varNames[3] = "price_min";
				varNames[4] = "price_max";
				varNames[5] = "displaysize_min";
				varNames[6] = "displaysize_max";
				varNames[7] = "opticalzoom_min";
				varNames[8] = "opticalzoom_max";
				varNames[9] = "maximumresolution_min";
				varNames[10] = "maximumresolution_max";
				varNames[11] = "session_id";
				indicatorNames[0] = "Price";
				indicatorNames[1] = "Display Size";
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
					filteringCommand += "s where (instock=1 and instock_ca=0 and (scanner IS NOT NULL) and (printserver IS NOT NULL) and ";
				}else if(region == "ca"){
					filteringCommand += "s where (instock=1 and instock_ca=1 and (scanner IS NOT NULL) and (printserver IS NOT NULL) and ";
				}
					
				filteringCommand += "(resolutionmax >0) and (ppm >0 ) and (itemwidth > 0) and (paperinput > 0))";
			
				break;
		default: 
				break;
	}
	return filteringCommand;
	
}
