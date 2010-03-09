//leafClustering(layer, conFeatureN, res, stmt, productName);

void leafClustering(int conFeatureN, int boolFeatureN, int clusterN, string* conFeatureNames, string* boolFeatureNames, 
					sql::ResultSet *res, sql::ResultSet *res2, sql::ResultSet *res3, sql::Statement *stmt, string productName, int version, string region){
	
	string command, command2;
	string capProductName = productName;
	capProductName[0] = capProductName[0] - 32;
	
	int cluster_id;
	int layer;
	double utility;
//	for (int l=1; l<layer; l++){
	   
		command = "SELECT id, layer from ";
		command += productName;
		command += "_clusters where (version=";
		ostringstream vstream;
		vstream << version;
		command += vstream.str();
		command += " AND region='";
		command += region;
		
		command += "' AND cluster_size<";
		ostringstream sizeStream;
		sizeStream << clusterN+1;
		command += sizeStream.str();
		command += ");";
		
		res = stmt->executeQuery(command);
	
		while(res->next()){
			ostringstream parent_idStream;
			int pid =  res->getInt("id");
			layer = res->getInt("layer");
			parent_idStream << pid;
			ostringstream clusterSizeStream;
			clusterSizeStream <<1;
			command = "select * from ";
			command += productName;
			command += "_nodes where (version=";
			ostringstream vs;
			vs << version;
			command += vs.str();
			command += " AND region='";
			command += region;
			command += "' AND cluster_id=";
			command += parent_idStream.str();
			command += ");";
		
			res2 = stmt->executeQuery(command);
		
		    while(res2->next()){			
			command = "INSERT INTO ";
			command += productName;
			command += "_clusters (version, region, layer, parent_id, cluster_size,cached_utility, price_min, price";
				for (int i=1; i<conFeatureN; i++){
					command += "_max, ";
					command += conFeatureNames[i];
					command += "_min, ";
					command += conFeatureNames[i];
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
				ostringstream layerStream;
				layerStream << layer+1;
				command += layerStream.str();
				command += ", ";
			
				command += parent_idStream.str();
				command += ", ";
				command += clusterSizeStream.str();
				
				
				ostringstream auStr; 
				auStr << res2->getDouble("utility");
				command += ", ";
				command += auStr.str();
				
				for (int f=0; f<conFeatureN; f++){
						command += ", ";
						double feaVal = res2->getDouble(conFeatureNames[f]);
						ostringstream feavalStream;
						feavalStream << feaVal;
						command += feavalStream.str();
						command += ", ";
						command += feavalStream.str();
				}
				
				command += ", \'";
				command += res2->getString("brand");
				command += "\'";
				
				for (int f=0; f<boolFeatureN; f++){
		    			command += ", ";
		    			ostringstream feavalStream;
		    			feavalStream << res2->getBoolean(boolFeatureNames[f]);
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
			command += "_nodes (version, region, cluster_id, product_id, utility";
			for (int i=0; i<conFeatureN; i++){
				command += ", ";
				command += conFeatureNames[i];
			}
			for (int i=0; i<boolFeatureN; i++){
				command += ", ";
				command += boolFeatureNames[i];
			}
			command += ", brand) values (";
			command += vs.str();
			command += ", '";
			command += region;
			command += "', ";
			ostringstream cidStream2; 			
			cidStream2<< cluster_id;
			command += cidStream2.str();
			command += ", ";
			ostringstream pIdStream;
			pIdStream << res2->getInt("product_id");
			command += pIdStream.str();
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
			command2 += pIdStream.str();
			command2 += ");";
	
			res3 = stmt->executeQuery(command2);
			utility = 0.0;
			if (res3->rowsCount()>0){
				res3->next();
				for (int f=0; f<conFeatureN; f++){
					utility += res3->getDouble(conFeatureNames[f]);
				}	
			}
			
			ostringstream ustr; 
			ustr << utility;
			command +=  ustr.str();	
			
			
			for (int f=0; f<conFeatureN; f++){
				command += ", ";
				ostringstream feaVStream;
				feaVStream << res2->getDouble(conFeatureNames[f]);
				command += feaVStream.str();
			}
			for (int f=0; f<boolFeatureN; f++){
				command += ", ";
				ostringstream feaVStream;
				feaVStream << res2->getBoolean(boolFeatureNames[f]);
				command += feaVStream.str();
			}
			command += ", \'";
			command += res2->getString("brand");
			command += "\');"; 
			stmt->execute(command);	
		}
		
		// insert in node tables
		
		
	
	}		
	
}