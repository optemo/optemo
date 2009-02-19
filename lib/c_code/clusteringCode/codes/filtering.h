#include <iostream>

//filterCluster(clusterIDs, clusterID, cameraIDs, cameraN, stmt, res);

int filterCluster(int *clusterIDs, int clusterID, int* cameraIDs, int cameraN, sql::Statement *stmt, sql::ResultSet *res, int clusterN){
	
	int acceptedCN = 0;
	int clusterChildrenN = 0;
	int clusterSize = 0;
	string command;
	int* clusterChildren;
	
if (clusterID !=0){	
	command = "SELECT cluster_size from clusters where id=";
	ostringstream cluster_idStream; 
	cluster_idStream<<clusterID;
	command += cluster_idStream.str();
	command += ";";
	
	res= stmt->executeQuery(command); 
	
	
	res->next();
	
	clusterSize = res->getInt("cluster_size");
		
	int* clusterChildren = new int [clusterSize];
	vector<int> clusterChildrenV;	
	
	//vector<int> clusterChildrenM = vector<int>(clusterChildrenV);

	clusterChildrenV = getChildren(clusterID, clusterChildrenV , stmt, res, clusterN, clusterSize);

	for (int j=0; j<clusterChildrenN; j++){
		clusterChildren[j] = clusterChildrenV.at(j);
	}
}

else{
	
	//if clusterId ==0

		res = stmt->executeQuery("SELECT * from clusters where parent_id=0;");
		int firstLayerClusterN = res->rowsCount();
		int* firstLayerClusters = new int [firstLayerClusterN];
		int k=0;
		int cId;
		while (res->next()){
			firstLayerClusters[k] = res->getInt("id");
			k++;
		}

		int sizeA = 0;
		clusterChildren = new int [sizeA+1];
		for(int j=0; j<firstLayerClusterN; j++){

			cId = firstLayerClusters[j];
			clusterChildren[sizeA] = cId;
			sizeA++;

		    command = "SELECT cluster_size from clusters where id=";
			ostringstream cluster_idStream; 
			cluster_idStream<<cId;
			command += cluster_idStream.str();
			command += ";";

			res= stmt->executeQuery(command); 
			res->next();

			clusterSize = res->getInt("cluster_size");
	


			vector<int> clusterChildrenV;


			clusterChildrenV = getChildren(clusterID, clusterChildrenV, stmt, res, clusterN, clusterSize);
			clusterChildrenN = clusterChildrenV.size();

			int* clusterChildrenNew = new int[sizeA + clusterChildrenN];	
			for (int t=0; t<sizeA; t++){
				clusterChildrenNew[t] = clusterChildren[t];
			}
			delete clusterChildren;	


			for (int i=0; i<clusterChildrenN; i++){

				clusterChildrenNew[sizeA+i] = clusterChildrenV.at(i);
			}

			sizeA += clusterChildrenN;
			clusterChildren = new int[sizeA];
		
			for (int i=0; i<sizeA; i++){
				clusterChildren[i] = clusterChildrenNew[i]; 
			}

			delete clusterChildrenNew;

		}
		clusterChildrenN = sizeA;
	}	
	


	command = "";
	for (int j=0; j<cameraN-1; j++){
		
	 	command += "(SELECT cluster_id FROM nodes WHERE camera_id=";
		ostringstream camera_idStream; 
		camera_idStream << cameraIDs[j];
		command += camera_idStream.str();
		command += ") UNION ";
	}
	
		command += "(SELECT cluster_id FROM nodes WHERE camera_id=";
		ostringstream camera_idStream; 
		camera_idStream << cameraIDs[cameraN-1];
		command += camera_idStream.str();
		command += ");";

		res = stmt->executeQuery(command);

		int j=0;
		int id;
	
		while(res->next()){
			id = res->getInt("cluster_id");	
	
				if (find(clusterChildren, id, clusterChildrenN)>-1){
					clusterIDs[j] = id;
					acceptedCN++;
				}
				else{
					clusterIDs[j] = id;
					acceptedCN++;
				}	
				j++;
	
		}
		return acceptedCN;
}

