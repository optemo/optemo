
#include "kmeans.h"
#include "helpers.h"


int hClustering(int layer, int clusterN, int conFeatureN, double *average, double** conFeatureRange, double*** conFeatureRangeC,
	sql::ResultSet *res, sql::ResultSet *res2, sql::ResultSet *resClus, sql::ResultSet *resNodes, sql::Statement *stmt){				
	
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
						data[j] = new double[conFeatureN]; 
				}
				brands = new string [sized];
				idA = new int[sized];	
			
				size = 0;
				
				double listprice = 0.0;
				double saleprice = 0.0;
				double price = 0.0;
			
				
				while (res->next()) 
				{
				
				 listprice =  res->getDouble("listpriceint");
				 if(res->getDouble("salepriceint")!=NULL ) {	
					
				    saleprice = res->getDouble("salepriceint");
				}
						
				   			price = min(listprice, saleprice);
							data[size][0] = price;
						    data[size][1] = res->getDouble("displaysize");
							data[size][2] = res->getDouble("opticalzoom");
							data[size][3] = res->getDouble("maximumresolution");
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

			 	   		getStatisticsData(data, indicators, average, size, conFeatureN, conFeatureRange, dataN);  

			// cluster
			 			int *centersA;
			 	   		double** dist;
			 	   		double distan;

			 	   		double** centroids = new double* [clusterN];
			 	   		for(int j=0; j<clusterN; j++){
			 	   	    	centroids[j]=new double[conFeatureN];
			 	   		}

			 	       	centersA = k_means(dataN,size,conFeatureN, clusterN, 1e-4, centroids); 

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

					//}		
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
					
				//	   getStatisticsClusteredData(data, clusteredData, indicators, average, idA, size, clusterN, conFeatureN, conFeatureRangeC);		
				   	   saveClusteredData(data, idA, size, brands, parent_id,clusteredData, conFeatureRangeC, layer, clusterN, conFeatureN, stmt, res2);
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
//cout<<"HERE BEG"<<endl;
	// getting all cluster ids in this layer
	string command = "SELECT * FROM clusters WHERE layer=";
	ostringstream layerStream; 
	layerStream << layer - 1; 
	command += layerStream.str();
	command += " AND cluster_size>";
	ostringstream cluster_sizeStream;
	cluster_sizeStream<< (clusterN * 4);
	command += cluster_sizeStream.str();
	command += ";";
	resClus = stmt->executeQuery(command); 

	
	while(resClus->next()){
	
		parent_id = resClus->getInt("id");
		command = "SELECT * FROM nodes WHERE cluster_id=";
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
				data[j] = new double[conFeatureN];
			}
			
			
			int s = 0;
		
			while(resNodes->next()){
					
				data[s][0] = resNodes->getDouble("price");
				data[s][1] = resNodes->getDouble("displaysize");
				data[s][2] = resNodes->getDouble("opticalzoom");
					
				data[s][3] = resNodes->getDouble("maximumresolution");
				
				idA[s] = resNodes->getInt("camera_id"); 
			
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
 	   		getStatisticsData(data, indicators, average, size, conFeatureN, conFeatureRange, dataN);  
		
// cluster
 			int *centersA;
 	   		double** dist;
 	   		double distan;
 	
 	   		double** centroids = new double* [clusterN];
 	   		for(int j=0; j<clusterN; j++){
 	   	    	centroids[j]=new double[conFeatureN];
 	   		}
     	      
 	       	centersA = k_means(dataN,size,conFeatureN, clusterN, 1e-10, centroids); 
	
		
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
					
		//}		
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
		
			
	//			for (int c=0; c<clusterN; c++){
	//				if (clusteredData[c][0] == 0){
	//					cout<<"cluster : "<<c<<" and layer is  "<<layer<<endl;
	//					}								
	//			}
	//				
		   // save it to the database
		 //  getStatisticsClusteredData(data, clusteredData, indicators, average, idA, size, clusterN, conFeatureN, conFeatureRangeC);	
	   	   //cout<<"THERE"<<endl;
		   saveClusteredData(data, idA, size, brands, parent_id,clusteredData, conFeatureRangeC, layer, clusterN, conFeatureN, stmt, res2);

		
			for (int c=0; c<clusterN; c++){
					if (clusteredData[c][0]>maxSize){
						maxSize = clusteredData[c][0];
					}
				}
				
					//cout<<"HERE ED"<<endl;
		delete data;	
		delete clusteredData;
		delete dist;
	
	}
	}	
}	

		return maxSize;

 }