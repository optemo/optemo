//	insertOutliers(conFeatureN, boolFeatureN, clusterN, res, res2, stmt, conFetureNames, boolFeatureNames, productName, version, region, outlier_ids)
void insertOutliers(int conFeatureN, int boolFeatureN, int clusterN, sql::ResultSet *res, sql::ResultSet *res2, sql::ResultSet *res3, sql::Statement *stmt,sql::Statement *stmt2, string* conFeatureNames,
					string* boolFeatureNames, string productName, int version, string region, vector<int> outlier_ids){
	//
						ostringstream verStr; 
						ostringstream clusterNStr;
						verStr << version;
						clusterNStr << clusterN;
						int cluster_id;
						int c, r;
						
						string command, pCommand;
						command ="select * from clusters where product_type=\'" + productName + "_" + region + "\' and version=" + verStr.str();
						command +=" and id NOT IN (select parent_id from clusters where product_type=\'" + productName + "_" + region + "\' and version=" + verStr.str()+");";
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
							command = "select * from nodes where product_type=\'"+ productName + "_" + region + "\' and version=" + vStr.str() + " and cluster_id=" + cidStr.str() + ";";
							res2 = stmt->executeQuery(command);
							c = 0;
							while (res2->next()){
								for (int f=0; f<conFeatureN; f++){
									ostringstream pIDS;
									pIDS << res2->getInt("product_id");
									command = "select value from cont_specs where product_type=\'"+ productName+"_"+region+"\' and name=\'"+conFeatureNames[f]+ "\' and product_id="; 
									command += pIDS.str() +  ";";
									res3 = stmt->executeQuery(command);
									res3->next();
									mean[f][r] = mean[f][r] + res3->getDouble("value");
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
						
							minDistance = DBL_MAX;
							clusterPick = -1;
							ostringstream pIdStr;
							pIdStr << outlier_ids[i];
						
							double fval; // [conFeatureNames];
							for (int j=0; j<r; j++){
							    distance = 0;	
								for (int f=0; f<conFeatureN; f++){
									command = "select * from cont_specs where product_type=\'" + productName+ "_" + region + "\' and product_id = " + pIdStr.str()
											+" and (name=\'"+ conFeatureNames[f] + "\');";
									res = stmt->executeQuery(command);
									res->next();
									fval = res->getDouble("value");
									distance = distance + sqrt(((fval - mean[f][j]) * (fval - mean[f][j])));
								}
								//check for the size of the cluster:
								ostringstream cIdSt;
								cIdSt << clusterIds[j];
								command ="select id from nodes where product_type=\'"+productName+"_"+region+"\' and cluster_id="+cIdSt.str()+ ";";
								res2 = stmt->executeQuery(command);
								if (res2->rowsCount()<9){
									if (distance < minDistance){
										minDistance = distance; 
										clusterPick = clusterIds[j];
									}	
								}
							}
							if (clusterPick==-1) {
								cout<<"THERE IS A PROBLEM WITH FINDING CLUSTER ID WHEN INSERTING OUTLIERS"<<endl;
								return;
							}
							
							//inserting it 
							ostringstream cPStr; 
							cPStr << clusterPick;
							ostringstream vStr;
							vStr << version;
							command = "INSERT into nodes (product_type, product_id, cluster_id, version) values(\'" + productName + "_" + region + "\', "+
										pIdStr.str()+", "+ cPStr.str()+ ", "+ vStr.str() + ");";
							stmt->execute(command);
							////////////////////////////////

							pCommand = "select parent_id from clusters where product_type=\'"+ productName+"_"+region+"\' and id=" + cPStr.str()+";";
							res2 = stmt->executeQuery(pCommand);
							res2->next();
							int parentId = res2->getInt("parent_id");
							while (parentId>0){
								ostringstream parStr;
								parStr << parentId;
								
								//inserting it 
								command = "INSERT into nodes (product_type, product_id, cluster_id, version) values(\'" +  productName +  "_" + region + 
											"\', " + pIdStr.str() +  ", " + parStr.str() + ", ";
								ostringstream vStr;
								vStr << version;
								command += vStr.str();

			
								command += ");";
								stmt->execute(command);
								
								string pCommand = "select parent_id from clusters where product_type = \'" + productName + "_" + region + "\' and id="+parStr.str()+";";
								
								res2= stmt->executeQuery(pCommand);
								res2->next();
								parentId = res2->getInt("parent_id");
							}   
						}						

					}	




void leafClustering(int conFeatureN, int boolFeatureN, int clusterN, string* conFeatureNames, string* boolFeatureNames, 
					sql::ResultSet *res, sql::ResultSet *res2, sql::ResultSet *res3, sql::Statement *stmt, string productName, int version, string region){
	string command, command2;

	int cluster_id;
	int layer;
	
	command = "select distinct id, layer from clusters where version=";
	ostringstream vstream;
	vstream << version;
	command += vstream.str();
	
	command += " and id NOT IN (select distinct parent_id from clusters where version=";
	command += vstream.str();
	command += ")";

	res = stmt->executeQuery(command);
	while (res->next()){
		
		layer = res->getInt("layer") + 1;
		ostringstream lStream;
		lStream << layer;
		command = "select * from nodes where cluster_id=";
		ostringstream idStream;
		idStream << res->getInt("id");
		command += idStream.str();
		command += ";";
		res2 = stmt->executeQuery(command);
		
		while (res2->next()){
				command= "INSERT into clusters (product_type, version, layer, parent_id) values (\'"+ productName + "_" + region + "\', " + vstream.str()
						+ ", " + lStream.str() + ", " + idStream.str() + ");";
				stmt->execute(command);
				
				command = "INSERT into nodes (product_type, version, cluster_id, product_id) values (\'" + productName +"_" + region + "\', "
						+ vstream.str() + ", ";
						
				command2 = "SELECT last_insert_id();"; // from clusters;
                res3 = stmt->executeQuery(command2);
			    if (res3->next()){
					cluster_id = res3->getInt("last_insert_id()");
				}
				else{
					cout<<"ERR- inserting into the cluster table"<<endl;
				}
				
				ostringstream cIdStream; 
				cIdStream << cluster_id;
				ostringstream prodIDS; 
				prodIDS << res2->getInt("product_id");
				command += cIdStream.str() +  ", "+ prodIDS.str()+ ");";
				stmt->execute(command);
				
		}

	}

}	