int filter2(double **filteredRange, string brand,sql::Statement *stmt,
 sql::ResultSet *res, sql::ResultSet *res2, int* cameraIDs, bool* conFilteredFeatures, bool* catFilteredFeatures, int clusterID, int clusterN, int conFeatureN, double** conFeatureRange) {
	
	int cameraN = 0;
	string command;
	string* conFeatureNames = new string[conFeatureN];
	conFeatureNames[0] = "price";
	conFeatureNames[1] = "displaysize";
	conFeatureNames[2] = "opticalzoom";
	conFeatureNames[3] = "maximumresolution";
	

	for(int f=0; f<conFeatureN; f++){
		conFeatureRange[f][0] = 10000.0;
		conFeatureRange[f][1] = 0.0;
	}
	
	
	if (clusterID==0){

		command = "SELECT distinct camera_id, price, maximumresolution, displaysize, opticalzoom from nodes";
		if (conFilteredFeatures[0]){
			command += " where (price>=";
			ostringstream minv;
			minv<<filteredRange[0][0];
			command += minv.str(); 
			command += " AND price<=";
			ostringstream maxv;
			maxv<<filteredRange[0][1];
			command += maxv.str();
			
			command += ")";
			
			if (conFilteredFeatures[1] || conFilteredFeatures[2] || conFilteredFeatures[3] || catFilteredFeatures[0]){
				command += " AND ";
			}
		}
		
		
		
	  if (conFilteredFeatures[1]){
		if(!conFilteredFeatures[0]){
			command += " where ";
		}
			command += "(displaysize>=";
			ostringstream minv;
			minv<<filteredRange[1][0];
			command += minv.str(); 
			command += " AND displaysize<=";
			ostringstream maxv;
			maxv<<filteredRange[1][1];
			command += maxv.str();
			command += ")";
			if (conFilteredFeatures[2] || conFilteredFeatures[3]  || catFilteredFeatures[0]){
				command += " AND ";
			}
		}
		if (conFilteredFeatures[2]){
			if(!conFilteredFeatures[0] && !conFilteredFeatures[1]){
				command += " where ";
			}
			command += "(opticalzoom>=";
			ostringstream minv;
			minv<<filteredRange[2][0];
			command += minv.str(); 
			command += " AND opticalzoom<=";
			ostringstream maxv;
			maxv<<filteredRange[2][1];
			command += maxv.str();
			command += ")";
			if (conFilteredFeatures[3] || catFilteredFeatures[0]){
				command += " AND ";
			}
		} 
		
		if (conFilteredFeatures[3]){
			if(!conFilteredFeatures[0] && !conFilteredFeatures[1] && !conFilteredFeatures[2]){
				command += " where ";
			}
			command += "(maximumresolution>=";
			ostringstream minv;
			minv<<filteredRange[3][0];
			command += minv.str(); 
			command += " AND maximumresolution<=";
			ostringstream maxv;
			maxv<<filteredRange[3][1];
			command += maxv.str();
			command += ")";
			
			if (catFilteredFeatures[0]){
				command += " AND ";
			} 

		}
		
		if (catFilteredFeatures[0]){
			if(!conFilteredFeatures[0] && !conFilteredFeatures[1] && !conFilteredFeatures[2] && !conFilteredFeatures[3]){
				command += " where ";
			}
			command += "(brand =\'";
			command += brand;
			command += "\'"; 
			command += ")";
		}
		command += ";";
	
		res = stmt->executeQuery(command);
		

				command = "";
				ostringstream mino;
				mino<<0;
				command += mino.str(); 
				command += "";
				ostringstream maxv;
				maxv<<0;
				command += maxv.str();
				command += "";


		
		while(res->next()){
				
			cameraIDs[cameraN] = res->getInt("camera_id");
			double* eachValue = new double[conFeatureN];
			
			for (int f=0; f<conFeatureN; f++){
				
				eachValue[f] = res->getDouble(conFeatureNames[f]);
			}
			
			for(int f=0; f<conFeatureN; f++){
				if (eachValue[f]<conFeatureRange[f][0]){
					conFeatureRange[f][0] = eachValue[f];
				}
				if (eachValue[f]>conFeatureRange[f][1]){
					conFeatureRange[f][1] = eachValue[f];
				}
			}

			cameraN++;
		}
		
	
	}
	else{ //if clusterID != 0
		
		command = "SELECT DISTINCT id from clusters where parent_id=";
		ostringstream cid; 
		cid<<clusterID;
		
		command += cid.str();
		command +=";";
		int* clusterChildren = new int[clusterN];

	
		res = stmt->executeQuery(command);
		int clusterN = res->rowsCount();
		if (clusterN==0){ //i.e. there is no subCluster
			command = "SELECT distinct camera_id, price, maximumresolution, displaysize, opticalzoom from nodes where cluster_id=";
			command += cid.str();
		}
		else{
			int i =0;
			while(res->next()){
				clusterChildren[i] = res->getInt("id");
				i++;
			}
			
			command = "SELECT distinct camera_id, price, maximumresolution, displaysize, opticalzoom from nodes where (cluster_id=";
			ostringstream cid2; 
			cid2<<clusterChildren[0];
			command += cid2.str();
	
		
			for (int j=1; j<i; j++){
				command += " OR cluster_id=";
				ostringstream cid2; 
				cid2<<clusterChildren[j];
				command += cid2.str(); 
			}
		
			command += ")";
		}
		if (conFilteredFeatures[0] || conFilteredFeatures[1] || conFilteredFeatures[2] || conFilteredFeatures[3]){
			command += " AND (";
			if (conFilteredFeatures[0]){
				command += " (price>=";
				ostringstream minv;
				minv<<filteredRange[0][0];
				command += minv.str(); 
				command += " AND price<=";
				ostringstream maxv;
				maxv<<filteredRange[0][1];
				command += maxv.str();
				command += ")";
				if (conFilteredFeatures[1] || conFilteredFeatures[2] || conFilteredFeatures[3]){
					command += " AND ";
				}
			}	
			 if(conFilteredFeatures[1]){
				command += "(displaysize>=";
				ostringstream minv;
				minv<<filteredRange[1][0];
				command += minv.str(); 
				command += " AND displaysize<=";
				ostringstream maxv;
				maxv<<filteredRange[1][1];
				command += maxv.str();
				command += ")";
				if (conFilteredFeatures[2] || conFilteredFeatures[3]){
					command += " AND ";
				}
			}
			 if(conFilteredFeatures[2]){
				command += "(opticalzoom>=";
				ostringstream minv;
				minv<<filteredRange[2][0];
				command += minv.str(); 
				command += " AND opticalzoom<=";
				ostringstream maxv;
				maxv<<filteredRange[2][1];
				command += maxv.str();
				command += ")";
				if (conFilteredFeatures[3]){
					command += " AND ";
				}
			}
			 if(conFilteredFeatures[3]){
				command += "(maximumresolution>=";
				ostringstream minv;
				minv<<filteredRange[3][0];
				command += minv.str(); 
				command += " AND maximumresolution<=";
				ostringstream maxv;
				maxv<<filteredRange[3][1];
				command += maxv.str();
				command += ")";
			}	
			command += ");";
		}	
	
		res = stmt->executeQuery(command);
	
		while(res->next()){
		
			cameraIDs[cameraN] = res->getInt("camera_id");
			double* eachValue = new double[conFeatureN];
			for (int f=0; f<conFeatureN; f++){
				eachValue[f] = res->getDouble(conFeatureNames[f]);
			}
			
			for(int f=0; f<conFeatureN; f++){
				if (eachValue[f]<conFeatureRange[f][0]){
					conFeatureRange[f][0] = eachValue[f];
				}
				if (eachValue[f]>conFeatureRange[f][1]){
					conFeatureRange[f][1] = eachValue[f];
				}
			}
			cameraN++;
		}
					
	}
	

	return cameraN;
}



