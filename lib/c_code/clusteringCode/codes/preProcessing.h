//preProcessing.h
#include <map>


//make productNames a global variable

void preClustering(string* varNames, map<const string, int>productNames, string productName, string* conFeatureNames, string* catFeatureNames, string* indicatorNames){
	
	 string brand = "";
	string var;
	int ind, startit, endit, lengthit; 

	catFeatureNames[0]= "brand";
	conFeatureNames[0]= "price";
//	cout<<"productNames[productName] is "<<productNames[productName]<<endl;
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

		case 2:	
				conFeatureNames[1]= "ppm";  
			    conFeatureNames[2]= "itemwidth";
			    conFeatureNames[3]= "paperinput";
			
				indicatorNames[0]="price";
				indicatorNames[1]= "ppm";  
			    indicatorNames[2]= "itemwidth";
			    indicatorNames[3]= "paperinput";
			
				break;
		default: 
				break;
	}
	
	
}



// parseInput(productFeatures, productNames, productName, argu, brands, catFilteredFeatures, conFilteredFeatures, boolFilteredFeatures, filteredRange, 
//			varNamesN, conFeatureNames, catFeatureNames, indicatorNames);

void parseInput(string* varNames, map<const string, int>productNames, string productName, string argument, string* brands, bool* catFilteredFeatures, bool* conFilteredFeatures, 
	bool* boolFilteredFeatures, double** filteredRange, int varNamesN, string* conFeatureNames, string* catFeatureNames, string* indicatorNames){

	string brand = "";
	string var;
	int ind, startit, endit, lengthit; 
	
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
				
				
				for (int j=0; j<varNamesN; j++){
					var = varNames[j];
					ind = argument.find(var, 0);
					endit = argument.find("\n", ind);
					startit = ind + var.length() + 2;
					lengthit = endit - startit;
					if(lengthit > 0){

						if (var=="brand"){
							brand = (argument.substr(startit, lengthit)).c_str();
							catFilteredFeatures[0] = 1;
							if (brand == "All Brands"){
								catFilteredFeatures[0] = 0;
							}
							// this will be changed once we have an array of brands
							brands[0] = brand;
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
		
			
			indicatorNames[0] = "price";
			indicatorNames[1] = "ppm";
			indicatorNames[2] = "itemwidth";
			indicatorNames[3] = "paperinput";
			
			
			for (int j=0; j<varNamesN; j++){
				var = varNames[j];
				ind = argument.find(var, 0);
				endit = argument.find("\n", ind);
				startit = ind + var.length() + 2;
				lengthit = endit - startit;
				if(lengthit > 0){

					if (var=="brand"){
						brand = (argument.substr(startit, lengthit)).c_str();
						catFilteredFeatures[0] = 1;
						if (brand == "All Brands"){
							catFilteredFeatures[0] = 0;
						}
						// this will be changed once we have an array of brands
						brands[0] = brand;
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
					
		     	}
			}
		
				break;
		default: 
				break;
	}			
}
string generateOutput(string* indicatorNames, int conFeatureN, int productN, double** conFeatureRange, string* varNames, int repW, int* reps, bool reped, 
	int* clusterIDs, int* mergedClusterIDs, int* clusterCounts, int** indicators){

		string out = "--- !map:HashWithIndifferentAccess \n";
		out.append("result_count: ");
		ostringstream resultCountStream;
	
		resultCountStream << productN;
		out.append(resultCountStream.str());
		out.append("\n");
		conFeatureRange[0][0] = conFeatureRange[0][0] / 100;
		conFeatureRange[0][1] = conFeatureRange[0][1] / 100;
		for (int j=0; j<(conFeatureN*2); j++){
			out.append(varNames[j+3]);
			out.append(": ");
			if ((j%2) == 0){  // j is even for mins
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][0];
		     	out.append(oss.str());
			}
			else{
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][1];
		     	out.append(oss.str());
				}
			out.append("\n");
		}
		out.append("products: \n");
	    for(int c=0; c<repW; c++){
			    out.append("- ");
		        std::ostringstream oss; 		  
			 	oss<<reps[c];
				out.append(oss.str()); 
			 	out.append("\n");
		}
	if (reped){
		out.append("clusters: \n");
        for(int c=0; c<repW; c++){
			out.append("- ");
			if (clusterIDs[c] < 0 ) { //merged clusters
				ostringstream oss2; 
				oss2<<mergedClusterIDs[0];
				out.append(oss2.str());
				for (int m=1; m<(-1*clusterIDs[c]); m++){
					out.append("-");
					ostringstream oss3;
					oss3 << mergedClusterIDs[m];
					out.append(oss3.str());
				}
			} 
		    else{    
	           std::ostringstream oss; 		  
			   oss<<clusterIDs[c];
			   out.append(oss.str());
			} 
			   out.append("\n");
		} 
	
		out.append("chosen: \n");

		for(int c=0; c<repW; c++){		  
		     	out.append("- {");
		   		out.append("cluster_id: ");
		   		std::ostringstream oss2; 		  
		   		oss2<<clusterIDs[c];
		   		out.append(oss2.str());
		  		out.append(", ");
				out.append("cluster_count: ");
				std::ostringstream oss3; 		  
				oss3<<clusterCounts[c];
				out.append(oss3.str());

		   		for (int f=0; f<conFeatureN; f++){
					out.append(", ");
					out.append(indicatorNames[f]);
					out.append(": ");
					std::ostringstream oss; 
					oss<<indicators[f][c];
					out.append(oss.str());
				}
		   		out.append("}\n");
		}
	}	

	
return out;

}
