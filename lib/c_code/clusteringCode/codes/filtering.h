#include <iostream>
#include "helpers.h"

//int filterCluster(int *clusterIDs, int clusterID, int* productIDs, int productN, sql::Statement *stmt, sql::ResultSet *res, int clusterN){
//	
//	int acceptedCN = 0;
//	int clusterChildrenN = 0;
//	int clusterSize = 0;
//	string command;
//	int* clusterChildren;
//	
//if (clusterID !=0){	
//	command = "SELECT cluster_size from clusters where id=";
//	ostringstream cluster_idStream; 
//	cluster_idStream<<clusterID;
//	command += cluster_idStream.str();
//	command += ";";
//	
//	res= stmt->executeQuery(command); 
//	
//	
//	res->next();
//	
//	clusterSize = res->getInt("cluster_size");
//		
//	int* clusterChildren = new int [clusterSize];
//	vector<int> clusterChildrenV;	
//
//	clusterChildrenV = getChildren(clusterID, clusterChildrenV , stmt, res, clusterN, clusterSize);
//
//	for (int j=0; j<clusterChildrenN; j++){
//		clusterChildren[j] = clusterChildrenV.at(j);
//	}
//}
//
//else{
//	
//	//if clusterId ==0
//
//		res = stmt->executeQuery("SELECT * from clusters where parent_id=0;");
//		int firstLayerClusterN = res->rowsCount();
//		int* firstLayerClusters = new int [firstLayerClusterN];
//		int k=0;
//		int cId;
//		while (res->next()){
//			firstLayerClusters[k] = res->getInt("id");
//			k++;
//		}
//
//		int sizeA = 0;
//		clusterChildren = new int [sizeA+1];
//		for(int j=0; j<firstLayerClusterN; j++){
//
//			cId = firstLayerClusters[j];
//			clusterChildren[sizeA] = cId;
//			sizeA++;
//
//		    command = "SELECT cluster_size from clusters where id=";
//			ostringstream cluster_idStream; 
//			cluster_idStream<<cId;
//			command += cluster_idStream.str();
//			command += ";";
//
//			res= stmt->executeQuery(command); 
//			res->next();
//
//			clusterSize = res->getInt("cluster_size");
//			vector<int> clusterChildrenV;
//			clusterChildrenV = getChildren(clusterID, clusterChildrenV, stmt, res, clusterN, clusterSize);
//			clusterChildrenN = clusterChildrenV.size();
//
//			int* clusterChildrenNew = new int[sizeA + clusterChildrenN];	
//			for (int t=0; t<sizeA; t++){
//				clusterChildrenNew[t] = clusterChildren[t];
//			}
//			delete clusterChildren;	
//
//
//			for (int i=0; i<clusterChildrenN; i++){
//
//				clusterChildrenNew[sizeA+i] = clusterChildrenV.at(i);
//			}
//
//			sizeA += clusterChildrenN;
//			clusterChildren = new int[sizeA];
//		
//			for (int i=0; i<sizeA; i++){
//				clusterChildren[i] = clusterChildrenNew[i]; 
//			}
//
//			delete clusterChildrenNew;
//
//		}
//		clusterChildrenN = sizeA;
//	}	
//	command = "";
//	for (int j=0; j<productN-1; j++){
//		
//	 	command += "(SELECT cluster_id FROM nodes WHERE product_id=";
//		ostringstream product_idStream; 
//		product_idStream << productIDs[j];
//		command += product_idStream.str();
//		command += ") UNION ";
//	}
//	
//		command += "(SELECT cluster_id FROM nodes WHERE product_id=";
//		ostringstream product_idStream; 
//		product_idStream << productIDs[productN-1];
//		command += product_idStream.str();
//		command += ");";
//
//		res = stmt->executeQuery(command);
//
//		int j=0;
//		int id;
//	
//		while(res->next()){
//			id = res->getInt("cluster_id");	
//	
//				if (find(clusterChildren, id, clusterChildrenN)>-1){
//					clusterIDs[j] = id;
//					acceptedCN++;
//				}
//				else{
//					clusterIDs[j] = id;
//					acceptedCN++;
//				}	
//				j++;
//	
//		}
//		return acceptedCN;
//}

