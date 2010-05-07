string preClustering(map<const string, int>productNames, string productName, string* conFeatureNames, string* catFeatureNames, string* boolFeatureNames, string* indicatorNames, string region){

	string filteringCommand;
	int conFeatureN, boolFeatureN, catFeatureN;
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
				filteringCommand += nullCheck;
				filteringCommand += ");";
				break;
		case 2:	
				conFeatureN = 5;
				catFeatureN = 1;
				boolFeatureN = 2;
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
			
				break;
		case 3:
				conFeatureN = 4;
				boolFeatureN = 0;
				conFeatureNames[1] = "width"; 
			    conFeatureNames[2] = "miniorder";
                conFeatureNames[3] = "species_hardness";

				indicatorNames[1] = "Item Width";
				indicatorNames[2] = "Minimum Order";
				indicatorNames[3] = "Species Hardness";
			
			
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
		filteringCommand = "SELECT id FROM products where products.product_type=\'";


	   filteringCommand += productName;
	   filteringCommand += "_";
	   filteringCommand += region;
	   filteringCommand += "\' and products.instock=1 and id IN (select product_id from cont_specs where cont_specs.name = 'price' and cont_specs.value>0)";
       
	   for (int f=1; f<conFeatureN; f++){
	   	filteringCommand += " and id IN (select product_id from cont_specs where cont_specs.name =\'";
	   	filteringCommand += conFeatureNames[f];
	   	filteringCommand += "\' AND cont_specs.value>0)" ;
	   }	
       
	   for (int f=0; f<boolFeatureN; f++){
	   	 filteringCommand += " and id IN (select product_id from bin_specs where bin_specs.name = \'";
	   	 filteringCommand += boolFeatureNames[f];
	   	 filteringCommand += "\' and (bin_specs.value =0 OR bin_specs.value=1))" ;
	   }
       
	   filteringCommand += ";";
	cout<<"filtering Command is :"<<filteringCommand<<endl;
	return filteringCommand;
	
}
