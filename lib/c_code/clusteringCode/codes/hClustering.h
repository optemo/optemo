
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

//leafClustering(layer, conFeatureN, res, stmt, productName);

void leafClustering(int layer, int conFeatureN, int clusterN, string* conFeatureNames, sql::ResultSet *res, sql::ResultSet *res2, sql::ResultSet *res3, sql::Statement *stmt, string productName){
	
	string command;
	int cluster_id;
//	for (int l=1; l<layer; l++){
	   
		command = "SELECT id, layer from ";
		command += productName;
		command += "_clusters where (cluster_size<";
		ostringstream sizeStream;
		sizeStream << clusterN+1;
		command += sizeStream.str();
		command += ");";
	
		res = stmt->executeQuery(command);
		while(res->next()){
			ostringstream parent_idStream;
			parent_idStream << res->getInt("id");
			ostringstream clusterSizeStream;
			clusterSizeStream <<1;
			command = "select * from ";
			command += productName;
			command += "_nodes where cluster_id=";
			command += parent_idStream.str();
			command += ";";
			
			res2 = stmt->executeQuery(command);
					
			command = "INSERT INTO ";
			command += productName;
			command += "_clusters (layer, parent_id, cluster_size,price_min, price";
				for (int i=1; i<conFeatureN; i++){
					command += "_max, ";
					command += conFeatureNames[i];
					command += "_min, ";
					command += conFeatureNames[i];
				}
				
				command += "_max) values (";
				ostringstream layerStream;
				layerStream << layer;
				command += layerStream.str();
				command += ", ";
			
				command += parent_idStream.str();
				command += ", ";
				command += clusterSizeStream.str();
				
				for (int f=0; f<conFeatureN; f++){
						command += ", ";
						res2->next();
						double feaVal = res2->getDouble(conFeatureNames[f]);
						ostringstream feavalStream;
						feavalStream << feaVal;
						command += feavalStream.str();
						command += ", ";
						command += feavalStream.str();
				}
			
				command +=");";
				
				stmt->execute(command);
			
				command = "SELECT last_insert_id();"; // from clusters;"
				res3 = stmt->executeQuery(command);

				if (res3->next()){
					cluster_id = res3->getInt("last_insert_id()");
				}
			command = "INSERT INTO ";
			command += productName;
			command += "_nodes (cluster_id, product_id";
			for (int i=0; i<conFeatureN; i++){
				command += ", ";
				command += conFeatureNames[i];
			}
			command += ", brand) values (";
			ostringstream cidStream2; 
			cidStream2<< cluster_id;
			command += cidStream2.str();
			command += ", ";
			ostringstream pIdStream;
			pIdStream << res2->getInt("product_id");
			command += pIdStream.str();
			for (int f=0; f<conFeatureN; f++){
				command += ", ";
				ostringstream feaVStream;
				feaVStream << res2->getDouble(conFeatureNames[f]);
				command += feaVStream.str();
				
			}
			command += ", ";
			command += res2->getString("brand");
			command += ");"; 
		}
		
		// insert in node tables
		
		
	
			
	
}