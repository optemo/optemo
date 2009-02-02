//#ifndef _EXAMPLES_H
//#define	_EXAMPLES_H
//
//// Portable __FUNCTION__
//#ifndef __FUNCTION__
// #ifdef __func__
//   #define __FUNCTION__ __func__
// #else
//   #define __FUNCTION__ "(function n/a)"
// #endif
//#endif
//
//#ifndef __LINE__
//  #define __LINE__ "(line number n/a)"
//#endif 

int find(int *idA, int value, int size){
		
	int ind = -1;
	for(int i=0; i<size; i++){
		if (idA[i] == value){
			ind = i;
			return ind;
		}
	}
	
	return ind;  
}


int find2(int *idA, int value, int size, int order){
		
	int ind = -1;
	int o = 0;
	for(int i=0; i<size; i++){
		if (idA[i] == value){
			o++;
			if (o = order){
				ind = i;
				return ind;
			}
		}
	}
	
	return ind;  
}


int findVec(vector<string> tokens, string value)
{
	int ind = -1;
	for (int i=0; i<tokens.size(); i++){
		if (tokens.at(i) == value){
			ind = i;
			return ind;
		}
	}
	return ind;
}

//save2File(fileName, data, clusteredData, centersA, brands, idA, sane, conFeatureN, clusterN, row)

void save2File (string filename, double **array1, int **array2, int *array3, string* array5, int *array4, int size, int F, int C, int R){
	ofstream myfile;
	int x, y;
	myfile.open(filename.c_str(), ios::out);
	
	myfile<<size;
	myfile<<" ";
    myfile<<F;
    myfile<<" ";
	myfile<<C;
	myfile<< " ";
	myfile<<R;
	myfile<<" ";
	for( y=0; y<F; y++){
		for ( x=0; x<size; x++){
			myfile<<array1[x][y];
			myfile<<" ";
		}
	}
	for(y=0; y<size; y++){
		for (x=0; x<C; x++){
			myfile<<array2[x][y];
			myfile<<" ";
		}
	}
	
	for(x = 0; x<size; x++){
		myfile<<array3[x];
		myfile<<" ";
	}
	
	for(x = 0; x<R; x++){
		myfile<<array4[x];
		myfile<<" ";
	}
	for(x = 0; x<size; x++){
		myfile<<array5[x];
		myfile<<" ";
	}
	myfile.close();
}

//(fileName, dataN, clusteredData, centersA, idA, sane, featureN, clusterN, row);

int* loadNumbers(string filename){
	ifstream myfile;
	myfile.open(filename.c_str(), ios::in);
	int *sizes = new int[4];
	myfile >> sizes[0];
	myfile >> sizes[1];
	myfile >> sizes[2];
	myfile >> sizes[3];
	myfile.close();
	return sizes;
} 


void loadFile(string filename, double **array1, int **array2, int *array3, string *array5, int *array4){
	ifstream myfile;
	myfile.open(filename.c_str(), ios::in);
	int x, y, size, F, C, R;
	myfile >> size;
	myfile >> F;
	myfile >> C;
	myfile >> R;
	for( y=0; y<F; y++){
		for ( x=0; x<size; x++){
			myfile>>array1[x][y];
		}
	}
	for(y=0; y<size; y++){
		for (x=0; x<C; x++){
			myfile>>array2[x][y];
		}
	}
	
	for(x = 0; x<size; x++){
		myfile>>array3[x];
	}
	
	for(x = 0; x<R; x++){
		myfile>>array4[x];
	}
	for(x = 0; x<size; x++){
		myfile>>array5[x];
	}
	myfile.close();
	
}

void getRange(double** data, int size, int conFeatureN, double** conFeatureRange){
		
	 	double *dif = new double[conFeatureN];
		for(int f=0; f<conFeatureN; f++){	
  	         conFeatureRange[f][1] = data[0][1]; 
             conFeatureRange[f][0] = data[0][1]; 
		}
        

/////
	
		for (int f=0; f<conFeatureN; f++){
      		for(int j = 1; j<size; j++){
					if(data[j][f] > conFeatureRange[f][1]){
                		conFeatureRange[f][1] = data[j][f];
	           		}
		       		if (data[j][f] < conFeatureRange[f][0]){
			   			conFeatureRange[f][0] = data[j][f];
		   			}
			}
		}
}


