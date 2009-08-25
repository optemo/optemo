	void saveClusteredData(double ** data, int* idA, int size, string* brands, int parent_id, int** clusteredData, int** clusteredDataOrdered, double*** conFeatureRange, 
    int layer, 
	int clusterN, int conFeatureN, int boolFeatureN, string* conFeatureNames, string* boolFeatureNames, sql::Statement *stmt, sql::ResultSet *res2, string productName, int version, string region){
	///Saving to cluster table 	
		ostringstream layerStream; 
		layerStream<<layer;
	    ostringstream parent_idStream;
		parent_idStream<<parent_id;
		int cluster_id;
		string command2;
		ostringstream vs; 
		vs<< version;	
		double utility, average_utility;	
		
		string capProductName = productName;
		capProductName[0] = productName[0] - 32;
		int i=0;
		
		for (int c=0; c<clusterN; c++){
			average_utility = 0.0;
			ostringstream nodeStream;
			ostringstream cluster_idStream; 
			ostringstream clusterSizeStream;
			clusterSizeStream<<clusteredData[c][0];
			string command = "INSERT INTO ";
			command += productName;
			command += "_clusters (version, region, layer, parent_id, cluster_size, price_min, price";
			for (int f=1; f<conFeatureN; f++){
				command += "_max, ";
				command += conFeatureNames[f];
				command += "_min, ";
				command += conFeatureNames[f];
			}
			
			command += "_max, brand"; 
			for (int f=0; f<boolFeatureN; f++){
				command += ", ";
				command += boolFeatureNames[f];
			}
			command += ") values (";
			command += vs.str();
			command += ", '";
			command += region;
			command += "', ";
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
		
		///Cluster Brands
			command2 = "SELECT DISTINCT brand from ";
			command2 += productName;
			command2 += "s where (id=";
			ostringstream pidstrm;
			pidstrm << clusteredDataOrdered[c][0];
			command2 += pidstrm.str();
			for (int i=1; i<clusteredData[c][0]; i++){
				command2 += " OR id = ";
				ostringstream pidstrm2;
				pidstrm2 << clusteredDataOrdered[c][i];	
				command2 += pidstrm2.str();
			}		
			command2 += ");";
		
			res2 = stmt->executeQuery(command2);
	
			command += ", \'";
			res2->next();
			command += res2->getString("brand");
			
			while(res2->next()){
			
				command += "*";
				command += res2 ->getString("brand");
			}
			command += "\' ";
			
		///Bool Features	
			for (int f=0; f<boolFeatureN; f++){
				command2 = "SELECT DISTINCT ";
				command2 += boolFeatureNames[f];
				command2 += " FROM ";
				command2 += productName;
				command2 += "s WHERE ((";
				command2 += boolFeatureNames[f];
				command2 += " IS NOT NULL) AND (id=";
				ostringstream pidstr;
				pidstr << clusteredDataOrdered[c][0];
				command2 += pidstr.str();
				for (int i=1; i<clusteredData[c][0]; i++){
					command2 += " OR id = ";
					ostringstream pidstr2;
					pidstr2 << clusteredDataOrdered[c][i];
					command2 += pidstr2.str();	
				}		
				command2 += "));";
		
				res2 = stmt->executeQuery(command2);
		
				if (res2->rowsCount()==1){ //it is only one value
					command += ", ";
					res2->next();
					ostringstream bb;
					bb <<res2->getBoolean(boolFeatureNames[f]);
					command += bb.str();
				}
				else{
					command += ", NULL";
				}
			}	
			command +=");";
		
			stmt->execute(command);
	

			command = "SELECT last_insert_id();"; // from clusters;"
			res2 = stmt->executeQuery(command);

			if (res2->next()){
				cluster_id = res2->getInt("last_insert_id()");
			}
			
			cluster_idStream<<cluster_id;

		////// saving in the nodes table
			for (int j=0; j<clusteredData[c][0]; j++){	
			
				command = "INSERT INTO ";
				command += productName;
				command += "_nodes (version, region, cluster_id, product_id, utility, price";
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

				command += vs.str();
				command += ", '";
				
				command += region;
				command += "', ";
				
				command += cluster_idStream.str();
				command += ", ";
				ostringstream idStream;
				idStream<<clusteredDataOrdered[c][j];
				command +=  idStream.str();
				command += ", ";
				
				//utility
				command2 = "SELECT ";
				command2 += conFeatureNames[0];
			
				for (int f=1; f<conFeatureN; f++){
					command2 += ", ";
					command2 += conFeatureNames[f]; 
				}	
				command2 += " from factors where (product_type= \'";
				
				command2 += capProductName;
				command2 += "\' and product_id=";
				command2 += idStream.str();
				command2 += ");";
			
				res2 = stmt->executeQuery(command2);
				utility = 0.0;
				if (res2->rowsCount()>0){
					res2->next();
					for (int f=0; f<conFeatureN; f++){
						utility += res2->getDouble(conFeatureNames[f]);
					}	
				}
				average_utility += utility;
				
				ostringstream ustr; 
				ustr << utility;
				command +=  ustr.str();
				for (int f=0; f<conFeatureN; f++){
					command +=", ";
					ostringstream featureStream;
					if ((f==0) && (data[find(idA, clusteredDataOrdered[c][j], size)][f]==0)){
						cout<<" id is "<< clusteredDataOrdered[c][j]<<endl;
					}
					featureStream<<data[find(idA, clusteredDataOrdered[c][j], size)][f];
					command += featureStream.str();
				}
				
				for (int f=0; f<boolFeatureN; f++){
				   command +=", ";
				   ostringstream featureStream;
				   featureStream<<data[find(idA, clusteredDataOrdered[c][j], size)][conFeatureN+f];
				   command += featureStream.str();
	
				}
		        command +=", \"";
				ostringstream featureStream;

				featureStream<<brands[find(idA, clusteredDataOrdered[c][j], size)];
				command += featureStream.str();   
				command +="\");"; 
				stmt->execute(command);
		 }
		average_utility = average_utility / clusteredData[c][0];
		command = "UPDATE ";
		command += productName;
		command += "_clusters SET cached_utility=";
		ostringstream auStr;
		auStr << average_utility;
		command += auStr.str();
		command += " where id=";
		command += cluster_idStream.str();
		command += ";";
		stmt->execute(command);
		}

	}	
