#include <iostream>
#include "helpers.h"

//range(stmt, res, searchIds, conFeatureRange, conFeatureN, productName, conFeatureNames, bucketCount, bucketDiv);

void featureRange(sql::Statement *stmt, sql::ResultSet *res, int* searchIds, double** conFeatureRange, int productN, int conFeatureN, string productName, string* conFeatureNames, 
		double** bucketCount, int bucketDiv){
		
			string command ;	
			string capProductName = productName;
			capProductName[0] = capProductName[0] - 32;

			double** bucketRange = new double* [conFeatureN];
			double* bucketInterval = new double [conFeatureN];

			for (int f=0; f<conFeatureN; f++){
				bucketRange[f] = new double[2];
				for (int t=0; t<bucketDiv; t++){
					bucketCount[f][t] = 0; 
				}
			}
			conFeatureRange[0][0] = 100000000.0;
			conFeatureRange[0][1] = 0.0;
			command = "select price_min, price_max from db_properties where name=\'";
			command += capProductName;
			command += "\';";

			res = stmt->executeQuery(command);
	
			res->next();
			bucketRange[0][0] = res->getDouble("price_min");
			bucketRange[0][1] = res->getDouble("price_max");

			bucketInterval[0] = (bucketRange[0][1] - bucketRange[0][0]) / bucketDiv ;
			for(int f=1; f<conFeatureN; f++){
				conFeatureRange[f][0] = 100000000.0;
				conFeatureRange[f][1] = 0.0;
				command = "select min, max from db_features where name=\'";
				command +=  conFeatureNames[f];
				command += "\';";
				res = stmt->executeQuery(command);

				res->next();
				bucketRange[f][0] = res->getDouble("min");
				bucketRange[f][1] = res->getDouble("max");
				bucketInterval[f] = (bucketRange[f][1] - bucketRange[f][0]) / bucketDiv ;
			}

			command = "select price";
			for (int f=1; f<conFeatureN; f++){
				command += ", ";
				command += conFeatureNames[f];
		
			}	
			command += " from ";
			command += productName;
			command += "_nodes where (product_id=";
			ostringstream pidSt;
			pidSt << searchIds[0];
			command += pidSt.str();
			
			for (int i=0; i<productN; i++){
				command +=" OR product_id=";
				ostringstream pidSt2; 
				pidSt2 << searchIds[i];
				command += pidSt2.str();
			}
			command +=");";
		
			res = stmt->executeQuery(command);
		
				while(res->next()){

					double* eachValue = new double[conFeatureN];

					for (int f=0; f<conFeatureN; f++){
						eachValue[f] = res->getDouble(conFeatureNames[f]);
						for (int t=0; t<bucketDiv; t++){
							if ( (eachValue[f]<(bucketRange[f][0]+((t+1)*bucketInterval[f]))) && (eachValue[f]>=(bucketRange[f][0]+(t*bucketInterval[f]))) ){
								bucketCount[f][t]++;
							}
						}
						if (eachValue[f]<conFeatureRange[f][0]){
							conFeatureRange[f][0] = eachValue[f];
						}
						if (eachValue[f]>conFeatureRange[f][1]){
							conFeatureRange[f][1] = eachValue[f];
						}
					}
			
				}
				
}