void getStatisticsData(double** data, int** indicators, double* average, int size, int conFeatureN, double** conFeatureRange, double** dataN){
		
			
	   for (int j=0; j<conFeatureN; j++){
			average[j] = average[j]/size;
		}
		
				
	  	
	 	double *dif = new double[conFeatureN];
	
		for(int f=0; f<conFeatureN; f++){	
  	         conFeatureRange[f][1] = data[0][1]; 
             conFeatureRange[f][0] = data[0][1]; 
		}
        

/////
	
		for (int f=0; f<conFeatureN; f++){
      		for(int j = 1; j<size; j++){
					if(data[j][f] > conFeatureRange[f][1]){
                		conFeatureRange[f][1] = data[j][f];
	           		}
		       		if (data[j][f] < conFeatureRange[f][0]){
			   			conFeatureRange[f][0] = data[j][f];
		   			}
			}
		}
			
			
	//	for (c=0; c<clusterN; c++){
	//		for (int f=0; f<conFeatureN; f++){
	//			//	tresh = min(difMax, difMin) / 2;
	//			for (int j=0; j<size; j++){
	//			
	//				if (data[j][f] > (average[f] + tresh)){    // high 
	//		   		indicators[f][j] = 1;
	//		    }
	//		    else if(data[j][f] < (average[f] - tresh)){ // low
	//		   		indicators[f][j] = -1;
	//			}  
	//			else{  //average
//	//				indicators[f][j] = 0;
//	//			}
//	//		}		
//	//	}	
		for (int f=0; f<conFeatureN; f++){
			dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
		}
		for (int f=0; f<conFeatureN; f++){
		   for(int j=0; j<size; j++){
			if (dif[f] == 0){
				dataN[j][f] = 0;
			}
			else{
		    	dataN[j][f] = (((data[j][f] - conFeatureRange[f][0])/ dif[f]) * 2 ) - 1;
		   	}
	}  }
  	}



	void getStatisticsClusteredData(double** data, int** clusteredData, int** indicators, double* average, int* idA, int size, int clusterN, int conFeatureN, double*** conFeatureRange){


		int ind = 0;
			
		for (int j=0; j<conFeatureN; j++){
			average[j] = average[j]/size;
		}
	
			for (int c=0; c<clusterN; c++){
				ind = find(idA, clusteredData[c][1], size);
				for(int f=0; f<conFeatureN; f++){	
	  	          conFeatureRange[c][f][1] = data[ind][f]; 
	              conFeatureRange[c][f][0] = data[ind][f]; 
				}
	        } 

	/////
			//	cout<<"in stat"<<endl;
			for (int c=0; c<clusterN; c++){
				for (int f=0; f<conFeatureN; f++){
		      		for(int j = 0; j<clusteredData[c][0]; j++){
			
						ind = find(idA, clusteredData[c][j+1], size);
						
						if(data[ind][f] > conFeatureRange[c][f][1]){
		                	conFeatureRange[c][f][1] = data[ind][f];
		           		}
			       		if (data[ind][f] < conFeatureRange[c][f][0]){
				   			conFeatureRange[c][f][0] = data[ind][f];
				   		}
					}
				 }
			}			
	  	}

//saveClusteredData(data, idA, size, brands, parent_id,clusteredData, conFeatureRangeC, layer, clusterN, conFeatureN, stmt, res2);
void saveClusteredData(double ** data, int* idA, int size, string* brands, int parent_id, int** clusteredData, double*** conFeatureRange, int layer, int clusterN, int conFeatureN, sql::Statement *stmt, sql::ResultSet *res2){
///Saving to DataBase	
	ostringstream layerStream; 
	layerStream<<layer;
    ostringstream parent_idStream;
	parent_idStream<<parent_id;
	int cluster_id;
	for (int c=0; c<clusterN; c++){
		ostringstream nodeStream;
		ostringstream cluster_idStream; 
		
		ostringstream clusterSizeStream;
		clusterSizeStream<<clusteredData[c][0];
		string command = "INSERT INTO clusters (layer, parent_id, cluster_size,price_min, price_max, displaysize_min,displaysize_max,  opticalzoom_min, opticalzoom_max, maximumresolution_min, maximumresolution_max ) values (";
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
			command = "INSERT INTO nodes (cluster_id, camera_id, price, displaysize, opticalzoom, maximumresolution, brand) values(";
			ostringstream cluster_idStream;
			cluster_idStream<<cluster_id;
			command += cluster_idStream.str();
			command += ", ";
			ostringstream idStream;
			idStream<<clusteredData[c][j+1];
			command +=  idStream.str();	
			for (int f=0; f<conFeatureN; f++){
				command +=", ";
				ostringstream featureStream;
			//	cout<<"j is "<<j<<" and idA[j] is "<<idA[j]<<"  and data[j][f] is  "<<data[j][f]<<endl;
			//	cout<<"finds"<<endl;
		//		cout<<"id is"<<clusteredData[c][j+1]<<"  and index is "<<find(idA, clusteredData[c][j+1], size)<<endl;
				featureStream<<data[find(idA, clusteredData[c][j+1], size)][f];
				
				command += featureStream.str();
			}
	        command +=", \"";
			ostringstream featureStream;
				
			featureStream<<brands[find(idA, clusteredData[c][j+1], size)];
			command += featureStream.str();   
			command +="\");"; 
			stmt->execute(command);
	 }
	}
	
}	



