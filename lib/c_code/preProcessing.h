//preProcessing.h

void parseInput(<map> productFeatures, string productName, string argument, string* brands, bool* catFilteredFeatures, bool* conFilteredFeatures, bool* boolFilteredFeatures, double* filteredRange){
	
	string* varNames = productFeatures.find(productName);
	string brand = "";
	
	if (producName == "camera"){
		for (int j=0; j<varNamesN; j++){
			var = varNames[j];
			ind = argu.find(var, 0);
			endit = argu.find("\n", ind);
			startit = ind + var.length() + 2;
			lengthit = endit - startit;
			if(lengthit > 0){

				if (var=="brand"){
					brand = (argu.substr(startit, lengthit)).c_str();
					catFilteredFeatures[0] = 1;
					if (brand == "All Brands"){
						catFilteredFeatures[0] = 0;
					}
					// this will be changed once we have an array of brands
					brands[0] = brand;
		   			}		
		    	}
		   		else if(var == "price_min"){
				    filteredRange[0][0] = atof((argu.substr(startit, lengthit)).c_str()) * 100;
		        	conFilteredFeatures[0] = 1;
	    		}
		   		else if(var == "price_max"){
	  				filteredRange[0][1] = atof((argu.substr(startit, lengthit)).c_str()) ;	
					filteredRange[0][1] = filteredRange[0][1]* 100;
			    	conFilteredFeatures[0] = 1;
		    	}
		   		else if(var == "displaysize_min"){
				    filteredRange[1][0] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[1] = 1;
		    	}
		   		else if(var == "displaysize_max"){
			    	filteredRange[1][1] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[1] = 1;
		    	}
		   		else if(var == "opticalzoom_min"){
			    	filteredRange[2][0] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[2] = 1;
		    	}
		   		else if(var == "opticalzoom_max"){
				    filteredRange[2][1] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[2] = 1;
				}
		   		else if (var == "maximumresolution_min"){
					filteredRange[3][0] = atof((argu.substr(startit, lengthit)).c_str());
			   		conFilteredFeatures[3] = 1;
		    	}	
		   		else if (var == "maximumresolution_max"){
		     	    filteredRange[3][1] = atof((argu.substr(startit, lengthit)).c_str());
				   	conFilteredFeatures[3] = 1;		
				}
		   		 
	     	}
	  }
	}
}