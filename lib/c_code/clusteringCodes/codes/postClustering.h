//	insertOutliers(conFeatureN, boolFeatureN, clusterN, res, res2, stmt, conFetureNames, boolFeatureNames, productName, version, region, outlier_ids)
void insertOutliers(int conFeatureN, int boolFeatureN, int clusterN, sql::ResultSet *res, sql::ResultSet *res2, sql::Statement *stmt,sql::Statement *stmt2, string* conFeatureNames,
					string* boolFeatureNames, string productName, int version, string region, vector<int> outlier_ids){
	//
						ostringstream verStr; 
						ostringstream clusterNStr;
						verStr << version;
						clusterNStr << clusterN;
						int cluster_id;
						int c, r;
						
						string command;
						command ="select * from ";
						command += productName; 
						command +="_clusters where version=";
						command += verStr.str();
						command += " and cluster_size<";
						command += clusterNStr.str();
						
						command +=" and parent_id NOT IN (select id from ";
						command += productName;
						command += "_clusters where version=";
						command += verStr.str();
						command += " and cluster_size<";
						command += clusterNStr.str();
						command += ") and layer>(select max(layer) from ";
						command += productName;
						command += "_clusters where version=";
						command += verStr.str();
						command += ")-2;"; 
						res = stmt->executeQuery(command);
						
						//inserting the ourliers to the closest cluster mean based on continuous features
						double** mean = new double* [conFeatureN];
						for (int f=0; f<conFeatureN; f++){
							mean[f] = new double [res->rowsCount()];
						}	
						r=0;
						int clusterIds [res->rowsCount()];
						
						while (res->next()){
							cluster_id = res->getInt("id");
							ostringstream cidStr; 
							ostringstream vStr;
							vStr << version;
							cidStr<< cluster_id;
							command = "select * from ";
							command += productName;
							command += "_nodes where version=";
							command += vStr.str();
							command += " and cluster_id=";
							command += cidStr.str();
							command += ";";
							res2 = stmt->executeQuery(command);
							c = 0;
							while (res2->next()){
								for (int f=0; f<conFeatureN; f++){
									mean[f][r] = mean[f][r] + res2->getDouble(conFeatureNames[f]);
								}
								c++;
							}
							for (int f=0; f<conFeatureN; f++){
								mean[f][r] = mean[f][r]/c;
							}
							clusterIds[r] = cluster_id;
							r++;
						}
						
						//finding the nearest 
						
						double distance;
						int clusterPick;
						double minDistance;
						for (int i=0; i<outlier_ids.size(); i++){
							command = "select * from ";
							command += productName;
							command += "s where id=";
							ostringstream pIdStr;
							pIdStr << outlier_ids[i];
							command += pIdStr.str();
							command += ";";
							res = stmt->executeQuery(command);
							res->next();	
							minDistance = DBL_MAX;
							clusterPick = clusterIds[0];
						
							double fval; // [conFeatureNames];
							for (int j=0; j<r; j++){
							    distance = 0;	
								for (int f=0; f<conFeatureN; f++){
									fval = res->getDouble(conFeatureNames[f]);
									distance = distance + sqrt(((fval - mean[f][j]) * (fval - mean[f][j])));
								}
								if (distance < minDistance){
									minDistance = distance; 
									clusterPick = clusterIds[j];
								}
							}
							
							//inserting it 
							command = "INSERT into ";
							command += productName;
							command += "_nodes (product_id, cluster_id, version, region, ";
							for (int f=0; f<conFeatureN; f++){
								command += conFeatureNames[f];
								command += ", ";
							}
							for (int f=0; f<boolFeatureN; f++){
								command += boolFeatureNames[f];
								command += ", ";
							}
							command += " brand) values(";
							command += pIdStr.str();
							command += ", ";
							ostringstream cPStr; 
							cPStr << clusterPick;
							command += cPStr.str();
							command += ", ";
							ostringstream vStr;
							vStr << version;
							command += vStr.str();
							command += ", \'";
							command += region;
							command += "\'";
							for (int f=0; f<conFeatureN; f++){
								command += ", ";
								ostringstream fvalstr; 
								fvalstr << res->getDouble(conFeatureNames[f]);
								command += fvalstr.str();
							}
							for (int f=0; f<boolFeatureN; f++){
								command += ", ";
								ostringstream fvalstr; 
								fvalstr << res->getBoolean(boolFeatureNames[f]);
								command += fvalstr.str();
							}
							command += ", \'";
							command += res->getString("brand");
							command += "\');";
							stmt->execute(command);
							////////////////////////////////is not checking and setting the cluster ranges in the cluster table
							command = "update ";
							command += productName;
							command += "_clusters set cluster_size=cluster_size+1 where id=";
							command += cPStr.str();
							command +=";";
							stmt->execute(command);
							string pCommand = "select parent_id from ";
							pCommand += productName;
							pCommand += "_clusters where id=";
							pCommand += cPStr.str();
							pCommand += ";";
							res2 = stmt->executeQuery(pCommand);
							res2->next();
							int parentId = res2->getInt("parent_id");
							while (parentId>0){
								ostringstream parStr;
								parStr << parentId;
								
								//inserting it 
								command = "INSERT into ";
								command += productName;
								command += "_nodes (product_id, cluster_id, version, region, ";
								for (int f=0; f<conFeatureN; f++){
									command += conFeatureNames[f];
									command += ", ";
								}
								for (int f=0; f<boolFeatureN; f++){
									command += boolFeatureNames[f];
									command += ", ";
								}
								command += " brand) values(";
								command += pIdStr.str();
								command += ", ";
								command += parStr.str();
								command += ", ";
								ostringstream vStr;
								vStr << version;
								command += vStr.str();
								command += ", \'";
								command += region;
								command += "\'";
								for (int f=0; f<conFeatureN; f++){
									command += ", ";
									ostringstream fvalstr; 
									fvalstr << res->getDouble(conFeatureNames[f]);
									command += fvalstr.str();
								}
								for (int f=0; f<boolFeatureN; f++){
									command += ", ";
									ostringstream fvalstr; 
									fvalstr << res->getBoolean(boolFeatureNames[f]);
									command += fvalstr.str();
								}
								command += ", \'";
								command += res->getString("brand");
								command += "\');";
								stmt->execute(command);
								
								command = "update ";
								command += productName;
								command += "_clusters set cluster_size=cluster_size+1 where id=";
								command += parStr.str();
								command +=";";
								stmt->execute(command);
								string pCommand = "select parent_id from ";
								pCommand += productName;
								pCommand += "_clusters where id=";
								pCommand += parStr.str();
								pCommand += ";";
								
								res2= stmt->executeQuery(pCommand);
								res2->next();
								parentId = res2->getInt("parent_id");
							}   
						}						

					}	







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