void insertion_sort(double* xOri, int* ids, int length)
{
 int key,i, idKey;
double* x = new double [length];
for (int j=0; j<length; j++){
	x[j] = xOri[j];
}
  
  for(int j=1;j<length;j++)
  {
     key=x[j];
	 idKey = ids[j];	
     i=j-1;

     while(x[i]>key && i>=0)
     {
         x[i+1]=x[i];
		 ids[i+1] = ids[i];	
         i--;
     }
     x[i+1] = key;
	ids[i+1] = idKey;
  }
delete x;

}


void sort(double** data, int* idA, int** sortedA, int size, int conFeatureN){
	
	double** dataT = new double* [conFeatureN];
	
	for (int f=0; f<conFeatureN; f++){
	dataT[f] = new double [size];

		for (int j=0; j<size; j++){
			dataT[f][j] = data[j][f];
			sortedA[f][j] = idA[j];
		}
		
		insertion_sort(dataT[f], sortedA[f], size);
		
	}
}


void getIndicators(double** data, int* idA, int** sortedA, int size, int conFeatureN, int** indicators){
	
	int quarter = size/4;
	
	for (int f=0; f<conFeatureN; f++){
		for(int j=0; j<size; j++){
		   if (data[j][f] > data[find(idA, sortedA[f][size-quarter], size)][f]) {//high
			indicators[f][j] = 1;
			}
			else if (data[j][f] < data[find(idA, sortedA[f][quarter], size)][f]) { //low
				indicators[f][j] = -1;
				}
			else{
				indicators[f][j] = 0;
			}	
		}
	}	  
}


// 	getIndicators2(accpetedCN, clusteID, stmt, res, indicators);


void getIndicators2(int cameraN, int* cameraIDs, sql::Statement *stmt, sql::ResultSet *res, int** indicators, double** data) //                  double** data, int** sortedA, int size, int conFeatureN, int** indicators){
{
	//getIndicators(double** data, int** sortedA, int size, int conFeatureN, int** indicators)
		
	string command = "";
	for (int j=0; j<cameraN-1; j++){
		command += "(SELECT price, displaysize, opticalzoom, maximumresolution, camera_id from nodes where camera_id=";
		ostringstream idStream; 
		idStream << cameraIDs[j];
		command += idStream.str();
		command += ")";
		command += " UNION ";
	}

	command += "(SELECT price, displaysize, opticalzoom, maximumresolution, camera_id from nodes where camera_id=";
	ostringstream idStream;
	idStream<<cameraIDs[cameraN-1];
	command += idStream.str();
	command += ")";
	command += ";";
	
	res = stmt->executeQuery(command);
	int j=0;
	int size = res->rowsCount();
	int* idA = new int[size];
	while(res->next()){
		data[j][0] = res->getInt("price");
		data[j][1] = res->getDouble("displaysize");
		data[j][2] = res->getDouble("opticalzoom");
		data[j][3] = res->getDouble("maximumresolution");
		idA[j] = res->getInt("camera_id");
		j++;
	}
		int conFeatureN =4;
	int** sortedA = new int* [conFeatureN];
	for (int f =0; f<conFeatureN; f++) {
		sortedA[f] = new int[cameraN];
	}
		
	//void sort(double** data, int* idA, int** sortedA, int size, int conFeatureN){

	sort(data, cameraIDs,sortedA,cameraN,conFeatureN);
		
//void getIndicators(double** data, int** sortedA, int size, int conFeatureN, int** indicators){	
	
	getIndicators(data, idA, sortedA, cameraN, conFeatureN,indicators);

	}


