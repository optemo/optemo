string generateOutput(string* indicatorNames, string* conFeatureNames, int conFeatureN, int productN, double** conFeatureRange, string* varNames, int repW, int* reps, bool reped, 
	int* clusterIDs, int** childrenIDs, int* childrenCount, int* mergedClusterIDs, int* clusterCounts, int** indicators, double** bucketCount, int bucketDiv, string** descStrings){

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
		
		for (int f=0; f<conFeatureN; f++){
			out.append(conFeatureNames[f]);
			out.append("_hist: \'");
			ostringstream countStream;
			countStream << round((bucketCount[f][0]/productN)*100)/100;
			out.append(countStream.str());
			for (int t=1; t<bucketDiv; t++){
				ostringstream countStream2;
				countStream2 << round((bucketCount[f][t]/productN)*100)/100;
				out.append(",");
				out.append(countStream2.str());	
			}
			out.append("\'\n");
		}
			
//	if (reped){
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
	
		out.append("clusterdetails: \n");

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
				out.append(", ");

				out.append("childrenCount: ");
				std::ostringstream oss5; 
				oss5 << childrenCount[c];
				out.append(oss5.str());
				if (childrenCount[c] >0){
					out.append(", ");
					out.append("children: [");
						ostringstream oss4; 
						oss4<<childrenIDs[c][0];
						out.append(oss4.str());
					
					for (int l=1; l<childrenCount[c]; l++){
						out.append(", ");
						ostringstream oss7; 
						oss7<<childrenIDs[c][l];
						//cout<<"children ID is "<<childrenIDs[c][l]<<endl;
						out.append(oss7.str());
					}
					out.append("]");
				}	
			
		   		for (int f=0; f<conFeatureN; f++){
					out.append(", ");
					out.append(indicatorNames[f]);
					out.append(": ");
					std::ostringstream oss; 
					oss<<indicators[f][c];
					out.append(oss.str());
				}
	
				out.append(", descString: \'");
				bool oneIndicator = 0;
				if (indicators[0][c] == 1) { //min
					out.append(descStrings[0][0]);
					oneIndicator = 1;
				}else if(indicators[0][c] == 3)//max
				{
					out.append(descStrings[0][1]);
					oneIndicator = 1;
				}
				
				for(int f=1; f<conFeatureN; f++){
					
					if (indicators[f][c] == 1) { //min
						if (oneIndicator){	
							out.append(", ");
						}	
						out.append(descStrings[f][0]);
						oneIndicator = 1;
					}else if(indicators[f][c] == 3)//max
					{
						if (oneIndicator){
							out.append(", ");
						}	
						out.append(descStrings[f][1]);
						oneIndicator = 1;
					}			
				}
				out.append("\'");
				
			
		   		out.append("}\n");
		}
//	}	
	

		
	
		

	
return out;

}
