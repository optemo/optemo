void saveClusteredData(double ** data, int* idA, int size, string* brands, int parent_id, int** clusteredDataOrderU, double*** conFeatureRange, 
int layer, 
int clusterN, int conFeatureN, int boolFeatureN, string* conFeatureNames, string* boolFeatureNames,  sql::Statement *stmt, string productName, int version, string region){

///Saving to cluster table 	
	ostringstream layerStream; 
	layerStream<<layer;
    ostringstream parent_idStream;
	parent_idStream<<parent_id;
	int cluster_id;
	string command2;
	ostringstream vs; 
	vs<< version;	

	
	for (int c=0; c<clusterN; c++){

		ostringstream nodeStream;
		ostringstream cluster_idStream; 
		ostringstream clusterSizeStream;
		clusterSizeStream<<clusteredDataOrderU[c][0];
		string command = "INSERT INTO clusters (version, layer, product_type, parent_id ";
	

		command += ") values (";
		command += vs.str();
		command += ", ";

		command += layerStream.str();
		command += ", \'";
		command += productName;
		command += "_";
		command += region;
		command += "\', ";
		command += parent_idStream.str();

						
		command +=");";
		stmt->execute(command);
	
		command = "SELECT last_insert_id();"; // from clusters;"

	  	std::auto_ptr<sql::ResultSet> res3(stmt->executeQuery(command));

		if (res3->next()){
			cluster_id = res3->getInt("last_insert_id()");
		}
		cluster_idStream<<cluster_id;
	
	////// saving in the nodes table
		for (int j=0; j<clusteredDataOrderU[c][0]; j++){	
		
			command = "INSERT INTO nodes (version, cluster_id, product_type, product_id) values(";
			//add rep

			command += vs.str();
			command += ", ";
			

			
			command += cluster_idStream.str();
			command += ", \'";
			
			command += productName;
			command += "_";
			command += region;
			command += "\', ";
			
			
			ostringstream idStream;
			
			idStream<<clusteredDataOrderU[c][j+1];
			command +=  idStream.str();
			
	// 	//utility
	// 	command2 = "SELECT ";
	// 	command2 += conFeatureNames[0];
	// 
	// 	for (int f=1; f<conFeatureN; f++){
	// 		command2 += ", ";
	// 		command2 += conFeatureNames[f]; 
	// 	}	
	// 	command2 += " from factors where (product_type= \'";
	// 	
	// 	command2 += capProductName;
	// 	command2 += "\' and product_id=";
	// 	command2 += idStream.str();
	// 	command2 += ");";
	// 
	//     std::auto_ptr<sql::ResultSet> res4(stmt->executeQuery(command2));
	// 	
	// 	utility = 0.0;
	// 	if (res4->rowsCount()>0){
	// 		res4->next();
	// 		for (int f=0; f<conFeatureN; f++){
	// 			utility += res4->getDouble(conFeatureNames[f]);
	// 		}	
	// 	}
			
	
			command +=");"; 
			stmt->execute(command);
			
	 }
	
	//average_utility = average_utility / clusteredDataOrderU[c][0];
	
	
	}

}	

void readData(double* dataPoint, string* brands, int s, int prodId, sql::ResultSet *res, sql::Statement *stmt, string* conFeatureNames, int conFeatureN, string* boolFeatureNames, int boolFeatureN, 
				string* catFeatureNames, int catFeatureN){
					
						string command;
						ostringstream pIdStream ; 
						pIdStream << prodId;

						for (int f=0; f<conFeatureN; f++){
							command = "SELECT * from cont_specs where product_id=";
							command += pIdStream.str();
							command += " AND name=\'";
							command += conFeatureNames[f];
							command += "\';";
							res = stmt->executeQuery(command);
							res->next();
							dataPoint[f] = res->getDouble("value");
						}

						for (int f=0; f<boolFeatureN; f++){
								command = "SELECT * from bin_specs where product_id=";
								command += pIdStream.str();
								command += " AND name=\'";
								command += boolFeatureNames[f];
								command += "\';";
								res = stmt->executeQuery(command);
								res->next();
								dataPoint[f+conFeatureN] = res->getDouble("value");
						}
					//	for (int f=0; f<catFeatureN; f++){
								command = "SELECT * from cat_specs where product_id=";
								command += pIdStream.str();
								command += " AND name=\'";
								command += catFeatureNames[0];
								command += "\';";
								res = stmt->executeQuery(command);
								res->next();
								brands[s] = res->getDouble("value");
					//	}
		}				
