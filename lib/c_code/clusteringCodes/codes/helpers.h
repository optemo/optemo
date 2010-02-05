
int find(int *idA, int value, int size){
		
	int ind = -1;
	for(int i=0; i<size; i++){
		if (idA[i] == value){
			ind = i;
			return ind;
		}
	}
	
	return ind;  
}

void shift1(int* reps, int* clusterIds, int* clusterCounts, int size){
	
	for (int i=0; i<size; i++){
		reps[i] = reps[i+1];
		clusterIds[i] = clusterIds[i+1];
		clusterCounts[i] = clusterCounts[i+1];
	} 
	
}

int find2(int *idA, int value, int size, int order){
		
	int ind = -1;
	int o = 0;
	for(int i=0; i<size; i++){
		if (idA[i] == value){
			o++;
			if (o == order){
				ind = i;
				return ind;
			}
		}
	}
	
	return ind;  
}

int find3(int *idA, int value, int size, int turn){
	
	int ind = -1;
	int r = 0;
	
	for(int i=0; i<size; i++){
		if (idA[i] == value){
			if(r==turn){
				ind = i;
				return ind;
			}
			else{ //r<turn
				r++;
			}	
		}
	}
	return ind;	
}

int findVec(vector<string> tokens, string value)
{
	int ind = -1;
	for (int i=0; i<(int)tokens.size(); i++){
		if (tokens.at(i) == value){
			ind = i;
			return ind;
		}
	}
	return ind;
}


void save2File (string filename, double **array1, int **array2, int *array3, string* array5, int *array4, int size, int F, int C, int R){
	ofstream myfile;
	int x, y;
	myfile.open(filename.c_str(), ios::out);
	
	myfile<<size;
	myfile<<" ";
    myfile<<F;
    myfile<<" ";
	myfile<<C;
	myfile<< " ";
	myfile<<R;
	myfile<<" ";
	for( y=0; y<F; y++){
		for ( x=0; x<size; x++){
			myfile<<array1[x][y];
			myfile<<" ";
		}
	}
	for(y=0; y<size; y++){
		for (x=0; x<C; x++){
			myfile<<array2[x][y];
			myfile<<" ";
		}
	}
	
	for(x = 0; x<size; x++){
		myfile<<array3[x];
		myfile<<" ";
	}
	
	for(x = 0; x<R; x++){
		myfile<<array4[x];
		myfile<<" ";
	}
	for(x = 0; x<size; x++){
		myfile<<array5[x];
		myfile<<" ";
	}
	myfile.close();
}

int* loadNumbers(string filename){
	ifstream myfile;
	myfile.open(filename.c_str(), ios::in);
	int *sizes = new int[4];
	myfile >> sizes[0];
	myfile >> sizes[1];
	myfile >> sizes[2];
	myfile >> sizes[3];
	myfile.close();
	return sizes;
} 


void loadFile(string filename, double **array1, int **array2, int *array3, string *array5, int *array4){
	ifstream myfile;
	myfile.open(filename.c_str(), ios::in);
	int x, y, size, F, C, R;
	myfile >> size;
	myfile >> F;
	myfile >> C;
	myfile >> R;
	for( y=0; y<F; y++){
		for ( x=0; x<size; x++){
			myfile>>array1[x][y];
		}
	}
	for(y=0; y<size; y++){
		for (x=0; x<C; x++){
			myfile>>array2[x][y];
		}
	}
	
	for(x = 0; x<size; x++){
		myfile>>array3[x];
	}
	
	for(x = 0; x<R; x++){
		myfile>>array4[x];
	}
	for(x = 0; x<size; x++){
		myfile>>array5[x];
	}
	myfile.close();
	
}

void getRange(double** data, int size, int conFeatureN, double** conFeatureRange){
		
	 
		for(int f=0; f<conFeatureN; f++){	
  	         conFeatureRange[f][1] = data[0][1]; 
             conFeatureRange[f][0] = data[0][1]; 
		}
        

/////
	
		for (int f=0; f<conFeatureN; f++){
      		for(int j = 1; j<size; j++){
					if(data[j][f] > conFeatureRange[f][1]){
                		conFeatureRange[f][1] = data[j][f];
	           		}
		       		if (data[j][f] < conFeatureRange[f][0]){
			   			conFeatureRange[f][0] = data[j][f];
		   			}
			}
		}
}

