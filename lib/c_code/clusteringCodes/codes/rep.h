int getRepCluster(int clusterID, int conFeatureN, sql::Statement *stmt , sql::ResultSet *res, int productN, int* productIDs, int* reps, int repSize, string productName, 
			 string* conFeatureNames){ 

	string product_clusters = productName;
	product_clusters += "_clusters";
	
	string product_nodes = productName;
	product_nodes += "_nodes";
	
	string command = "SELECT * from ";
	command += product_nodes;
	command +=" where cluster_id=";
	ostringstream cid;
	int rep=0;
	int turn = 0;
	cid<<clusterID;
	command += cid.str();
	command += " and (product_id=";
	ostringstream productIdStream; 
	productIdStream<<productIDs[0];
	command += productIdStream.str();
	
	for (int i=0; i<productN; i++){
		command +=" or product_id="; 
		ostringstream productIdStream2; 
		productIdStream2<<productIDs[i];
		command += productIdStream2.str();
	}
	command += ");";

	res = stmt->executeQuery(command);
	int size = res->rowsCount(); 
	double** data = new double* [conFeatureN];
	for (int f=0; f<conFeatureN; f++){
		data[f] = new double[size];
	}
	
	int* sortedA = new int [size];
	int i=0;
	while(res->next()){
			
		data[0][i] = res->getInt("price");
		for (int f=1; f<conFeatureN; f++){
			data[f][i] = res->getDouble(conFeatureNames[f]);
		}

		sortedA[i] = res->getInt("product_id");
	
		i++;
	}

	median2(data, size, conFeatureN, sortedA);
	for(int j=0; j<size; j++){
		while (turn <= repSize){
			  if (find(reps, sortedA[j], repSize) == -1){	
					rep = sortedA[j];
					return rep;
			  }		
		turn++;
		}
	}	
	return rep;
}

//getRepClusterString(mergedClusterIDs, conFeatureN, stmt, res2, productN,productIds,reps,j);
int getRepClusterString(int* clusterIDs, int mergedClusterN, int conFeatureN, sql::Statement *stmt , sql::ResultSet *res, int productN, int* productIDs, int* reps, 
		int repSize, string productName, string* conFeatureNames){ 

	string product_clusters = productName;
	product_clusters += "_clusters";
	
	string product_nodes = productName;
	product_nodes += "_nodes"; 		 
	
	string command = "SELECT * from ";
	command += product_nodes;
	command += " where (cluster_id=";
	ostringstream cid;
	int rep=0;
	int turn=0;
	cid<<clusterIDs[0];
	command += cid.str();
	for (int i=1; i<mergedClusterN; i++){
		ostringstream cid2;
		cid2 <<clusterIDs[i];
		command += "OR cluster_id=";
		command += cid2.str();
	}
	command += ") and (product_id=";
	ostringstream productIdStream; 
	productIdStream<<productIDs[0];
	command += productIdStream.str();
	
	for (int i=0; i<productN; i++){
		command +=" or product_id="; 
		ostringstream productIdStream2; 
		productIdStream2<<productIDs[i];
		command += productIdStream2.str();
	}
	command += ");";

	res = stmt->executeQuery(command);
	int size = res->rowsCount(); 
	double** data = new double* [conFeatureN];
	for (int f=0; f<conFeatureN; f++){
		data[f] = new double[size];
	}
	
	int* sortedA = new int [size];
	int i=0;
	while(res->next()){
			
		data[0][i] = res->getInt("price");
		for (int f=1; f<conFeatureN; f++){

			data[1][i] = res->getDouble(conFeatureNames[f]);
} 
		sortedA[i] = res->getInt("product_id");

		i++;
	}

	median2(data, size, conFeatureN, sortedA);
	for(int j=0; j<size; j++){
		while (turn <= repSize){
			  if (find(reps, sortedA[j], repSize) == -1){	
					rep = sortedA[j];
					return rep;
			  }		
		turn++;
		}
	}	

	return rep;
}

// getRep(reps, productIDs, productN, resultClusters, childrenIDs, clusterCounts, conFeatureN, repW, stmt, 
//	res, res2, clusterID, smallNFlag, mergedClusterIDs, mergedClusterIDInput, productName, conFeatureNames);