//vector<int> clusterChildrenV;	
//clusterChildrenN = size(getChildrenV(clusterID, clusterChildrenV, stmt, res, clusterSize, clusterN));
//
//for (int j=0; j<clusterChildrenN; j++){
//	clusterChildren[j] = clusterChildrenV.at(j);
//}
int getChildren(int parent_id, vector<int>* clusterChildren,sql::Statement *stmt, sql::ResultSet *res, int clusterN, int clusterSize){
	int clusterChildrenN = 0;
	string command;
	if(clusterSize>clusterN){
		command = "(SELECT id, cluster_size FROM clusters WHERE parent_id=";
		ostringstream clusterIDStream;
		clusterIDStream<<parent_id;
		command += clusterIDStream.str();
		command += ");";
		res = stmt->executeQuery(command);
		while(res->next()){
			clusterSize = res->getInt("cluster_size");
			parent_id = res->getInt("id");

			clusterChildrenN += getChildren(parent_id, clusterChildren, stmt, res, clusterN, clusterSize); 
		}
	}
	else{
		
		clusterChildrenN++;
	}
	return clusterChildrenN; 	
}



vector<int> getChildren(int parent_id, vector<int> clusterChildren,sql::Statement *stmt, sql::ResultSet *res, int clusterN, int clusterSize){
	//int clusterChildrenN = 0;
	int sizeIt;
	string command;
	if(clusterSize>clusterN){
		command = "(SELECT id, cluster_size FROM clusters WHERE parent_id=";
		ostringstream clusterIDStream;
		clusterIDStream<<parent_id;
		command += clusterIDStream.str();
		command += ");";
	//	cout<<"command in children is "<<command<<endl;
		res = stmt->executeQuery(command);
		while(res->next()){
			clusterSize = res->getInt("cluster_size");
			parent_id = res->getInt("id");
		//	cout<<"parent_id is  "<<parent_id<<endl;
			clusterChildren.push_back(parent_id);
		 //   sizeIt = getChildren(parent_id, clusterChildren, stmt, res, clusterN, clusterSize).size();
		//	cout<<"sizeIt is "<<sizeIt<<endl;
			//for (int j=0; j<sizeIt; j++){
				clusterChildren = getChildren(parent_id, clusterChildren, stmt, res, clusterN, clusterSize);
			//} 
		}
	}
	//else{
		
		//;
	//}
//	cout<<"clusterChildrenN  is  "<<clusterChildren.size()<<endl;
	return clusterChildren; 	
}


//filterCluster(clusterIDs, clusterID, cameraIDs, cameraN, stmt, res);

int filterCluster(int *clusterIDs, int clusterID, int* cameraIDs, int cameraN, sql::Statement *stmt, sql::ResultSet *res, int clusterN){
	
	int acceptedCN = 0;
	int clusterChildrenN = 0;
	int clusterSize = 0;
	string command;
	
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
			if (clusterID>0){
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
		}
		return acceptedCN;
}