//	getStatisticsData(data, clusteredData, indicators, idA, s, clusterN, conFeatureN, conFeatureRangeC);
void getStatisticsData(double** data, int** clusteredData, int** indicators, int* idA, int size, int clusterN, int conFeatureN, double*** conFeatureRangeC){
		
			
	int ind = 0;
		
			
	for (int c=0; c<clusterN; c++){
		ind = find(idA, clusteredData[c][1], size);

		for(int f=0; f<conFeatureN; f++){
			
          conFeatureRangeC[c][f][1] = data[ind][f]; 

          conFeatureRangeC[c][f][0] = data[ind][f]; 
		}
    } 

/////
	for (int c=0; c<clusterN; c++){
		for (int f=0; f<conFeatureN; f++){
      		for(int j = 0; j<clusteredData[c][0]; j++){
	
				ind = find(idA, clusteredData[c][j+1], size);
				
				if(data[ind][f] > conFeatureRangeC[c][f][1]){
                	conFeatureRangeC[c][f][1] = data[ind][f];
           		}
	       		if (data[ind][f] < conFeatureRangeC[c][f][0]){
		   			conFeatureRangeC[c][f][0] = data[ind][f];
		   		}
			}
		 }
	}
   }     

/////
	
	
void getStatisticsData1(double** data, int** indicators, int size, int conFeatureN, int boolFeatureN, double** dataN){
			double *dif = new double[conFeatureN + boolFeatureN];
			double **conFeatureRange = new double* [conFeatureN];
		    for(int f=0; f<conFeatureN; f++){	
				conFeatureRange[f] = new double [2];	
	  	         conFeatureRange[f][1] = data[0][f]; 
	             conFeatureRange[f][0] = data[0][f]; 
			}


	/////

			for (int f=0; f<conFeatureN; f++){
	      		for(int j = 1; j<size; j++){
						if(data[j][f] > conFeatureRange[f][1]){
	                		conFeatureRange[f][1] = data[j][f];
		           		}
			       		if (data[j][f] < conFeatureRange[f][0]){
				   			conFeatureRange[f][0] = data[j][f];
			   			}
				}
			}


			for (int f=0; f<conFeatureN; f++){
				dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
			}
			for (int f=0; f<conFeatureN+boolFeatureN; f++){
			   for(int j=0; j<size; j++){
				if (dif[f] == 0){
					dataN[j][f] = 0;
				}
				else{
					
			    	dataN[j][f] = (data[j][f] - conFeatureRange[f][0])/ dif[f];
			   	}
		}  }
		
	}

	void getStatisticsData2(double** data, double* average, int size, int conFeatureN, int boolFeatureN, double** dataN){
		   for (int j=0; j<conFeatureN; j++){
			 if (size>0){
			 	average[j] = average[j]/size;
			  }else{
				average[j] = 0;
			  }	
		    }
				
		 	double *dif = new double[conFeatureN+boolFeatureN];
			double **conFeatureRange = new double* [conFeatureN];
			
			for(int f=0; f<conFeatureN; f++){	
				 conFeatureRange[f] = new double [2];	
	  	         conFeatureRange[f][1] = data[0][f]; 
	             conFeatureRange[f][0] = data[0][f]; 
			}

			for (int f=0; f<conFeatureN; f++){
	      		for(int j = 1; j<size; j++){
						if(data[j][f] > conFeatureRange[f][1]){
	                		conFeatureRange[f][1] = data[j][f];
		           		}
			       		if (data[j][f] < conFeatureRange[f][0]){
				   			conFeatureRange[f][0] = data[j][f];
			   			}
				}
			}

			for (int f=0; f<conFeatureN; f++){
				dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
			}
			for (int j=0; j<size; j++){
  				for (int f=0; f<conFeatureN; f++){
			   
					if (dif[f] == 0){
						dataN[j][f] = 0;
					}
					else{
			    		dataN[j][f] = (data[j][f] - conFeatureRange[f][0])/ dif[f];
			    	}
		       }
	    		for (int f=conFeatureN; f<conFeatureN+boolFeatureN; f++){
					dataN[j][f] = 	data[j][f];
			  }  
			}
	  	}

	void getStatisticsClusteredData(double** data, int** clusteredData, double* average, int* idA, int size, int clusterN, int conFeatureN, double*** conFeatureRange){
		int ind = 0;
			
		for (int j=0; j<conFeatureN; j++){
			average[j] = average[j]/size;
		}
		
	
			for (int c=0; c<clusterN; c++){
				ind = find(idA, clusteredData[c][1], size);
		
				for(int f=0; f<conFeatureN; f++){
					
	  	          conFeatureRange[c][f][1] = data[ind][f]; 
	
	              conFeatureRange[c][f][0] = data[ind][f]; 
				}
	        } 

	/////
			for (int c=0; c<clusterN; c++){
				for (int f=0; f<conFeatureN; f++){
		      		for(int j = 0; j<clusteredData[c][0]; j++){
			
						ind = find(idA, clusteredData[c][j+1], size);
						
						if(data[ind][f] > conFeatureRange[c][f][1]){
		                	conFeatureRange[c][f][1] = data[ind][f];
		           		}
			       		if (data[ind][f] < conFeatureRange[c][f][0]){
				   			conFeatureRange[c][f][0] = data[ind][f];
				   		}
					}
				 }
			}			
	  	}



	


	

