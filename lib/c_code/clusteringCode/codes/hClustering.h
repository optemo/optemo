
#include "kmeans.h"
#include "helpers.h"


int hClustering(int layer, int clusterN, int conFeatureN, int boolFeatureN, double *average, double** conFeatureRange, double*** conFeatureRangeC,
	sql::ResultSet *res, sql::ResultSet *res2, sql::ResultSet *resClus, sql::ResultSet *resNodes, sql::Statement *stmt, 
	string* conFeatureNames, string* boolFeatureNames, string productName, double* weights){				
	
int maxSize = -2;	
double **data;
double **dataN;
int *idA;
string *brands; 
int parent_id = 0;
int size, sized, cluster_id;
				
if 	(layer == 1){	
	
	     		sized = res->rowsCount();
				data= new double*[sized];
		    	for(int j=0; j<sized; j++){
						data[j] = new double[conFeatureN+boolFeatureN]; 
				}
				brands = new string [sized];
				idA = new int[sized];	
			
				size = 0;
				
				double listprice = 0.0;
				double saleprice = 0.0;
				double price = 0.0;
		
				
				while (res->next()) 
				{
		//		listprice =  res->getInt("listpriceint");
				saleprice = res->getInt("salepriceint");
		//	 if(saleprice > 0 ) {	
		//			price = min(listprice, saleprice);	
				    
		//		}
						
		//	else{
				price = saleprice;
				
		//	}	   		
			
							data[size][0] = price;
							for (int f=1; f<conFeatureN; f++){
								data[size][f] = res->getDouble(conFeatureNames[f]);
							}	
							for (int f=0; f<boolFeatureN; f++){
								data[size][conFeatureN+f] = res->getDouble(boolFeatureNames[f]);
							}
							
							//data[size][1] = res->getDouble(conFeatureNames[1]);
							//data[size][2] = res->getDouble(conFeatureNames[2]);
							//data[size][3] = res->getDouble(conFeatureNames[3]);
							idA[size] = res->getInt("id"); 
							brands[size] = res->getString("brand");
							for (int f=0; f<conFeatureN; f++){
							average[f] += data[size][f];
					}
					size++;	
											
				}
				
				  dataN = new double*[size];
			 	   	    for(int j=0; j<size; j++){
			 	   				dataN[j] = new double[conFeatureN]; 
			 	   		}

			 	   		int **indicators = new int* [conFeatureN];
			 	   		for (int j=0; j<conFeatureN; j++){
			 	   				indicators[j] = new int[size];
			 	   			}

			 	   		getStatisticsData1(data, indicators, average, size, conFeatureN, dataN);  

			// cluster
			 			int *centersA;
			 	   		double** dist;
			 	   		double distan;

			 	   		double** centroids = new double* [clusterN];
			 	   		for(int j=0; j<clusterN; j++){
			 	   	    	centroids[j]=new double[conFeatureN];
			 	   		}

			 	       	centersA = k_means3(dataN,size,conFeatureN, clusterN, DBL_MIN, centroids, weights); 
					
				
				dist = new double* [size];

						for(int j=0; j<size; j++){
					    	dist[j] = new double[clusterN]; 
						}

						for (int j=0; j<size; j++){
					    	  	for (int c=0; c<clusterN; c++){
					    		   	for (int f=0; f<conFeatureN; f++){
										 	distan = dist[j][c] + ((centroids[c][f] - dataN[j][f])*(centroids[c][f] - dataN[j][f]) );	 
					    				 	dist[j][c] = distan;	   
					    				}  
					   				}	 
					     }
	
		////////////////////////////////  Change clusteredData to vector 
					    int **clusteredData = new int* [clusterN];
						for (int j=0; j<clusterN; j++){
						 		clusteredData[j] = new int[size];	
						 	}
				   		for (int c=0; c<clusterN; c++){
						 		clusteredData[c][0] = 0;
						 	}

						int *ts = new int[clusterN];
						for(int j=0; j<clusterN; j++){
						 		ts[j] = 0;
						 	}
						for (int j=0; j<size; j++){
						 		ts[centersA[j]] = ts[centersA[j]]++;			
						 		clusteredData[centersA[j]][ts[centersA[j]]] = idA[j];
						 		clusteredData[centersA[j]][0]++;
						 	}

					   // save it to the database
						
					   getStatisticsClusteredData(data, clusteredData, indicators, average, idA, size, clusterN, conFeatureN, conFeatureRangeC);		

					   saveClusteredData(data, idA, size, brands, parent_id,clusteredData, conFeatureRangeC, layer, clusterN, conFeatureN, conFeatureNames, stmt, res2, productName);
					
						for (int c=0; c<clusterN; c++){
								if (clusteredData[c][0]>maxSize){
									maxSize = clusteredData[c][0];
								}
							}
					
					delete data;	
					delete clusteredData;
					delete dist;
				
			}
if (layer > 1){
	
	// getting all cluster ids in this layer
	string command = "SELECT * FROM ";
	command += productName;
	command += "_clusters WHERE layer=";
	ostringstream layerStream; 
	layerStream << layer - 1; 
	command += layerStream.str();
	command += " AND cluster_size>";
	ostringstream cluster_sizeStream;
	cluster_sizeStream<< (clusterN);
	command += cluster_sizeStream.str();
	command += ";";
	resClus = stmt->executeQuery(command); 
	
	
	while(resClus->next()){
	
		parent_id = resClus->getInt("id");
		command = "SELECT * FROM ";
		command += productName;
		command += "_nodes WHERE cluster_id=";
		ostringstream cidStream;
		ostringstream cluster_idStream;
		cluster_id = resClus->getInt("id");

		cluster_idStream<<cluster_id;
		command += cluster_idStream.str();
		command += ";";

		resNodes = stmt->executeQuery(command); 
		
		size = resNodes->rowsCount();
	
	
		if (size>clusterN){
	 
			data = new double*[size];
			idA = new int [size];
			brands = new string [size];
			for (int j=0; j<size; j++){
				data[j] = new double[conFeatureN+boolFeatureN];
			}

			int s = 0;
			while(resNodes->next()){
					
				data[s][0] = resNodes->getDouble("price");
				data[s][1] = resNodes->getDouble(conFeatureNames[1]);
				data[s][2] = resNodes->getDouble(conFeatureNames[2]);
					
				data[s][3] = resNodes->getDouble(conFeatureNames[3]);
				data[s][4] = resNodes->getDouble(conFeatureNames[4]);
				 
			//	for (int f=0; f<boolFeatureN; f++){
			//		cout<<"in loop "<<boolFeatureNames[f]<<endl;
			//		cout<<"resNodes->getDouble(boolFeatureNames[f]) is "<<resNodes->getDouble(boolFeatureNames[f])<<endl;
			//		data[s][f+conFeatureN] = resNodes->getDouble(boolFeatureNames[f]);
			//	}
				 cout<<"layer is "<<layer<<endl;
				idA[s] = resNodes->getInt("product_id"); 
			
				brands[s] = resNodes->getString("brand");

				for (int f=0; f<conFeatureN; f++){
				
     				average[f] += data[s][f];
			
		        }
		        s++;					
	        }
	     
       dataN = new double*[size];
 	   	    for(int j=0; j<size; j++){
 	   				dataN[j] = new double[conFeatureN]; 
 	   		}

 	   		int **indicators = new int* [conFeatureN];
 	   		for (int j=0; j<conFeatureN; j++){
 	   				indicators[j] = new int[size];
 	   			}


			getStatisticsData2(data, average, s, conFeatureN, dataN);
// cluster
 			int *centersA;
 	   		double** dist;
 	   		double** centroids = new double* [clusterN];
 	   		for(int j=0; j<clusterN; j++){
 	   	    	centroids[j]=new double[conFeatureN];
 	   		}
     	      
 	       	centersA = k_means3(dataN,size,conFeatureN, clusterN, DBL_MIN, centroids, weights); 
	        dist = new double* [size];
		
			for(int j=0; j<size; j++){
		    	dist[j] = new double[clusterN]; 
			}
		      		
									////////////////////////////////  Change clusteredData to vector 
		    int **clusteredData = new int* [clusterN];
			for (int j=0; j<clusterN; j++){
			 		clusteredData[j] = new int[size];	
			 	}
	   		for (int c=0; c<clusterN; c++){
			 		clusteredData[c][0] = 0;
			 	}
	 	
			int *ts = new int[clusterN];
			for(int j=0; j<clusterN; j++){
			 		ts[j] = 0;
			 	}
			for (int j=0; j<size; j++){
			 		ts[centersA[j]] = ts[centersA[j]]++;			
			 		clusteredData[centersA[j]][ts[centersA[j]]] = idA[j];
			 		clusteredData[centersA[j]][0]++;
			 	}
			
			//	 getStatisticsClusteredData(data, clusteredData, indicators, average, idA, size, clusterN, conFeatureN, conFeatureRangeC);		
			
 	   		getStatisticsData(data, clusteredData, indicators, idA, s, clusterN, conFeatureN, conFeatureRangeC);
		   saveClusteredData(data, idA, size, brands, parent_id,clusteredData, conFeatureRangeC, layer, clusterN, conFeatureN, conFeatureNames, stmt, res2, productName);

		
			for (int c=0; c<clusterN; c++){
					if (clusteredData[c][0]>maxSize){
						maxSize = clusteredData[c][0];
					}
				}
				
		delete data;	
		delete clusteredData;
		delete dist;
	
	}
	}	
}	

		return maxSize;

 }