int filter2(double **filteredRange, string brand,sql::Statement *stmt,
 sql::ResultSet *res, sql::ResultSet *res2, int* productIDs, bool* conFilteredFeatures, bool* catFilteredFeatures, int clusterID, int clusterN, int conFeatureN, double** conFeatureRange, string productName, string* conFeatureNames) {

	int productN = 0;
	string command;
	string product_clusters = productName;
	product_clusters += "_clusters";
	string product_nodes = productName;
	product_nodes += "_nodes";
	


	for(int f=0; f<conFeatureN; f++){
		conFeatureRange[f][0] = 100000000.0;
		conFeatureRange[f][1] = 0.0;
	}
	double eps = 0.00001;
	for (int f=0; f<conFeatureN; f++){
		filteredRange[f][0] -= eps;
		filteredRange[f][1] += eps;
	}
	
	if (clusterID==0){
		command = "SELECT distinct product_id, price";
		for (int i=1; i<conFeatureN; i++){
			command += ", ";
			command += conFeatureNames[i];
		}
		command += " from ";
		command += product_nodes;
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
		
	 ////////////////////////////////////////This SHOULD be also 	
	  if (conFilteredFeatures[1]){
		if(!conFilteredFeatures[0]){
			command += " where ";
		}
		command += "(";
		command += conFeatureNames[1]; 
		command += ">=";
		ostringstream minv;
		minv<<filteredRange[1][0];
		command += minv.str(); 
		command += " AND ";
		command += conFeatureNames[1];
		command += "<=";
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
			command += "(";
			command += conFeatureNames[2];
			command +=">=";
			ostringstream minv;
			minv<<filteredRange[2][0];
			command += minv.str(); 
			command += " AND ";
			command += conFeatureNames[2];
			command += "<=";
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
			command += "(";
			command += conFeatureNames[3];
			command +=">=";
			ostringstream minv;
			minv<<filteredRange[3][0];
			command += minv.str(); 
			command += " AND ";
			command += conFeatureNames[3];
			command += "<=";
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
				
			productIDs[productN] = res->getInt("product_id");
			double* eachValue = new double[conFeatureN];
		
			for (int i=0; i<conFeatureN; i++){
				eachValue[i] = res->getDouble(conFeatureNames[i]);
			}
			
			for(int f=0; f<conFeatureN; f++){
				if (eachValue[f]<conFeatureRange[f][0]){
					conFeatureRange[f][0] = eachValue[f];
				}
				if (eachValue[f]>conFeatureRange[f][1]){
					conFeatureRange[f][1] = eachValue[f];
				}
			}

			productN++;
		}

	}
	
	else{ //if clusterID != 0

		command = "SELECT DISTINCT id from ";
		command += product_clusters;
		command +=" where parent_id=";
		ostringstream cid; 
		cid<<clusterID;
		
		command += cid.str();
		command +=";";
		int* clusterChildren = new int[clusterN];

	
		res = stmt->executeQuery(command);
			
		int clusterN = res->rowsCount();
		
		if (clusterN==0){ //i.e. there is no subCluster
			
			command = "SELECT distinct product_id, price";
			for (int i=1; i<conFeatureN; i++){
				command += ", ";
				command += conFeatureNames[i];
			}
			command += " from ";
			command += product_nodes;
			command += " where cluster_id=";
			command += cid.str();
		}
		else{
			int i =0;
			while(res->next()){
				clusterChildren[i] = res->getInt("id");
				i++;
			}
			
			command = "SELECT distinct product_id, price";
			for (int i=0; i<conFeatureN; i++){
				command += ", ";
				command += conFeatureNames[i];
			}
			command += " from ";
			command += product_nodes;
			command +=" where (cluster_id=";
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
		if (conFilteredFeatures[0] || conFilteredFeatures[1] || conFilteredFeatures[2] || conFilteredFeatures[3] || catFilteredFeatures[0]){
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
				if (conFilteredFeatures[1] || conFilteredFeatures[2] || conFilteredFeatures[3] || catFilteredFeatures[0]){
					command += " AND ";
				}
			}	
			 if(conFilteredFeatures[1]){
				command += "(";
				command += conFeatureNames[1];
				command +=">=";
				ostringstream minv;
				minv<<filteredRange[1][0];
				command += minv.str(); 
				command += " AND ";
				command += conFeatureNames[1];
				command +="<=";
				ostringstream maxv;
				maxv<<filteredRange[1][1];
				command += maxv.str();
				command += ")";
				if (conFilteredFeatures[2] || conFilteredFeatures[3] || catFilteredFeatures[0]){
					command += " AND ";
				}
			}
			 if(conFilteredFeatures[2]){
				command += "(";
				command += conFeatureNames[2];
				command += ">=";
				ostringstream minv;
				minv<<filteredRange[2][0];
				command += minv.str(); 
				command += " AND ";
				command += conFeatureNames[2];
				command +="<=";
				ostringstream maxv;
				maxv<<filteredRange[2][1];
				command += maxv.str();
				command += ")";
				if (conFilteredFeatures[3] || catFilteredFeatures[0]){
					command += " AND ";
				}
			}
			 if(conFilteredFeatures[3]){
				command += "(";
				command += conFeatureNames[3];
				command +=">=";
				ostringstream minv;
				minv<<filteredRange[3][0];
				command += minv.str(); 
				command += " AND ";
				command += conFeatureNames[3];
				command +="<=";
				ostringstream maxv;
				maxv<<filteredRange[3][1];
				command += maxv.str();
				command += ")";
				if (catFilteredFeatures[0]){
					command += " AND ";
				}
			}
			if(catFilteredFeatures[0]){
				
				command += "(brand =\'";
				command += brand;
				command += "\'"; 
				command += ")";
			}
				
			command += ");";
		}	
	
		res = stmt->executeQuery(command);

		while(res->next()){
		
			productIDs[productN] = res->getInt("product_id");
			double* eachValue = new double[conFeatureN];
			for (int f=0; f<conFeatureN; f++){
				eachValue[f] = res->getDouble(conFeatureNames[f]);
			}
			
			for(int f=0; f<conFeatureN; f++){
				if (eachValue[f]<=conFeatureRange[f][0]){
					conFeatureRange[f][0] = eachValue[f];
				}
				if (eachValue[f]>=conFeatureRange[f][1]){
					conFeatureRange[f][1] = eachValue[f];
				}
			}
			productN++;
		}
					
	}

	return productN;
}

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