void insertion_sort(double* xOri, int* ids, int length)
{
  int i, idKey;
 double key;	 
  double* x = new double [length];
  for (int j=0; j<length; j++){
     x[j] = xOri[j];
  }
  
  for(int j=1;j<length;j++)
  {
     key=x[j];
	 idKey = ids[j];	
     i=j-1;

     while(x[i]>=key && i>=0)
     {
         x[i+1]=x[i];
		 ids[i+1] = ids[i];	
         i--;
     }
     x[i+1] = key;
	ids[i+1] = idKey;
  }
delete x;

}


void sortT(double** dataT, int* idA, int** sortedA, int size, int conFeatureN){
	
	
	for (int f=0; f<conFeatureN; f++){
		for (int j=0; j<size; j++){
			sortedA[f][j] = idA[j];
		}
		
		insertion_sort(dataT[f], sortedA[f], size);
		
	}
}


void sort(double** data, int* idA, int** sortedA, int size, int conFeatureN){
	
	double** dataT = new double* [conFeatureN];
	
	for (int f=0; f<conFeatureN; f++){
	dataT[f] = new double [size];

		for (int j=0; j<size; j++){
			dataT[f][j] = data[j][f];
			sortedA[f][j] = idA[j];
		}
		
		insertion_sort(dataT[f], sortedA[f], size);
		
	}
}


void getIndicators(int* clusterIDs, int repW, int conFeatureN, double*** conFeatureRangeC, bool* conFilteredFeatures, int** indicators, sql::Statement *stmt,
 sql::ResultSet *res, int* mergedClusterIDs, string productName, string* conFeatureNames){

    string capProductName = productName;
	capProductName[0] = capProductName[0] - 32;
	string command;
	double** stat = new double* [conFeatureN];
	double** range = new double* [conFeatureN];
	for(int f=0; f<conFeatureN; f++){
		stat[f] = new double[2]; 
		range[f]= new double[2]; 
	}
	
	for (int f=1; f<conFeatureN; f++){
		command = "select low, high from db_features where name=\'";
		ostringstream fnameString;
		fnameString << conFeatureNames[f];
		command += fnameString.str();
		command += "\'";
		res = stmt->executeQuery(command);
		res->next();
		stat[f][0] = res->getDouble("low");
		stat[f][1] = res->getDouble("high");
	}	
	
	command = "select price_low, price_high from db_properties where name=\'";
	ostringstream cProductStream; 
	cProductStream <<capProductName;
	command += cProductStream.str();
	command += "\'";	
	res = stmt->executeQuery(command); 
	res->next();
	stat[0][0] = res->getDouble("price_low");
	stat[0][1] = res->getDouble("price_high");

	for (int i=0; i<repW; i++){
		command = "SELECT * from ";
		command += productName;
		command += "_clusters where (id=";
		if (clusterIDs[i]<0){ //merged clusters
			ostringstream mergedCId;
			mergedCId << mergedClusterIDs[0];
			command += mergedCId.str();
			for (int m=0; m<(-1*clusterIDs[i]); m++){
				command += " or id=";
				ostringstream mergedCId2;
				mergedCId2 << mergedClusterIDs[m];
				command += mergedCId2.str();
			}
			command += ")";
		}
		else{
	
			ostringstream cId;
			cId << clusterIDs[i];
			command += cId.str();
			command += ")";
		}	
		
		command += ";";
		res = stmt->executeQuery(command); 
	
		res->next();
		
		range[0][0] = res->getDouble("price_min");
		range[0][1] = res->getDouble("price_max");
		for (int f=1; f<conFeatureN; f++){
			res->next();
			command = conFeatureNames[f];
			command += "_min"; 
			range[f][0] = res->getDouble(command);
			command = conFeatureNames[f];
			command += "_max";
			range[f][1] = res->getDouble(command);
		}	
			

	
		for (int f=0; f<conFeatureN; f++){  //min
			
				if (range[f][1] <= stat[f][0]){
					indicators[f][i] = 1;
				}
				else if (range[f][0] >= stat[f][1]){ //max
				indicators[f][i] = 3;
				}
		
			else if ((range[f][0] >= stat[f][0]) && (range[f][1] <= stat[f][1])){ //average
				indicators[f][i] = 2;
			}	
		}
	}
}