//getRepCluster(cId, conFeatureN, stmt, res2, cameraN,cameraIds,0);
int getRepCluster(int clusterID, int conFeatureN, sql::Statement *stmt , sql::ResultSet *res, int cameraN, int* cameraIDs, int turn, int* reps, int repSize){ 

	string command = "SELECT * from nodes where cluster_id=";
	ostringstream cid;
	int rep=0;
	cid<<clusterID;
	command += cid.str();
	command += ";";
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

		data[1][i] = res->getDouble("displaysize");

		data[2][i] = res->getDouble("opticalzoom");

		data[3][i] = res->getDouble("maximumresolution"); 
		sortedA[i] = res->getInt("camera_id");
	
		i++;
	}

	median2(data, size, conFeatureN, sortedA);

	for(int j=0; j<size; j++){
		while (turn <= repSize){
			if (find(cameraIDs, sortedA[j], cameraN)> -1){
			  if (find(reps, sortedA[j], repSize) == -1){	
					rep = sortedA[j];
					return rep;
			  }		
		   }
		turn++;
		}
	}	
	return rep;
}


//int getReps14(int clusterID, int conFeatureN, sql::Statement *stmt, sql::ResultSet *res, int cameraN, int* cameraIDs, int* reps,int cursor)
bool getRep2(int* reps, int* cameraIds, int cameraN, int* clusterIds, int* clusterCounts, int conFeatureN, int& repW, 
				sql::Statement *stmt, sql::ResultSet *res, sql::ResultSet *res2, int clusterID){
				
	bool reped = false;
	string command;
	int rep;
	int clusterN = 0;
	
	if (clusterID ==0){
		command = "SELECT DISTINCT cluster_id FROM nodes WHERE camera_id=";
		ostringstream idstr;
    	idstr << cameraIds[0]; 
		command += idstr.str(); 
		for (int i=1; i<cameraN; i++){
			command += " OR camera_id=";
			ostringstream idStream;
			idStream << cameraIds[i];
			command += idStream.str();
			}
			command +=";";
			res = stmt->executeQuery(command);
			clusterN = res->rowsCount();
	
   		}
	else{ //clusterID != 0
	
		//	command = "SELECT id, cluster_size FROM clusters where parent_id=";
			command = "SELECT * from ((SELECT distinct id FROM clusters where parent_id=";
			ostringstream clusterIDStream;
			clusterIDStream<<clusterID;
			command += clusterIDStream.str();
			
			command += ") UNION ALL (SELECT distinct cluster_id from nodes where camera_id=";
			ostringstream idstr;
		    idstr << cameraIds[0]; 
			command += idstr.str();
			for (int i=1; i<cameraN; i++){
				command += " OR camera_id=";
				ostringstream idStream;
				idStream << cameraIds[i];
				command += idStream.str();
			}
			
			command += ")) as tbl GROUP BY tbl.id HAVING COUNT(*)=2";
			command += ";";
			res = stmt->executeQuery(command);	
		 	clusterN = res->rowsCount();
			if (clusterN == 0){
				
					command = "SELECT DISTINCT camera_id from nodes where cluster_id=";
					command += clusterIDStream.str();
					command += ";";
					
					res2 = stmt->executeQuery(command);
					repW = res2->rowsCount();
					int i=0;
					while(res2->next()){
						reps[i] = res2->getInt("camera_id");
						i++;
					}
			
					return reped;
				}
			}	

	int j=0;
	int cId;
	
		//if (clusterN>repW){
				
			while(res->next() && j<repW){
			
				if (clusterID == 0){
					cId= res->getInt("cluster_id");
				}
				else{
					cId= res->getInt("id");
				}	
				
					command = "select distinct camera_id from nodes where ( cluster_id=";
					ostringstream cIdStream;
					cIdStream << cId;
					command += cIdStream.str();
					command += " AND (camera_id=";
					ostringstream cameraIdStream;
					cameraIdStream << cameraIds[0];
					command += cameraIdStream.str();
				
					for (int k=1; k<cameraN; k++){
						command += " OR";
						ostringstream cameraIdStream2;
						cameraIdStream2 << cameraIds[k];
						command += " camera_id=";
						command += cameraIdStream2.str();
					}
					
					command += "));";
				
				res2 = stmt->executeQuery(command);	
				int clusterCount = res2->rowsCount();
				rep = getRepCluster(cId, conFeatureN, stmt, res2, cameraN,cameraIds,0, reps,j);
	
				if (rep>0){
					reps[j] = rep;
					clusterIds[j] = cId;			
					clusterCounts[j] = clusterCount;
					j++;	
				}
		}	
	//else{	//clusterN<repW
	if (j<repW){
	int i=0;
				
				while((i<cameraN) && (j<repW) ){
					
					if (find(reps, cameraIds[i], j) == -1){
					
						reps[j] = cameraIds[i];
						command = "SELECT cluster_id from nodes where camera_id=";
						ostringstream cameraIdStream;
						cameraIdStream <<  cameraIds[i];
						command += cameraIdStream.str();
						command += ";";
						res = stmt->executeQuery(command);
						res->next();
						int cid = res->getInt("cluster_id");
				
						clusterIds[j] = cid;
						command = "select distinct camera_id from nodes where ( cluster_id=";
						ostringstream cidStream;
						cidStream << cid;
						command += cidStream.str();
						command += " AND (camera_id=";
						command += cameraIdStream.str();
					
						for (int k=0; k<cameraN; k++){
							command += " OR";
							ostringstream cameraIdStream2;
							cameraIdStream2 << cameraIds[k];
							command += " camera_id=";
							command += cameraIdStream2.str();
						}
						
						command += "));";
						res = stmt->executeQuery(command);
						clusterCounts[j] = res->rowsCount();
						j++;
					}
					i++;	
				}	
		}		
	if (j==repW){
		reped = true;
	}			
	return reped;
}


