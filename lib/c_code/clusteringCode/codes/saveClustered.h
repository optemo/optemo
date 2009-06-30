	void saveClusteredData(double ** data, int* idA, int size, string* brands, int parent_id, int** clusteredData, int** clusteredDataOrdered, double*** conFeatureRange, int layer, 
	int clusterN, int conFeatureN, int boolFeatureN, string* conFeatureNames, string* boolFeatureNames, sql::Statement *stmt, sql::ResultSet *res2, string productName){
	///Saving to cluster table 	
		ostringstream layerStream; 
		layerStream<<layer;
	    ostringstream parent_idStream;
		parent_idStream<<parent_id;
		int cluster_id;
		string command2;
		int* repOrder;	
				
		for (int c=0; c<clusterN; c++){
		
			ostringstream nodeStream;
			ostringstream cluster_idStream; 
			ostringstream clusterSizeStream;
			clusterSizeStream<<clusteredData[c][0];
			string command = "INSERT INTO ";
			command += productName;
			command += "_clusters (layer, parent_id, cluster_size,price_min, price";
			for (int i=1; i<conFeatureN; i++){
				command += "_max, ";
				command += conFeatureNames[i];
				command += "_min, ";
				command += conFeatureNames[i];
			}
			
			command += "_max) values (";
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
				command = "INSERT INTO ";
				command += productName;
				command += "_nodes (cluster_id, product_id, price";
				for (int i=1; i<conFeatureN; i++){
						command += ", ";
						command += conFeatureNames[i];
				}
				for (int i=0; i<boolFeatureN; i++){
						command += ", ";
						command += boolFeatureNames[i];
				}
				command += ", brand) values(";
				//add rep

				ostringstream cluster_idStream;
				cluster_idStream<<cluster_id;
				command += cluster_idStream.str();
				command += ", ";
				ostringstream idStream;
				idStream<<clusteredDataOrdered[c][j];
				command +=  idStream.str();	
				for (int f=0; f<conFeatureN; f++){
					command +=", ";
					ostringstream featureStream;
					featureStream<<data[find(idA, clusteredDataOrdered[c][j], size)][f];

					command += featureStream.str();
				}
				
				for (int f=0; f<boolFeatureN; f++){
					command +=", ";
					ostringstream featureStream;
					command2 = "Select ";
					command2 += boolFeatureNames[f];
					command2 += " from ";
					command2 += productName;
					command2 += "s where id=";
					ostringstream idS;
					idS << idA[j];
					command2 += idS.str();
					command2 += ";";
					
					res2 = stmt->executeQuery(command2);
					
					res2->next();   
					featureStream<<res2->getInt(boolFeatureNames[f]);
					
					command += featureStream.str();
				}
		        command +=", \"";
				ostringstream featureStream;

				featureStream<<brands[find(idA, clusteredDataOrdered[c][j], size)];
				command += featureStream.str();   
				command +="\");"; 
		
				stmt->execute(command);
			
		 }
		}

	}	