bool getRep(int* reps, int* productIds, int productN, int* clusterIds, int** childrenIDs, double*** conFeatureRangeC, int* clusterCounts, int* childrenCount, int conFeatureN, int& repW, 
				sql::Statement *stmt, sql::ResultSet *res, sql::ResultSet *res2, int clusterID, bool smallNFlag, int* mergedClusterIDs, int* mergedClusterIDInput, string productName, string* conFeatureNames, int searchBoxFlag){
					
					
	bool reped = false;
	string command;
	int rep;
	int clusterN = 0;
	int j=0;
	int cid, clusterCount;
	string product_clusters = productName;
	product_clusters += "_clusters";
	
	string product_nodes = productName;
	product_nodes += "_nodes";	
	//don't need to do so much work if the number of accepted ids are smaller than 9!

	if (smallNFlag){
		
		for(int i=0; i<productN; i++){
			reps[i] = productIds[i];
			if (clusterID==0){
			
				command = "select ";
				command += product_clusters;
				command += ".id from ";
				command += product_nodes;
				command += ", ";
				command += product_clusters;
				command += " where (";
				command += product_nodes;
				command += ".cluster_id=";
				command += product_clusters;
				command += ".id and ";
				command += product_nodes;
				command += ".product_id=";
				ostringstream productIdSmall;
				productIdSmall << productIds[i];
				command += productIdSmall.str();
				command += ");" ;
		}
		
		    else{
			
				command = "select ";
				command += product_clusters;
				command += ".id from ";
				command += product_nodes;
				command += ", ";
				command += product_clusters;
				command += " where (";
				command += product_nodes;
				command += ".cluster_id=";
				command += product_clusters;
				command +=".id and ";
				command += product_nodes;
				command += ".product_id =";
				ostringstream productIdSmall;
				productIdSmall << productIds[i];
				command += productIdSmall.str();
				
				if (clusterID <0 ){ //clusters are merged
					command +=  " and (";
					command += product_clusters;
					command +=".id=";
					ostringstream jointParentStream;
					jointParentStream << mergedClusterIDInput[0];
					command += jointParentStream.str();
					for (int m=1; m<(-1*clusterID); m++){
						ostringstream jointParentStream2;
						jointParentStream2 << mergedClusterIDInput[m];
						command += " OR ";
						command += product_clusters;
						command += ".id=";
						command += jointParentStream2.str();
					}
					command += ")";
				}
				else{ 
					command += " and ";
					command += product_clusters;
					command += ".id=";
			
					ostringstream parentIdSmall;
					parentIdSmall << clusterID;
					command += parentIdSmall.str();
				}
				command += ");" ;
				}				
			//	
						res = stmt->executeQuery(command);
						res->next();
						clusterIds[i] = res->getInt("id");
						
				
					
					
						command = "select distinct product_id, cluster_id from ";
						command += product_nodes;
						command +=" where ((cluster_id=";
						if (clusterID <0 ){ //clusters are merged
							ostringstream jointParentStream;
							jointParentStream << mergedClusterIDInput[0];
							command += jointParentStream.str();
							for (int m=1; m<(-1*clusterID); m++){
								ostringstream jointParentStream2;
								jointParentStream2 << mergedClusterIDInput[m];
								command += " OR ";
								command += product_clusters;
								command +=".id=";
								command += jointParentStream2.str();
							}
							command += ")";
						}
						else{
							ostringstream cStream;
							cStream << clusterIds[i];
							command += cStream.str();
							command += ")";
						}	
						command += " and (product_id=";
						ostringstream camIdStream;
						camIdStream << productIds[0];
						command += camIdStream.str(); 
						for (int k=1; k<productN; k++){
							command += " OR product_id=";
							ostringstream camIdStream2;
							camIdStream2 << productIds[k];
							command += camIdStream2.str();
						}
						command += "));";
				
						res = stmt->executeQuery(command);
						
						clusterCounts[i] = 1;//res->rowsCount();
						childrenCount[i] = 0;
						reped = true;
					//	return reped;
		}
	}
	else{
		
	//where clusterID is 0 - on the first page- 
	//Finding the accepted clusters 
	if (clusterID ==0){
	
		command = "SELECT DISTINCT ";command += product_nodes;command += ".cluster_id, ";command += product_clusters;command += ".cluster_size, ";command += product_clusters;
		command +=".layer FROM ";command += product_nodes;command +=", ";command += product_clusters;command +=" WHERE (";command +=product_clusters;command += ".id=";
		command += product_nodes;	command += ".cluster_id AND (product_id=";ostringstream idstr;idstr << productIds[0]; command += idstr.str(); 
		
		for (int i=1; i<productN; i++){
			command += " OR product_id=";
			ostringstream idStream;
			idStream << productIds[i];
			command += idStream.str();
		}
			command += ")) order by layer, cluster_size DESC;";

			res = stmt->executeQuery(command);
		if (searchBoxFlag){
		
			res->next();
			int lay = res->getInt("layer");
		
				command = "SELECT DISTINCT ";
				command += product_nodes;
				command += ".cluster_id, ";
				command += product_clusters;
				command += ".cluster_size FROM ";
				command += product_nodes;
				command +=", ";
				command += product_clusters;
				command +=" WHERE (";
				command +=product_clusters;
				command += ".id=";
				command += product_nodes;
				command += ".cluster_id AND ";
				command += product_clusters;
				command +=".layer=";
				ostringstream layStream;
				layStream << lay;
				command += layStream.str();
				command += " AND (product_id=";
				ostringstream idstr;
		    	idstr << productIds[0]; 
				command += idstr.str(); 
				for (int i=1; i<productN; i++){
					command += " OR product_id=";
					ostringstream idStream;
					idStream << productIds[i];
					command += idStream.str();
				}
					command += ")) order by layer, cluster_size DESC;";
					res = stmt->executeQuery(command);
					clusterN = res->rowsCount();
			
		}
		else{	
			clusterN = res->rowsCount();
		}	
	}
	
	
	//If the user clicks on explore similar -- there is a parent_id
	
	else{ 
	
		command = "SELECT DISTINCT ";
		command += product_nodes;
		command += ".cluster_id, ";
		command += product_clusters;
		command +=".cluster_size, ";
		command += product_clusters;
		command +=".layer FROM ";
		command += product_nodes;
		command +=", ";
		command +=product_clusters;
		command +=" WHERE (";
		command += product_clusters;
		command +=".id=";
		command += product_nodes;
		command +=".cluster_id AND (";
		command +=product_clusters;
		command +=".parent_id=";
		    if (clusterID <0 ){ //clusters are merged
				ostringstream jointParentStream;
				jointParentStream << mergedClusterIDInput[0];
				command += jointParentStream.str();
				for (int m=1; m<(-1*clusterID); m++){
					ostringstream jointParentStream2;
					jointParentStream2 << mergedClusterIDInput[m];
					command += " OR clusters.parent_id=";
					command += jointParentStream2.str();
				}
				command += ")";
			}
			else{
				
				ostringstream clusterIDStream;
				clusterIDStream<<clusterID;
				command += clusterIDStream.str();
				command += ")";
			}	
			
			command += " AND (";
			command += product_nodes;
			command += ".product_id=";
			ostringstream idstr;
		    idstr << productIds[0]; 
			command += idstr.str();
			for (int i=1; i<productN; i++){
				command += " OR ";
				command += product_nodes;
				command += ".product_id=";
				ostringstream idStream;
				idStream << productIds[i];
				command += idStream.str();
			}	
			command += ")) order by ";
			command += product_clusters;
			command +=".layer, ";
			command += product_clusters;
			command += ".cluster_size;";
//			cout<<"commad is "<<command<<endl;
			res = stmt->executeQuery(command);	

		 	clusterN = res->rowsCount();
		
		
			if (clusterN == 0){
				
				command = "SELECT DISTINCT product_id from ";
				command += product_nodes;
				command += " where (cluster_id=";
					if (clusterID <0 ){ //clusters are merged
					
						ostringstream jointParentStream;
						jointParentStream << mergedClusterIDInput[0];
						command += jointParentStream.str();
						for (int m=1; m<(-1*clusterID); m++){
							ostringstream jointParentStream2;
							jointParentStream2 << mergedClusterIDInput[m];
							command += " OR cluster_id=";
							command += jointParentStream2.str();
						}
						command += ")";
					}
					else{
						ostringstream clusterIDStream;
						clusterIDStream<<clusterID;
						command += clusterIDStream.str();
						command += ")";
					}	
					command += " AND (product_id=";
					ostringstream idstr2;
				    idstr2 << productIds[0]; 
					command += idstr2.str();
					for (int i=1; i<productN; i++){
						command += " OR product_id=";
						ostringstream idStream3;
						idStream3 << productIds[i];
						command += idStream3.str();
					}
					command += ");";
				
					res2 = stmt->executeQuery(command);
					
					repW = res2->rowsCount();
				
					j=0;
					while(res2->next()){
						reps[j] = res2->getInt("product_id");
						j++;
					}
					return reped; ///////////////////////////////////////////////////////////////
				}
			}	
	
	        int cId;
		

			while(res->next() && j<repW){
		
			//	if (clusterID == 0){
				
					cId= res->getInt("cluster_id");
					//cout<<"cId is      :"<<cId<<endl;
				
			//	}
			//	else{
			//		cId= res->getInt("cluster_id");
			//	}				
				command = "select distinct product_id from ";
				command += product_nodes;
				command +=" where ((cluster_id=";
					if (clusterID <0 ){ //clusters are merged
						ostringstream jointParentStream;
						jointParentStream << mergedClusterIDInput[0];
						command += jointParentStream.str();
						for (int m=1; m<(-1*clusterID); m++){
							ostringstream jointParentStream2;
							jointParentStream2 << mergedClusterIDInput[m];
							command += " OR cluster_id=";
							command += jointParentStream2.str();
						}
						command += ")";
					}
					else{
						ostringstream cIdStream;
						cIdStream << cId;
						command += cIdStream.str();
						command += ")";
					}	
					command += " AND (product_id=";
					ostringstream productIdStream;
					productIdStream << productIds[0];
					command += productIdStream.str();
					for (int k=1; k<productN; k++){
						command += " OR";
						ostringstream productIdStream2;
						productIdStream2 << productIds[k];
					
						command += " product_id=";
						command += productIdStream2.str();
					}	
				
				command += "));";
			
				res2 = stmt->executeQuery(command);	
				int clusterCount = 0;
				clusterCount = res2->rowsCount();
				int cIdN = 1;
				int* cIds = new int[cIdN];
				cIds[0] = cId;
				rep = getRepCluster(cId,conFeatureN, stmt, res2, productN,productIds, reps,j, productName, conFeatureNames);
				
				if (rep>0){
				
					reps[j] = rep;
			clusterIds[j] = cId;
				
			if (searchBoxFlag){				
					command = "SELECT ";
					command += productName;
					command +="_clusters.id, ";
					command += productName;
					command += "_nodes.product_id from ";
					command += productName; 
					command += "_clusters,";
					command += productName;
					command += "_nodes where (";
					command += productName;
					command += "_clusters.id=";
					command += productName;
					command += "_nodes.cluster_id AND ";
					command += productName;
					command += "_clusters.parent_id=";
					ostringstream cidstream;
					cidstream << cId;
					command += cidstream.str();
					command += " AND (";
					command += productName;
					command += "_nodes.product_id=";
					ostringstream pidSt3;
					pidSt3<<productIds[0];
					command += pidSt3.str();
					for (int p=1; p<productN; p++){
						command += " OR ";
						command += productName;
						command += "_nodes.product_id=";
						ostringstream pidSt4;
						pidSt4<<productIds[p];
						command += pidSt4.str();
					}
					
					command += "));";
				
				}
				else{

					command = "SELECT id FROM ";
					command += productName; 
					command += "_clusters where (parent_id=";
					ostringstream cidstream;
						cidstream << cId;
						command += cidstream.str();
					
			
					
					command += ");";
				}
				
					res2 = stmt->executeQuery(command);
					if (res2->rowsCount() ==0){
						command = "SELECT id FROM ";
						command += productName; 
						command += "_clusters where (id=";
						ostringstream cidstream;
						cidstream << cId;
						command += cidstream.str();
							command += ");";
					}
					res2 = stmt->executeQuery(command);
					int cSize = 0;
					while(res2->next()){
						childrenIDs[j][cSize] = res2->getInt("id");
						cSize++;
					}
					childrenCount[j] = cSize;
				
					clusterCounts[j] = clusterCount;
					j++;	
				}
			}
		
	if (j<repW){ // i.e. (clusterN<repW)
		// we should use children and remove parent
			int i=0;
			while((i<j) && (j<repW)){ 
		
					ostringstream parentClusterStream;
					parentClusterStream<< clusterIds[i];
					command = "SELECT distinct ";
					command += product_clusters;
					command += ".id, ";
					command += product_clusters;
					command += ".cluster_size from ";
					command += product_clusters;
					command += ", ";
					command += product_nodes;
					command += " where (";
					command += product_nodes;
					command +=".cluster_id=";
					command += product_clusters;
					command += ".id and (";
					command += product_clusters;
					command +=".parent_id=";
					if (clusterID <0 ){ //clusters are merged
						ostringstream jointParentStream;
						jointParentStream << mergedClusterIDInput[0];
						command += jointParentStream.str();
						for (int m=1; m<(-1*clusterID); m++){
							ostringstream jointParentStream2;
							jointParentStream2 << mergedClusterIDInput[m];
							command += " OR ";
							command += product_clusters;
							command += ".parent_id=";
							command += jointParentStream2.str();
						}
						command += ")";
					}
					else{
						command += parentClusterStream.str();
						command += ")";
					}
					
					command += ") order by ";
					command += product_clusters;
					command += ".cluster_size DESC;";
					
					res = stmt->executeQuery(command);
				
				    int cCount = res->rowsCount();
					if ( cCount> 0){
						int preClusterCount = clusterCounts[i];
						int preRep = reps[i];
						int preId = clusterIds[i];
						shift1(reps, clusterIds, clusterCounts, j);
						j--;
						int childLeftN = cCount;
							
						while(res->next() && j<repW){
						
							cid = res->getInt("id");
							command ="select distinct * from ";
							command += product_nodes;
							command +=" where ((cluster_id=";
							if (clusterID <0 ){ //clusters are merged
								ostringstream jointParentStream;
								jointParentStream << mergedClusterIDInput[0];
								command += jointParentStream.str();
								for (int m=1; m<(-1*clusterID); m++){
									ostringstream jointParentStream2;
									jointParentStream2 << mergedClusterIDInput[m];
									command += " OR cluster_id=";
									command += jointParentStream2.str();
								}
								command += ")";
							}
							else{
								ostringstream cIdStream3;
								cIdStream3 << cid;
								command += cIdStream3.str();
								command += ")";
							}	
							command += " and (product_id=";
							ostringstream productIdStream3; 
							productIdStream3 << productIds[0];
							command += productIdStream3.str();
						 	for (int k=1; k<productN; k++){
									command += " OR";
									ostringstream productIdStream2;
									productIdStream2 << productIds[k];
									command += " product_id=";
									command += productIdStream2.str();
								}
							command += "));";
						
							res2 = stmt->executeQuery(command);
							
							clusterCount = res2->rowsCount();
							if (clusterCount>0){
								rep = getRepCluster(cid,conFeatureN, stmt, res2, productN,productIds,reps,j, productName, conFeatureNames);
								if(rep>0) {	
									reps[j] = rep;
									cout<<"     MANIP:cid is    "<<cid<<endl;
									clusterIds[j] = cid;
									
								//	cout<<"clusterIds here is "<<cid<<endl;
									command = "SELECT id from ";
									command += productName;
									command += "_clusters where parent_id=";
									ostringstream cidstream;
									cidstream << cId;
									command += cidstream.str();
									command += ";";
									res2 = stmt->executeQuery(command);
									int cSize = 0;
									while(res2->next()){
										childrenIDs[j][cSize] = res2->getInt("id");
										cSize++;
									}		
									childrenCount[j] = cSize;
								
									clusterCounts[j] = clusterCount;
								
									j++;
									childLeftN--;	
								}
								cout<<" j  is  "<<j<<"   clusterIds is "<<clusterIds[j]<<endl;
							}	
						}
						if (childLeftN == cCount){
					
								reps[j] = preRep;
								command = "SELECT id from ";
								command += productName;
								command += "_clusters where parent_id=";
								ostringstream cidstream;
								cidstream << cId;
								command += cidstream.str();
								command += ";";
							
								res = stmt->executeQuery(command);
					
								int cSize = 0;
								while(res->next()){
									childrenIDs[j][cSize] = res->getInt("id");
									cSize++;
								}	
								childrenCount[j] = cSize;
								clusterCounts[j] = preClusterCount;
								clusterIds[j] = preId;									
						}
						else if (childLeftN > 0){ // i.e. some of the children are in repW and some are left out
							//merge the unused children
							mergedClusterIDs = new int [childLeftN];
							string appendedClusters;
							ostringstream appendedClusterStream;
							j--;
							appendedClusterStream << clusterIds[j];
							appendedClusters = appendedClusterStream.str();
							int mergedClusterN = 0;
							int mergedCount = 0;
							while(res->next()){ 
								cid = res->getInt("id");
								command ="select distinct * from ";
								command += product_nodes;
								command += " where ((cluster_id=";
								if (clusterID <0 ){ //clusters are merged
									ostringstream jointParentStream;
									jointParentStream << mergedClusterIDInput[0];
									command += jointParentStream.str();
									for (int m=1; m<(-1*clusterID); m++){
										ostringstream jointParentStream2;
										jointParentStream2 << mergedClusterIDInput[m];
										command += " OR cluster_id=";
										command += jointParentStream2.str();
									}
									command += ")";
								}
								else{
									ostringstream cIdStream3;
									cIdStream3 << cid;
									command += cIdStream3.str();
									command += ")";
								}	
								command += " and (product_id=";
								ostringstream productIdStream3; 
								productIdStream3 << productIds[0];
								command += productIdStream3.str();
							 	for (int k=1; k<productN; k++){
										command += " OR";
										ostringstream productIdStream2;
										productIdStream2 << productIds[k];
										command += " product_id=";
										command += productIdStream2.str();
									}
								command += "));";
								res2 = stmt->executeQuery(command);
								
								clusterCount = res2->rowsCount();
								if (clusterCount>0){
									mergedClusterIDs[mergedClusterN] = cid;
									mergedClusterN++;
									mergedCount += clusterCount;
								}
							}
							if (mergedCount>0){
								rep = getRepClusterString(mergedClusterIDs, mergedClusterN, conFeatureN, stmt, res2, productN,productIds,reps,j, productName, conFeatureNames);
								
								if (rep>0){
									reps[j] = rep;
									clusterIds[j] = -1*(mergedClusterN); //meaning that it is a mergedCluster
									clusterCounts[j] = mergedCount;
									j++;
								}
						
							}
			  		}
			}
		i++;
	}
				
	}						
	if (j==repW){
	
		reped = true;
	}
	else if(j<repW){
		
		repW = j;
		reped=true;
	} 		
}


for (int r=0; r<repW; r++){
			string command2 = "select price";
			conFeatureRangeC[r][0][0] = 10000000;
			conFeatureRangeC[r][0][1] = 1e-5;
			for(int f=1; f<conFeatureN; f++){
				command2 += ", ";
				ostringstream fst;
				fst << conFeatureNames[f];
				command2 += fst.str();
				
				////
				conFeatureRangeC[r][f][0] = 10000000;
				conFeatureRangeC[r][f][1] = 1e-5;
				///
			} 
			command2 += " from ";
			command2 += product_nodes;
			command2 += " where cluster_id=";
			ostringstream idSt;
			idSt << clusterIds[r];
			command2 += idSt.str();
			
			command2 += " AND (id=";
			ostringstream proSt; 
			proSt<< productIds[0];
			command2 += proSt.str();
			for(int p=0; p<productN; p++){
				command2 += " OR id=";
				ostringstream proSt2; 
				proSt2<< productIds[0];
				command2 += proSt2.str();
			} 
			command2 += ");";
			
			double fValue;
			//cout<<"command is "<<command2<<endl;
			res = stmt->executeQuery(command2);
			//	cout<<"getRep"<<endl;
			while (res->next()){
				for (int f=0; f<conFeatureN; f++){
					fValue = res->getDouble(conFeatureNames[f]);
					if (fValue < conFeatureRangeC[r][f][0]){
						conFeatureRangeC[r][f][0] = fValue;
					}
					else if (fValue > conFeatureRangeC[r][f][1]){
						conFeatureRangeC[r][f][1] = fValue;
					} 
				}	
			}
}
   
	
	return reped;	
}