void median(double** data, int size, int conFeatureN, int* sortedA){

	double* distan = new double[size];
	for (int j=0; j<size; j++){
	    distan[j] = 0;
		for (int i=0; i<size; i++){
			for (int f=0; f<conFeatureN; f++){
				distan[j] += (data[j][f] - data[i][f]) *  (data[j][f] - data[i][f]);
		   }
		}	
	}
	
	insertion_sort(distan, sortedA, size);
}



void weightedMedian(double** data, int size, int conFeatureN, int* sortedA, double* weights){

	double* distan = new double[size];
	for (int j=0; j<size; j++){
	    distan[j] = 0;
		for (int i=0; i<size; i++){
			for (int f=0; f<conFeatureN; f++){
				distan[j] += weights[f] * (data[j][f] - data[i][f]) *  (data[j][f] - data[i][f]);
		   }
		}	
	}
	insertion_sort(distan, sortedA, size);
}



void median2(double** data, int size, int conFeatureN, int* sortedA){

	double* distan = new double[size];
	for (int j=0; j<size; j++){
	    distan[j] = 0;
		for (int i=0; i<size; i++){
			for (int f=0; f<conFeatureN; f++){
				distan[j] += (data[f][j] - data[f][i]) *  (data[f][j] - data[f][i]);
		   }
		}	
	}
	
	insertion_sort(distan, sortedA, size);

}


void repOrder(double** dataCluster, int size, string mode, int conFeatureN, int boolFeatureN, int* order, double* weights){
	
	if (mode=="median"){
		weightedMedian(dataCluster, size, conFeatureN, order, weights);
	}

}


void utilityOrder(double** data, int* idA, int size, int** clusteredData, int** clusteredDataOrder, int** clusteredDataOrderU, int clusterN, int conFeatureN, 
				int boolFeatureN, string* conFeatureNames, string* boolFeatureNames, sql::Statement *stmt, string productName){
	//	// clusteredData, clusteredDataOrder, clusteredDataOrderU

	string capProductName = productName;
	double utility;
	double *avgUtilities = new double [clusterN];
	capProductName[0] = productName[0] - 32;
	string command;
	int* orderRec = new int [clusterN];

	for (int c=0; c<clusterN; c++){	
		utility = 0.0;
		orderRec[c] = c;
		for (int i=0; i<clusteredData[c][0]; i++){
				command = "SELECT ";
				command += conFeatureNames[0];
				for (int f=1; f<conFeatureN; f++){
					command += ", ";
					command += conFeatureNames[f]; 
				}	
				command += " from factors where (product_type= \'";
				command += capProductName;
				command += "\' and product_id=";
				ostringstream idStream; 
				idStream << clusteredData[c][i+1];
				command += idStream.str();
				command += ");";
				std::auto_ptr<sql::ResultSet> res2(stmt->executeQuery(command));
				if (res2->rowsCount()>0){
					res2->next();
					for (int f=0; f<conFeatureN; f++){
						utility += res2->getDouble(conFeatureNames[f]);
					}	
				}
		}
		avgUtilities[c] = utility/clusteredData[c][0];
	}		
	insertion_sort(avgUtilities, orderRec, clusterN);
	for (int c=0; c<clusterN; c++){
		clusteredDataOrderU[clusterN-c-1][0] = clusteredData[orderRec[c]][0];
		for (int i=0; i<clusteredData[orderRec[c]][0]; i++){
			clusteredDataOrderU[clusterN-c-1][i+1] = clusteredDataOrder[orderRec[c]][i];
		}	
	}
		
}		    
	
	
//#endif	/* _EXAMPLES_H */

