int parseInput(string* varNames, map<const string, int>productNames, string productName, string argument, 
				string* brands, bool* catFilteredFeatures, bool* conFilteredFeatures, 
	bool* boolFilteredFeatures, double** filteredRange, bool* boolFeatures, int varNamesN, string* conFeatureNames, 
	string* catFeatureNames, string* boolFeatureNames, string* indicatorNames, 	string** descStrings){

	int brandN =0;	
	string brandString;		
	string brand = "";
	string var;
	int ind, startit, endit, lengthit, indash; 
	
	catFeatureNames[0]= "brand";
	conFeatureNames[0]= "price";
	switch(productNames[productName]){
		case 1:
	
				conFeatureNames[1]= "displaysize";  
			    conFeatureNames[2]= "opticalzoom";
			    conFeatureNames[3]= "maximumresolution";
				varNames[0] = "session_id";
				varNames[1] = "cluster_id";
				varNames[2] = "brand";
				varNames[3] = "price_min";
				varNames[4] = "price_max";
				varNames[5] = "displaysize_min";
				varNames[6] = "displaysize_max";
				varNames[7] = "opticalzoom_min";
				varNames[8] = "opticalzoom_max";
				varNames[9] = "maximumresolution_min";
				varNames[10] = "maximumresolution_max";
				indicatorNames[0] = "Price";
				indicatorNames[1] = "Display Size";
				indicatorNames[2] = "Optical Zoom";
				indicatorNames[3] = "MegaPixels";
				
				descStrings[0][0] = "Cheap";
				descStrings[0][1] = "Expensive";
				descStrings[1][0] = "Small Screen";
				descStrings[1][1] = "Large Screen";
				descStrings[2][0] = "Low Zoom";
				descStrings[2][1] = "High Zoom";
				descStrings[3][0] = "Low Resolutiion";
				descStrings[3][1] = "High Resolution";
				
				
				
				
				
				
				
				for (int j=0; j<varNamesN; j++){
					var = varNames[j];
					ind = argument.find(var, 0);
					endit = argument.find("\n", ind);
					startit = ind + var.length() + 2;
					lengthit = endit - startit;
					if(lengthit > 0){
								if (var=="brand"){
									brandString = (argument.substr(startit, lengthit)).c_str();
									catFilteredFeatures[0] = 1;
									if (brandString == "All Brands"){
										catFilteredFeatures[0] = 0;
									}
									// this will be changed once we have an array of brands
									else{
											startit = 0;
											brandString += "\n";
										while(brandString != ""){
											indash = brandString.find("*", startit);
											if (indash ==-1) // this is the last brand	
											{	
												indash = brandString.find("\n", startit);
											}

											brands[brandN] = brandString.substr(startit, indash);
											brandN ++;
										
											brandString = brandString.substr(indash+1);
											startit = 0;
										}
									}
						   		}
				
				   		else if(var == "price_min"){
							filteredRange[0][0] = atof((argument.substr(startit, lengthit)).c_str()) * 100;
				        	conFilteredFeatures[0] = 1;
			    		}
				   		else if(var == "price_max"){
			  				filteredRange[0][1] = atof((argument.substr(startit, lengthit)).c_str()) ;	
							filteredRange[0][1] = filteredRange[0][1] * 100;
					    	conFilteredFeatures[0] = 1;
				    	}
				   		else if(var == "displaysize_min"){
						    filteredRange[1][0] = atof((argument.substr(startit, lengthit)).c_str());
						    conFilteredFeatures[1] = 1;
				    	}
				   		else if(var == "displaysize_max"){
					    	filteredRange[1][1] = atof((argument.substr(startit, lengthit)).c_str());
					    	conFilteredFeatures[1] = 1;
				    	}
				   		else if(var == "opticalzoom_min"){
					    	filteredRange[2][0] = atof((argument.substr(startit, lengthit)).c_str());
					    	conFilteredFeatures[2] = 1;
				    	}
				   		else if(var == "opticalzoom_max"){
						    filteredRange[2][1] = atof((argument.substr(startit, lengthit)).c_str());
						    conFilteredFeatures[2] = 1;
						}
				   		else if (var == "maximumresolution_min"){
							filteredRange[3][0] = atof((argument.substr(startit, lengthit)).c_str());
					   		conFilteredFeatures[3] = 1;
				    	}	
				   		else if (var == "maximumresolution_max"){
				     	    filteredRange[3][1] = atof((argument.substr(startit, lengthit)).c_str());
						   	conFilteredFeatures[3] = 1;		
						}
						
			     	}
				}
				break;
				
		case 2:
		
			conFeatureNames[1]= "ppm";  
		    conFeatureNames[2]= "itemwidth";
		    conFeatureNames[3]= "paperinput";
			conFeatureNames[4] = "resolutionarea";
			
			boolFeatureNames[0] = "scanner";
			boolFeatureNames[1] = "printserver";
				
		    varNames[0] = "session_id";
			varNames[1] = "cluster_id";
			varNames[2] = "brand";
			varNames[3] = "price_min";
			varNames[4] = "price_max";
			varNames[5] = "ppm_min";
			varNames[6] = "ppm_max";
			varNames[7] = "itemwidth_min";
			varNames[8] = "itemwidth_max";
			varNames[9] = "paperinput_min";
			varNames[10] = "paperinput_max";
			varNames[11] = "resolutionarea_min";
			varNames[12] = "resolutionarea_max";
			varNames[13] = "scanner";
			varNames[14] = "printserver";
		    
			
			indicatorNames[0] = "price";
			indicatorNames[1] = "ppm";
			indicatorNames[2] = "itemwidth";
			indicatorNames[3] = "paperinput";
			indicatorNames[4] = "resolutionarea";
			indicatorNames[5] = "scanner";
			indicatorNames[6] = "printserver";
		
		
			descStrings[0][0] = "Cheap";
			descStrings[0][1] = "Expensive";
			descStrings[1][0] = "Slow";
			descStrings[1][1] = "Fast";
			descStrings[2][0] = "Small";
			descStrings[2][1] = "Large";
			descStrings[3][0] = "Low Capacity";
			descStrings[3][1] = "High Capacity";
			descStrings[4][0] = "Low Resolution";
			descStrings[4][1] = "High Resolution";
			descStrings[5][0] = "No Print Server";
			descStrings[5][1] = "Print Server";
			descStrings[6][0] = "No Scanner";
			descStrings[6][1] ="Scanner";
			
			
			for (int j=0; j<varNamesN; j++){
				var = varNames[j];
				ind = argument.find(var, 0);
				endit = argument.find("\n", ind);
				startit = ind + var.length() + 2;
				lengthit = endit - startit;
			
				if(lengthit > 0){
							if (var=="brand"){
								brandString = (argument.substr(startit, lengthit)).c_str();
								catFilteredFeatures[0] = 1;
								if (brandString == "All Brands"){
									catFilteredFeatures[0] = 0;
								}
								// this will be changed once we have an array of brands
								else{
										startit = 0;
										brandString += "\n";
									while(brandString != ""){
										indash = brandString.find("*", startit);
										if (indash ==-1) // this is the last brand	
										{	
											indash = brandString.find("\n", startit);
										}
					
										brands[brandN] = brandString.substr(startit, indash);
										brandN++;
										brandString = brandString.substr(indash+1);
										startit = 0;
									}
								}
					   		}
	
			
			   		else if(var == "price_min"){
						filteredRange[0][0] = atof((argument.substr(startit, lengthit)).c_str()) * 100;
			        	conFilteredFeatures[0] = 1;
		    		}
			   		else if(var == "price_max"){
		  				filteredRange[0][1] = atof((argument.substr(startit, lengthit)).c_str()) ;	
						filteredRange[0][1] = filteredRange[0][1] * 100;
				    	conFilteredFeatures[0] = 1;
			    	}
			   		else if(var == "ppm_min"){
					    filteredRange[1][0] = atof((argument.substr(startit, lengthit)).c_str());
					    conFilteredFeatures[1] = 1;
			    	}
			   		else if(var == "ppm_max"){
				    	filteredRange[1][1] = atof((argument.substr(startit, lengthit)).c_str());
				    	conFilteredFeatures[1] = 1;
			    	}
			   		else if(var == "itemwidth_min"){
				    	filteredRange[2][0] = atof((argument.substr(startit, lengthit)).c_str());
				    	conFilteredFeatures[2] = 1;
			    	}
			   		else if(var == "itemwidth_max"){
					    filteredRange[2][1] = atof((argument.substr(startit, lengthit)).c_str());
					    conFilteredFeatures[2] = 1;
					}
			   		else if (var == "paperinput_min"){
						filteredRange[3][0] = atof((argument.substr(startit, lengthit)).c_str());
				   		conFilteredFeatures[3] = 1;
			    	}	
			   		else if (var == "paperinput_max"){
			     	    filteredRange[3][1] = atof((argument.substr(startit, lengthit)).c_str());
					   	conFilteredFeatures[3] = 1;		
					}
					else if (var == "resolutionarea_min"){
				     	filteredRange[4][0] = atof((argument.substr(startit, lengthit)).c_str());
						conFilteredFeatures[4] = 1;		
					}
					else if (var == "resolutionarea_max"){
				     	filteredRange[4][1] = atof((argument.substr(startit, lengthit)).c_str());
						conFilteredFeatures[4] = 1;		
					}
					else if (var == "scanner"){
				
						boolFilteredFeatures[0] = 1;
						boolFeatures[0] = atof((argument.substr(startit, lengthit)).c_str());
						
					}
					else if (var == "printserver"){
						boolFilteredFeatures[1] =1;
						boolFeatures[1] = atof((argument.substr(startit, lengthit)).c_str());
					}
		     	}
			}
		
				break;
		default: 
				break;
	}	
	return brandN;		
}