bool getRep(int* reps, int* productIds, int productN, int* clusterIds, int* clusterCounts, int conFeatureN, int& repW, 
				sql::Statement *stmt, sql::ResultSet *res, sql::ResultSet *res2, int clusterID, bool smallNFlag, int* mergedClusterIDs, int* mergedClusterIDInput, string productName, string* conFeatureNames){
					
					
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
		
						res = stmt->executeQuery(command);
						res->next();
						clusterIds[i] = res->getInt("id");
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
				
						clusterCounts[i] = 0;//res->rowsCount();
						reped = false;
		}
	}
	else{
		
	//where clusterID is 0 - on the first page- 
	//Finding the accepted clusters 
	if (clusterID ==0){
		
		command = "SELECT DISTINCT ";
		command += product_nodes;
		command += ".cluster_id, ";
		command += product_clusters;
		command += ".cluster_size, ";
		command += product_clusters;
		command +=".layer FROM ";
		command += product_nodes;
		command +=", ";
		command += product_clusters;
		command +=" WHERE (";
		command +=product_clusters;
		command += ".id=";
		command += product_nodes;
		command += ".cluster_id AND (product_id=";
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
	
	
	//If the user clicks on explore similar -- there is a parent_id
	
	else{ 
		
		command = "SELECT DISTINCT nodes.cluster_id, clusters.cluster_size, clusters.layer FROM nodes, clusters WHERE (clusters.id=nodes.cluster_id AND (clusters.parent_id=";
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
					return reped;
				}
			}	
	
	        int cId;
			while(res->next() && j<repW){
				if (clusterID == 0){
					cId= res->getInt("cluster_id");
				}
				else{
					cId= res->getInt("cluster_id");
				}				
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
									clusterIds[j] = cid;
									clusterCounts[j] = clusterCount;
									j++;
									childLeftN--;	
								}
							}	
						}
						if (childLeftN == cCount){
								reps[j] = preRep;
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
								command += "where ((cluster_id=";
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

	return reped;	
}

