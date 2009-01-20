//#ifndef _EXAMPLES_H
//#define	_EXAMPLES_H
//
//// Portable __FUNCTION__
//#ifndef __FUNCTION__
// #ifdef __func__
//   #define __FUNCTION__ __func__
// #else
//   #define __FUNCTION__ "(function n/a)"
// #endif
//#endif
//
//#ifndef __LINE__
//  #define __LINE__ "(line number n/a)"
//#endif 

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

int findVec(vector<string> tokens, string value)
{
	int ind = -1;
	for (int i=0; i<tokens.size(); i++){
		if (tokens.at(i) == value){
			ind = i;
			return ind;
		}
	}
	return ind;
}

//save2File(fileName, data, clusteredData, centersA, brands, idA, sane, conFeatureN, clusterN, row)

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

//(fileName, dataN, clusteredData, centersA, idA, sane, featureN, clusterN, row);

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
void getStatisticsData(double** data, int** indicators, double* average, int size, int conFeatureN, double** conFeatureRange, double** dataN){
		
			
	   for (int j=0; j<conFeatureN; j++){
			average[j] = average[j]/size;
		}
		
				
	  	
	 	double *dif = new double[conFeatureN];
	
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
			
			
	//	for (c=0; c<clusterN; c++){
	//		for (int f=0; f<conFeatureN; f++){
	//			//	tresh = min(difMax, difMin) / 2;
	//			for (int j=0; j<size; j++){
	//			
	//				if (data[j][f] > (average[f] + tresh)){    // high 
	//		   		indicators[f][j] = 1;
	//		    }
	//		    else if(data[j][f] < (average[f] - tresh)){ // low
	//		   		indicators[f][j] = -1;
	//			}  
	//			else{  //average
//	//				indicators[f][j] = 0;
//	//			}
//	//		}		
//	//	}	
		for (int f=0; f<conFeatureN; f++){
			dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
		}
		for (int f=0; f<conFeatureN; f++){
		   for(int j=0; j<size; j++){
			if (dif[f] == 0){
				dataN[j][f] = 0;
			}
			else{
		    	dataN[j][f] = (((data[j][f] - conFeatureRange[f][0])/ dif[f]) * 2 ) - 1;
		   	}
	}  }
  	}



	void getStatisticsClusteredData(double** data, int** clusteredData, int** indicators, double* average, int* idA, int size, int clusterN, int conFeatureN, double*** conFeatureRange){


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
		
	//		for (c=0; c<clusterN; c++){
	//			for (int f=0; f<conFeatureN; f++){
	//				//	tresh = min(difMax, difMin) / 2;
	//				for (int j=0; j<clusteredData[c][0]; j++){
	//					ind = idA[clusteredData[c][j];
	//					if (data[ind][f] > (average[f] + tresh)){    // high 
	//			   		indicators[f][j] = 1;
	//			    }
	//			    else if(data[j][f] < (average[f] - tresh)){ // low
	//			   		indicators[f][j] = -1;
	//				}  
	//				else{  //average
	//					indicators[f][j] = 0;
	//				}
	//			}		
	//		}	
			
		
	  	}


void saveClusteredData(double ** data, int* idA, string* brands, int parent_id, int** clusteredData, double*** conFeatureRange, int layer, int clusterN, int conFeatureN, sql::Statement *stmt, sql::ResultSet *res2){
///Saving to DataBase	
	ostringstream layerStream; 
	layerStream<<layer;
    ostringstream parent_idStream;
	parent_idStream<<parent_id;
	int cluster_id;
	for (int c=0; c<clusterN; c++){
		ostringstream nodeStream;
		ostringstream cluster_idStream; 
		
		ostringstream clusterSizeStream;
		clusterSizeStream<<clusteredData[c][0];
		string command = "INSERT INTO clusters (layer, parent_id, cluster_size,price_min, price_max, displaysize_min,displaysize_max,  opticalzoom_min, opticalzoom_max, maximumresolution_min, maximumresolution_max ) values (";
		command += layerStream.str();
		command += ", ";
		command += parent_idStream.str();
		command += ", ";
		command += clusterSizeStream.str();
		for (int f=0; f<conFeatureN; f++){
			for (int r=0; r<2; r++){
				command += ", ";
				ostringstream rangeStream;
				rangeStream<<conFeatureRange[c][f][r];
				command += rangeStream.str();
			}
		}
		command +=");";
		
		stmt->execute(command);
	
		command = "SELECT last_insert_id();"; // from clusters;"
		res2 = stmt->executeQuery(command);
	
		if (res2->next()){
			cluster_id = res2->getInt("last_insert_id()");
		}
		
	////// saving in the nodes table
		for (int j=0; j<clusteredData[c][0]; j++){	  
			command = "INSERT INTO nodes (cluster_id, camera_id, price, displaysize, opticalzoom, maximumresolution, brand) values(";
			ostringstream cluster_idStream;
			cluster_idStream<<cluster_id;
			command += cluster_idStream.str();
			command += ", ";
			ostringstream idStream;
			idStream<<clusteredData[c][j+1];
			command +=  idStream.str();	
			for (int f=0; f<conFeatureN; f++){
				command +=", ";
				ostringstream featureStream;
			//	cout<<"j is "<<j<<" and idA[j] is "<<idA[j]<<"  and data[j][f] is  "<<data[j][f]<<endl;
				featureStream<<data[j][f];
				
				command += featureStream.str();
			}
	  
	        command +=", \"";
			ostringstream featureStream;
				
			featureStream<<brands[j];
			command += featureStream.str();   
			command +="\");"; 
			stmt->execute(command);
	 }
	
	}
	
	
	
	
}	

//#endif	/* _EXAMPLES_H */