int filter(double **filteredRange, string brand,sql::Statement *stmt,
 sql::ResultSet *res, sql::ResultSet *res2, int* cameraIDs, bool* conFilteredFeatures, bool* catFilteredFeatures, int clusterID, int clusterN) {

	int cameraN = 0; ////???
	int cameraNC = 0;
	int c=0;
	
	
	
	string command = "SELECT cluster_size from clusters where id=";
	ostringstream cluster_idStream; 
	cluster_idStream<<clusterID;
	command += cluster_idStream.str();
	command += ";";

	res= stmt->executeQuery(command); 

	res->next();
	
	int clusterSize = res->getInt("cluster_size");

	int* clusterChildren = new int[clusterSize];
	
	
	vector<int> clusterChildrenV;

	
	clusterChildrenV = getChildren(clusterID, clusterChildrenV, stmt, res, clusterN, clusterSize);
	int clusterChildrenN = clusterChildrenV.size();

	for (int j=0; j<clusterChildrenN; j++){
		clusterChildren[j] = clusterChildrenV.at(j);
	}
	

	int cluster_id;
	int cSize = clusterChildrenN; //res->rowsCount();
	int counter = 0;
	int i=0;
	command = "";
	for(int j=0; j<clusterChildrenN-1; j++){
		
		cluster_id = clusterChildren[j];
		command += "(SELECT camera_id FROM nodes WHERE cluster_id=";
		ostringstream cluster_idStream;
		cluster_idStream << cluster_id;         
		command += cluster_idStream.str();
	if (conFilteredFeatures[0]){	
		command += " AND (price>=";
		ostringstream priceMin;
		priceMin<<filteredRange[0][0];
		command += priceMin.str();
		command +=" AND price<=";
		ostringstream priceMax;
		priceMax<<filteredRange[0][1];
		command += priceMax.str();
	}
	
	if (conFilteredFeatures[1]){		
		command +=" AND displaysize>=";
		stringstream displaysizeMin;
		displaysizeMin<<filteredRange[1][0];
		command += displaysizeMin.str();
		command +=" AND displaysize<=";
		ostringstream displaysizeMax;
		displaysizeMax<<filteredRange[1][1];
		command += displaysizeMax.str();
	}
	
	if (conFilteredFeatures[2]){		
		command +=" AND opticalzoom>=";
		stringstream opticalzoomMin;
		opticalzoomMin<<filteredRange[2][0];
		command += opticalzoomMin.str();
		command +=" AND opticalzoom<=";
		ostringstream opticalzoomMax;
		opticalzoomMax<<filteredRange[2][1];
		command += opticalzoomMax.str();
	}
	
	if (conFilteredFeatures[3]){		
		command +=" AND maximumresolution>=";
		stringstream maximumresolutionMin;	
		maximumresolutionMin<<filteredRange[3][0];
		command += maximumresolutionMin.str();
		command +=" AND maximumresolution<=";
		ostringstream maximumresolutionMax;
		maximumresolutionMax<<filteredRange[3][1];
		command += maximumresolutionMax.str();
	}
	
	if (catFilteredFeatures[0]){		
		command +=" AND brand=";	
		command += brand;	
	}
	
	
		command += ") UNION ";
	}
	
	/////////////////////////////////////STUPID
		cluster_id = clusterChildren[clusterChildrenN-1];
		command += "(SELECT camera_id FROM nodes WHERE cluster_id=";
		ostringstream cluster_idStream2;
		cluster_idStream2 << cluster_id;         
		command += cluster_idStream2.str();
	if (conFilteredFeatures[0]){	
		command += " AND (price>=";
		ostringstream priceMin;
		priceMin<<filteredRange[0][0];
		command += priceMin.str();
		command +=" AND price<=";
		ostringstream priceMax;
		priceMax<<filteredRange[0][1];
		command += priceMax.str();
	}
	
	if (conFilteredFeatures[1]){		
		command +=" AND displaysize>=";
		stringstream displaysizeMin;
		displaysizeMin<<filteredRange[1][0];
		command += displaysizeMin.str();
		command +=" AND displaysize<=";
		ostringstream displaysizeMax;
		displaysizeMax<<filteredRange[1][1];
		command += displaysizeMax.str();
	}
	
	if (conFilteredFeatures[2]){		
		command +=" AND opticalzoom>=";
		stringstream opticalzoomMin;
		opticalzoomMin<<filteredRange[2][0];
		command += opticalzoomMin.str();
		command +=" AND opticalzoom<=";
		ostringstream opticalzoomMax;
		opticalzoomMax<<filteredRange[2][1];
		command += opticalzoomMax.str();
	}
	
	if (conFilteredFeatures[3]){		
		command +=" AND maximumresolution>=";
		stringstream maximumresolutionMin;	
		maximumresolutionMin<<filteredRange[3][0];
		command += maximumresolutionMin.str();
		command +=" AND maximumresolution<=";
		ostringstream maximumresolutionMax;
		maximumresolutionMax<<filteredRange[3][1];
		command += maximumresolutionMax.str();
	}
	

	if (catFilteredFeatures[0]){		
		command +=" AND brand=";	
		command += brand;	
	}
		command += ");";
	
		res2 = stmt->executeQuery(command);

//		int id;
		while(res2->next()){
			cameraIDs[i] = res2->getInt("camera_id");
			i++;
			cameraN++;
		}

	return cameraN; 
}

//////


void median(double** data, int size, int conFeatureN, int* sortedA){

	double* distan = new double[size];
	for (int j=0; j<size; j++){
	    distan[j] = 0;
		for (int i=0; i<size; i++){
			for (int f=0; f<conFeatureN; f++){
				distan[j] += (data[j][f] - data[i][f]) *  (data[j][f] - data[i][f]);
		   }
		}	
	}
	
	insertion_sort(distan, sortedA, size);
}