//int filter(double **filteredRange, string brand,sql::Statement *stmt,
// sql::ResultSet *res, sql::ResultSet *res2, int* cameraIDs, bool* conFilteredFeatures, bool* catFilteredFeatures, int clusterID, int clusterN) {
//
//	int cameraN = 0; ////???
//	int cameraNC = 0;
//	int c=0;
//	int clusterSize;
//	int clusterChildrenN;
//	string command;
//	int* clusterChildren;
//	
//if (clusterID != 0){	
//   command = "SELECT cluster_size from clusters where id=";
//	ostringstream cluster_idStream; 
//	cluster_idStream<<clusterID;
//	command += cluster_idStream.str();
//	command += ";";
//
//	res= stmt->executeQuery(command); 
//
//	res->next();
//	
//	clusterSize = res->getInt("cluster_size");
//
//
//	clusterChildren = new int[clusterSize];
//	
//	
//	vector<int> clusterChildrenV;
//
//		
//	clusterChildrenV = getChildren(clusterID, clusterChildrenV, stmt, res, clusterN, clusterSize);
//	clusterChildrenN = clusterChildrenV.size();
//
//	for (int j=0; j<clusterChildrenN; j++){
//		clusterChildren[j] = clusterChildrenV.at(j);
//	}
//	
//
//	
//}
//
//
//
//
//else{  //if clusterId ==0
//	res = stmt->executeQuery("SELECT * from clusters where parent_id=0;");
//	int firstLayerClusterN = res->rowsCount();
//	int* firstLayerClusters = new int [firstLayerClusterN];
//	int k=0;
//	int cId;
//	while (res->next()){
//		firstLayerClusters[k] = res->getInt("id");
//		k++;
//	}
//	
//	int sizeA = 0;
//	clusterChildren = new int [sizeA+1];
//	for(int j=0; j<firstLayerClusterN; j++){
//		
//		cId = firstLayerClusters[j];
//		clusterChildren[sizeA] = cId;
//		sizeA++;
//		
//	    command = "SELECT cluster_size from clusters where id=";
//		ostringstream cluster_idStream; 
//		cluster_idStream<<cId;
//		command += cluster_idStream.str();
//		command += ";";
//	
//		res= stmt->executeQuery(command); 
//		res->next();
//
//		clusterSize = res->getInt("cluster_size");
//
//		vector<int> clusterChildrenV;
//
//
//		clusterChildrenV = getChildren(clusterID, clusterChildrenV, stmt, res, clusterN, clusterSize);
//		clusterChildrenN = clusterChildrenV.size();
//			
//		int* clusterChildrenNew = new int[sizeA + clusterChildrenN];	
//		for (int t=0; t<sizeA; t++){
//			clusterChildrenNew[t] = clusterChildren[t];
//		}
//		delete clusterChildren;	
//			
//			
//		for (int i=0; i<clusterChildrenN; i++){
//
//			clusterChildrenNew[sizeA+i] = clusterChildrenV.at(i);
//		}
//		
//		sizeA += clusterChildrenN;
//		clusterChildren = new int[sizeA];
//
//		for (int i=0; i<sizeA; i++){
//			clusterChildren[i] = clusterChildrenNew[i]; 
//		}
//		
//		delete clusterChildrenNew;
//	    	
//	}
//	clusterChildrenN = sizeA;
//
//}	
//	int cluster_id;
//	int cSize = clusterChildrenN; //res->rowsCount();
//	int counter = 0;
//	int i=0;
//	command = "";
//	for(int j=0; j<clusterChildrenN-1; j++){
//	
//		cluster_id = clusterChildren[j];
//		command += "(SELECT camera_id FROM nodes WHERE cluster_id=";
//		ostringstream cluster_idStream;
//		cluster_idStream << cluster_id;         
//		command += cluster_idStream.str();
//	if (conFilteredFeatures[0]){	
//		command += " AND (price>=";
//		ostringstream priceMin;
//		priceMin<<filteredRange[0][0];
//		command += priceMin.str();
//		command +=" AND price<=";
//		ostringstream priceMax;
//		priceMax<<filteredRange[0][1];
//		command += priceMax.str();
//	}
//	
//	if (conFilteredFeatures[1]){		
//		command +=" AND displaysize>=";
//		stringstream displaysizeMin;
//		displaysizeMin<<filteredRange[1][0];
//		command += displaysizeMin.str();
//		command +=" AND displaysize<=";
//		ostringstream displaysizeMax;
//		displaysizeMax<<filteredRange[1][1];
//		command += displaysizeMax.str();
//	}
//	
//	if (conFilteredFeatures[2]){		
//		command +=" AND opticalzoom>=";
//		stringstream opticalzoomMin;
//		opticalzoomMin<<filteredRange[2][0];
//		command += opticalzoomMin.str();
//		command +=" AND opticalzoom<=";
//		ostringstream opticalzoomMax;
//		opticalzoomMax<<filteredRange[2][1];
//		command += opticalzoomMax.str();
//	}
//	
//	if (conFilteredFeatures[3]){		
//		command +=" AND maximumresolution>=";
//		stringstream maximumresolutionMin;	
//		maximumresolutionMin<<filteredRange[3][0];
//		command += maximumresolutionMin.str();
//		command +=" AND maximumresolution<=";
//		ostringstream maximumresolutionMax;
//		maximumresolutionMax<<filteredRange[3][1];
//		command += maximumresolutionMax.str();
//	}
//	
//	if (catFilteredFeatures[0]){		
//		command +=" AND brand=";	
//		command += brand;	
//	}
//	
//	
//		command += ")) UNION ";
//	}
//	
//	/////////////////////////////////////STUPID
//		cluster_id = clusterChildren[clusterChildrenN-1];
//		command += "(SELECT camera_id FROM nodes WHERE cluster_id=";
//		ostringstream cluster_idStream2;
//		cluster_idStream2 << cluster_id;         
//		command += cluster_idStream2.str();
//	if (conFilteredFeatures[0]){	
//		command += " AND (price>=";
//		ostringstream priceMin;
//		priceMin<<filteredRange[0][0];
//		command += priceMin.str();
//		command +=" AND price<=";
//		ostringstream priceMax;
//		priceMax<<filteredRange[0][1];
//		command += priceMax.str();
//	}
//	
//	if (conFilteredFeatures[1]){		
//		command +=" AND displaysize>=";
//		stringstream displaysizeMin;
//		displaysizeMin<<filteredRange[1][0];
//		command += displaysizeMin.str();
//		command +=" AND displaysize<=";
//		ostringstream displaysizeMax;
//		displaysizeMax<<filteredRange[1][1];
//		command += displaysizeMax.str();
//	}
//	
//	if (conFilteredFeatures[2]){		
//		command +=" AND opticalzoom>=";
//		stringstream opticalzoomMin;
//		opticalzoomMin<<filteredRange[2][0];
//		command += opticalzoomMin.str();
//		command +=" AND opticalzoom<=";
//		ostringstream opticalzoomMax;
//		opticalzoomMax<<filteredRange[2][1];
//		command += opticalzoomMax.str();
//	}
//	
//	if (conFilteredFeatures[3]){		
//		command +=" AND maximumresolution>=";
//		stringstream maximumresolutionMin;	
//		maximumresolutionMin<<filteredRange[3][0];
//		command += maximumresolutionMin.str();
//		command +=" AND maximumresolution<=";
//		ostringstream maximumresolutionMax;
//		maximumresolutionMax<<filteredRange[3][1];
//		command += maximumresolutionMax.str();
//	}
//	
//
//	if (catFilteredFeatures[0]){
//			
//		command +=" AND brand=";	
//		command += brand;	
//	}
//		command += "));";
//
//		res2 = stmt->executeQuery(command);
//
//		while(res2->next()){
//			cameraIDs[i] = res2->getInt("camera_id");
//			i++;
//			cameraN++;
//		}
//
//	return cameraN; 
//}
