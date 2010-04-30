string preClustering(map<const string, int>productNames, string productName, string* conFeatureNames, string* catFeatureNames, string* boolFeatureNames, string* indicatorNames, string region){

	string filteringCommand;
	int conFeatureN, boolFeatureN;
	string brand = "";
	string var;
	string nullCheck = "";
	catFeatureNames[0] = "brand";
	conFeatureNames[0] = "price";
	indicatorNames[0] = "Price";
	switch(productNames[productName]){
		case 1:
				conFeatureN = 4;
				boolFeatureN = 0;
				conFeatureNames[1]= "displaysize"; 
			    conFeatureNames[2]= "opticalzoom";
			    conFeatureNames[3]= "maximumresolution";
				//conFeatureNames[4]= "itemweight";
				//boolFeatureNames[0] = "slr";
				//boolFeatureNames[1] = "waterproof";

				indicatorNames[1] = "Item Weight";
				indicatorNames[2] = "Optical Zoom";
				indicatorNames[3] = "MegaPixels";
				filteringCommand = "SELECT * FROM ";
				filteringCommand += productName;
				filteringCommand += "s where instock=1;";
				filteringCommand = "SELECT * FROM ";
				filteringCommand += productName;
				nullCheck += "((price IS NOT NULL)";
				for (int f=1; f<conFeatureN; f++){
					nullCheck += " and (";
					nullCheck += conFeatureNames[f];
					nullCheck += " IS NOT NULL";
					nullCheck += ")"; 
				} 
				for (int f=0; f<boolFeatureN; f++){
					nullCheck += " and (";
					nullCheck += conFeatureNames[f];
					nullCheck += " IS NOT NULL";
					nullCheck += ")";
				}
				nullCheck += ")";
				if (region == "us"){
					filteringCommand += "s where (instock=1 and ";
					
				}else if(region == "ca"){
					filteringCommand += "s where (instock_ca=1 and (scanner IS NOT NULL) and (printserver IS NOT NULL) and ";
				}
				filteringCommand += nullCheck;
				filteringCommand += ");";
				break;
		case 2:	
				conFeatureNames[1]= "ppm";  
			    conFeatureNames[2]= "itemwidth";
			    conFeatureNames[3]= "paperinput";
				conFeatureNames[4] = "resolutionmax";
				boolFeatureNames[0] = "scanner";
				boolFeatureNames[1] = "printserver";
				
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
		case 3:
				conFeatureN = 4;
				boolFeatureN = 0;
				conFeatureNames[1] = "width"; 
			    conFeatureNames[2] = "miniorder";
                conFeatureNames[3] = "species_hardness";
//			    catFeatureNames[1] = "species";
//			    catFeatureNames[2] = "feature";
//			    catFeatureNames[3] = "colorrange";

				indicatorNames[1] = "Item Width";
				indicatorNames[2] = "Minimum Order";
				indicatorNames[3] = "Species Hardness";
				filteringCommand = "SELECT * FROM ";
				filteringCommand += productName;
				filteringCommand += "s where instock=1 AND ";
				nullCheck += "((price IS NOT NULL)";
				for (int f=1; f<conFeatureN; f++){
					nullCheck += " and (";
					nullCheck += conFeatureNames[f];
					nullCheck += " IS NOT NULL";
					nullCheck += ")"; 
				}  
				for (int f=0; f<boolFeatureN; f++){
					nullCheck += " and (";
					nullCheck += conFeatureNames[f];
					nullCheck += " IS NOT NULL";
					nullCheck += ")";
				}
				nullCheck += ")";
				filteringCommand += nullCheck;
  		break;
  	case 4:
  			conFeatureN = 4;
  			boolFeatureN = 0;
  			conFeatureNames[1] = "ram"; 
  		    conFeatureNames[2] = "hd";
            conFeatureNames[3] = "screensize";


  			indicatorNames[1] = "Item Width";
  			indicatorNames[2] = "Minimum Order";
				indicatorNames[3] = "Species Hardness";
  			filteringCommand = "SELECT * FROM ";
  			filteringCommand += productName;
  			filteringCommand += "s where instock=1 AND ";
  			nullCheck += "((price IS NOT NULL)";
  			for (int f=1; f<conFeatureN; f++){
  				nullCheck += " and (";
  				nullCheck += conFeatureNames[f];
  				nullCheck += " IS NOT NULL";
  				nullCheck += ")"; 
  			}  
  			for (int f=0; f<boolFeatureN; f++){
  				nullCheck += " and (";
  				nullCheck += conFeatureNames[f];
  				nullCheck += " IS NOT NULL";
  				nullCheck += ")";
  			}
  			nullCheck += ")";
  						filteringCommand += nullCheck;
  						break;
  default: 
				break;
	}
	return filteringCommand;
	
}