//given the data of a cluster and filtered cameras would give the cluster rep
int getRepC (double** clusterData, int size, int conFeatureN, int* idA, int* cameraIds, int cameraN, int order){
	int ind;
	int rep = 0;
	int* sortedA = new int[size];
		
	for (int j=0; j<size; j++){
		sortedA[j] = idA[j];
	}
	//median or more soffisticated things
	median(clusterData, size, conFeatureN, sortedA);
	ind = find(cameraIds,sortedA[order], cameraN);
	if(ind>-1){
		rep=cameraIds[ind]; 
   }	
	return rep;
}


//gives all the reps (int* reps)
bool getRep(int* reps, int* repClusters, int* cameraIds, int* clusterIds, int cameraIDN, int conFeatureN, int acceptedClusterN, int repW, sql::Statement *stmt, sql::ResultSet *res){
//	filter(double **filteredRange, string brand, int layer,sql::Statement *stmt,
//	 sql::ResultSet *res, sql::ResultSet *res2, int* cameraIDs, bool* conFilteredFeatures, bool* catFilteredFeatures)
	int rep;
	int c=0;
	int r=0;
	int size, j;
	double** clusterData; 
	int* idA;
	int* cIdA;
	if (repW>cameraIDN){
			return false;
	}
	else {
		string command;
		while((r<repW) && (c<acceptedClusterN) && (r<acceptedClusterN)){
			
			command = "SELECT * from nodes where ";	
			command += "cluster_id=";
			ostringstream cluster_idStream;
			cluster_idStream<<clusterIds[c];
			command += cluster_idStream.str();
			command += ";";
			res = stmt->executeQuery(command);
			size = res->rowsCount();
		
			if (size>0){
				clusterData = new double* [size];
				idA = new int[size];
				cIdA = new int [size];
				j=0;
				while(res->next()){
					clusterData[j] = new double [conFeatureN];
					clusterData[j][0] = res->getInt("price");
					clusterData[j][1] = res->getDouble("displaysize");
					clusterData[j][2] = res->getDouble("opticalzoom");
					clusterData[j][3] = res->getDouble("maximumresolution");
					idA[j] = res->getInt("camera_id");
					cIdA[j] = res->getInt("cluster_id");
					j++;
				}
					rep = getRepC(clusterData, size, conFeatureN, idA, cameraIds, cameraIDN,1);
					if (rep>0){
						reps[r] = rep;
						command = "SELECT cluster_id from nodes where camera_id=";
						ostringstream repStream;
						repStream<<rep;
						command += repStream.str();
						res= stmt->executeQuery(command);
						res->next();
						repClusters[r] = res->getInt("cluster_id");
						r++;
					}
		}
		c++;
	  }

		if(repW>r){
			int left = repW - r;
		    j=0; 
		    c = -1;
			int o;
			o = 2;
			while ((r<left) && (c<acceptedClusterN)){
			    command = "SELECT * from nodes where ";	
				command += "cluster_id=";
				ostringstream cluster_idStream;
				cluster_idStream<<clusterIds[c];
				command += cluster_idStream.str();
				command += ";";
				res = stmt->executeQuery(command);
				size = res->rowsCount();
			    if(size>0){
				clusterData = new double* [size];
				idA = new int[size];
				j=0;
				while(res->next()){
						clusterData[j] = new double [conFeatureN];
						clusterData[j][0] = res->getInt("price");
						clusterData[j][1] = res->getDouble("displaysize");
						clusterData[j][2] = res->getDouble("opticalzoom");
						clusterData[j][3] = res->getDouble("maximumresolution");
						idA[j] = res->getInt("camera_id");
						repClusters[j] = res->getInt("cluster_id");
						j++;
				}
			
				rep = getRepC(clusterData, size, conFeatureN, idA, cameraIds, cameraIDN, o);
		//			<<"rep is "<<rep<<endl;
				int t= 0;
				while ((rep=0) && (t<size)){
					o++;
					rep  = getRepC(clusterData, size, conFeatureN, idA, cameraIds, cameraIDN,  o);
					t++;
				}
			
				if (rep>0){
					
					reps[r] = rep;
					command = "SELECT cluster_id from nodes where camera_id=";
					ostringstream repStream;
					repStream<<rep;
					command += repStream.str();
					res= stmt->executeQuery(command);
					res->next();
					repClusters[r] = res->getInt("cluster_id");
					r++;
				}	
	
				    j++;
					c++;
				}
			
			else{
				o = 2;
				c++;
			}
							
		}
		}
		return true;	
	}
	
}

//#endif	/* _EXAMPLES_H */