int filter2(double **filteredRange, string* brands, int brandN, sql::Statement *stmt,
 sql::ResultSet *res, sql::ResultSet *res2, int* productIDs, bool* conFilteredFeatures, bool* catFilteredFeatures, bool* boolFilteredFeatures,
int clusterID, int clusterN, int conFeatureN, int boolFeatureN, double** conFeatureRange, bool* boolFeatures, string productName, string* conFeatureNames,string* boolFeatureNames, double** bucketCount, int bucketDiv) {


	int productN = 0;
	string command;
	string product_clusters = productName;
	product_clusters += "_clusters";
	string product_nodes = productName;
	product_nodes += "_nodes";
	string capProductName = productName;
	capProductName[0] = capProductName[0] - 32;
	
	double** bucketRange = new double* [conFeatureN];
	double* bucketInterval = new double [conFeatureN];
	
	for (int f=0; f<conFeatureN; f++){
		bucketRange[f] = new double[2];
		for (int t=0; t<bucketDiv; t++){
			bucketCount[f][t] = 0; 
		}
	}	
	
	conFeatureRange[0][0] = 100000000.0;
	conFeatureRange[0][1] = 0.0;
	command = "select price_min, price_max from db_properties where name=\'";
	command += capProductName;
	command += "\';";

	res = stmt->executeQuery(command);
	
	res->next();
	bucketRange[0][0] = res->getDouble("price_min");
	bucketRange[0][1] = res->getDouble("price_max");
		
	bucketInterval[0] = (bucketRange[0][1] - bucketRange[0][0]) / bucketDiv ;
	for(int f=1; f<conFeatureN; f++){
		conFeatureRange[f][0] = 100000000.0;
		conFeatureRange[f][1] = 0.0;
		command = "select min, max from db_features where name=\'";
		command +=  conFeatureNames[f];
		command += "\';";
		res = stmt->executeQuery(command);

		res->next();
		bucketRange[f][0] = res->getDouble("min");
		bucketRange[f][1] = res->getDouble("max");
		bucketInterval[f] = (bucketRange[f][1] - bucketRange[f][0]) / bucketDiv ;
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
		
	}	
	bool condition, condition2;

	int g;
	condition = 0;
	for (g=0 ; g<conFeatureN; g++){
		condition =  condition || conFilteredFeatures[g];
	}
//	for (g=0; g<catFeatureN; g++){
//		condition = condition || catFilteredFeatures[g];
//	}
//	for (g=0; g<boolFilteredFeatures; g++){
//		condition = condition || boolFilteredFeatures[g];
//	}	
	if (condition){
		command += " Where (";
	}
	for (int k=0; k<conFeatureN; k++){
		for (int g=k; g<conFeatureN; g++){
			condition =  condition || conFilteredFeatures[g];
		}	

		if (condition || catFilteredFeatures[0]){
	
			if (conFilteredFeatures[k]){
				command += " (";
				command += conFeatureNames[k];
				command += ">=";
				ostringstream minv;
				minv<<filteredRange[k][0];
				command += minv.str(); 
				command += " AND ";
				command += conFeatureNames[k];
				command += "<=";
				ostringstream maxv;
				maxv<<filteredRange[k][1];
				command += maxv.str();
				command += ")";
				condition2  = 0;
		
				for (int l=k+1; l<conFeatureN; l++){			
					condition2 = condition2 || conFilteredFeatures[l];
				}	 
				
				if (conFilteredFeatures[k] && (condition2 || catFilteredFeatures[0])){
					command += " AND ";
				}
			}
		}
	}

	if (!condition && catFilteredFeatures[0]){
			
		command += " WHERE (";
	}
			if(catFilteredFeatures[0]){
				command += "(";
				command += "brand =\'";
				command += brands[0];
				command += "\'"; 
				for (int b=1; b<brandN; b++){
					command += " OR brand=\'";
					command += brands[b];
					command += "\'";
				}
				command += ")";
			}
			
			condition2 = 0;
			for (int g=0 ; g<boolFeatureN; g++){
				condition2 =  condition2 || boolFilteredFeatures[g];
			}
		
			if (condition2){
				if (condition || catFilteredFeatures[0]){
					command += " AND";
				}
				else{
			
					command += " WHERE ("; 
				}
			}
			condition = 0;
			for (int k=0; k<boolFeatureN; k++){
				for (int g=k; g<boolFeatureN; g++){
					condition =  condition || boolFilteredFeatures[g];
				}	

				if (condition || boolFilteredFeatures[k]){
					if (boolFilteredFeatures[k]){
						command += " (";
						command += boolFeatureNames[k];
						command += "=";
						ostringstream minv;
						minv<<boolFeatures[k];
						command += minv.str(); 
						command += ")";
						condition2  = 0;

						for (int l=k+1; l<boolFeatureN; l++){			
							condition2 = condition2 || boolFilteredFeatures[l];
						}	 

						if (condition2){
							command += " AND ";
						}
					}
				}
			}	
			
			if (condition || condition2){
					command += ");";
				}	
		
	
		res = stmt->executeQuery(command);

		while(res->next()){
		
					productIDs[productN] = res->getInt("product_id");
					double* eachValue = new double[conFeatureN];

					for (int f=0; f<conFeatureN; f++){
						eachValue[f] = res->getDouble(conFeatureNames[f]);
						for (int t=0; t<bucketDiv; t++){
							if ( (eachValue[f]<(bucketRange[f][0]+((t+1)*bucketInterval[f]))) && (eachValue[f]>=(bucketRange[f][0]+(t*bucketInterval[f]))) ){
								bucketCount[f][t]++;
							}
						}
						if (eachValue[f]<conFeatureRange[f][0]){
							conFeatureRange[f][0] = eachValue[f];
						}
						if (eachValue[f]>conFeatureRange[f][1]){
							conFeatureRange[f][1] = eachValue[f];
						}
					}
			productN++;
		}
		
//	}
	return productN;

}

