#include "kmeans.h"
#include "kmeans_reza.h"
#include "qmeasures_reza.h"
#include "saveClustered.h"
#include "querries.h"


//map<string,int> brand2int;
//vector<double> mean, var;


//		maxSize = hClustering(layer, clusterN,  conFeatureN,  boolFeatureN, averag conFeatureRange, conFeatureRangeC, res, res2, resClus, resNodes, 
//				stmt, conFeatureNames, boolFeatureNames, productName, version, region, outlier_ids);
int hClustering(int layer, int max_k, int conFeatureN, int boolFeatureN, int catFeatureN, double *average, double** conFeatureRange, double*** conFeatureRangeC,
	sql::ResultSet *res, sql::ResultSet *res2, sql::ResultSet *resClus, sql::ResultSet *resNodes, sql::Statement *stmt, 
	string* conFeatureNames, string* boolFeatureNames, string* catFeatureNames, string productName, int version, string region, 
	vector<int> &outlier_ids){
		
			
	
int maxSize = -2;	
double **data, **dataN, **temp_dataN;
int *idA;
string *brands; 
int parent_id = 0;
int size, sized, cluster_id;
//double* weightSLR =  new double[conFeatureN+boolFeatureN];

//REZA /////////////////////////////////////////////////////////////////////////////////
static vector<double> mean, var; // this ststic since we do stanrdization based on the mu and var of the 'whole' data
static map<string,int> brand2int;
map<string,int>::iterator iter;
static double *weights;
int restart_num = 5;
int clusterN;
InitMethods method = INIT_KMEANSPP;
bool to_clip = true;
static vector<int> disc_domains;
///////////////////////////////////////////////////////////////////////////////////
int prodId = 0;

if 	(layer == 1){	

	     	sized = res->rowsCount();
				double **tdata = new double*[sized];			
		    for(int j=0; j<sized; j++) tdata[j] = new double[conFeatureN+boolFeatureN];  				
				brands = new string [sized];
				idA = new int[sized];	

				size = 0;
				while (res->next()) { 

						prodId = res->getInt("id");	
						readData(tdata[size], brands, size, prodId, resNodes, stmt, conFeatureNames, conFeatureN, boolFeatureNames, boolFeatureN, catFeatureNames, catFeatureN);
		 				idA[size] = prodId; 	
		 	        //	brands[size] = res->getString("brand");
						iter = brand2int.find(brands[size]); 
						if (iter == brand2int.end()) brand2int[brands[size]] = brand2int.size();
		 				for (int f=0; f<conFeatureN; f++) average[f] += tdata[size][f];
						size++;											
				}
				
				///////////////
				data = new double*[size];
		    for(int j=0; j<size; j++){
					data[j] = new double[conFeatureN+2*boolFeatureN+brand2int.size()];
					for (int d = 0; d < conFeatureN; d++)
						data[j][d] = tdata[j][d];
					for (int d = 0; d < boolFeatureN; d++) {
						data[j][conFeatureN+2*d] = tdata[j][conFeatureN+d]; data[j][conFeatureN+2*d+1] = 1 - tdata[j][conFeatureN+d];
					}						
					for (int d = conFeatureN+2*boolFeatureN; d < conFeatureN+2*boolFeatureN+brand2int.size(); d++)
						data[j][d] = 0;
					data[j][conFeatureN+2*boolFeatureN + brand2int[brands[j]]] = 1;		 
				}	
				
				///////////////  
				dataN = new double* [size];	
				for (int j=0; j<size; j++)
				{
				    dataN[j]= new double [conFeatureN+2*boolFeatureN+brand2int.size()];
			    }
				// data standardization
				get_mean_var(data, size, conFeatureN, mean, var);
				standarize_data(data, size, conFeatureN, 2*boolFeatureN+brand2int.size(), mean, var, dataN); //reza
        /////////////////////////////////////////
       // computing the weights
		
        weights = new double [conFeatureN+2*boolFeatureN+brand2int.size()];
        double z1 = 0;
        for (int ii = 0; ii < size; ii++)
           for (int d = 0; d < conFeatureN; d++) 
              z1 += dataN[ii][d] * dataN[ii][d];
        double z2 = 0;
        for (int ii = 0; ii < size; ii++)
           for (int d = 0; d < 2*boolFeatureN+brand2int.size(); d++)
              z2 += dataN[ii][conFeatureN+d] * dataN[ii][conFeatureN+d];
        if ((z2 == 0) || (z1 == 0)) z2 = z1 = 1;
        for (int d = 0; d < conFeatureN; d++) weights[d] = 1;
        for (int d = 0; d < 2*boolFeatureN+brand2int.size(); d++) weights[conFeatureN+d] = (conFeatureN*z1) / (z2 * (2*boolFeatureN+brand2int.size())*20);

	    for (int j = 0; j < boolFeatureN; j++) disc_domains.push_back(2);
        disc_domains.push_back(brand2int.size());
        ///////////////  
        // outlier detection
				int H = 20; // the number of bins between max_dist and min_dist
				double meps = .05; // the lowest allowable density			
        vector<int> non_out_index;
        double *temp_dataN[size];

        identify_outliers(non_out_index, temp_dataN, dataN, size, conFeatureN, H, meps);
        cout << " the number of outliers is " << size - non_out_index.size() << endl;
        int tcentersA[non_out_index.size()];
        clusterN = hartigan_qmeasure(temp_dataN, non_out_index.size(), conFeatureN, 2*boolFeatureN+brand2int.size(), max_k,
                                         method, restart_num, weights, to_clip, &disc_domains, tcentersA);
		int centersA[size];
        for (int i = 0; i < size; i++) 
           centersA[i] = clusterN;
        for(int i = 0; i < non_out_index.size(); i++) 
           centersA[non_out_index[i]] = tcentersA[i];
        // if (non_out_index.size() < size) clusterN++;
	

	    string temp_brands[non_out_index.size()]; 
	    int temp_idA[non_out_index.size()];
	    double *temp_data[size];
	    outlier_ids.clear();
	    bool temp_out[size];
	    for (int i = 0; i < size; i++)
	    	temp_out[i] = false;
	    for(int i = 0; i < non_out_index.size(); i++) 
	       temp_out[non_out_index[i]] = true;				
	    for (int i = 0, k = 0; i < size; i++)
	       if (temp_out[i] == false)
	          outlier_ids.push_back(idA[i]);
	       else {
	    	   temp_brands[k] = brands[i];
	    	   temp_idA[k] = idA[i]; 
	    	   temp_data[k++] = tdata[i];
	        }

	
        if (clusterN < 2) return maxSize; //it prevents going into infinite loop 
       ////////////////////////////////////////
			int **clusteredData = new int* [clusterN];
			int** clusteredDataOrderU = new int* [clusterN];
			int** clusteredDataOrder = new int* [clusterN];
			double ** dataCluster;
			for (int c=0; c<clusterN; c++) { 
				clusteredData[c] = new int[size+1];	
				clusteredDataOrderU[c] = new int [size+1];
				clusteredDataOrder[c] = new int[size+1]; 
			}	
			
			for (int c=0; c<clusterN; c++) clusteredData[c][0] = 0;
			for (int j=0; j<non_out_index.size(); j++)			 		
               clusteredData[tcentersA[j]][++clusteredData[tcentersA[j]][0]] = temp_idA[j];	
	
		  double* clusterUtilities = new double[clusterN];
	
		  for (int c=0; c<clusterN; c++) {
			   dataCluster = new double* [clusteredData[c][0]];
				 for (int j=0; j<clusteredData[c][0]; j++){
				 	 	dataCluster[j] = new double [conFeatureN+boolFeatureN]; 
				 		for (int f=0; f<conFeatureN; f++)
				 		   dataCluster[j][f] = temp_data[find(temp_idA, clusteredData[c][j+1], non_out_index.size())][f]; 
						clusteredDataOrder[c][j] = clusteredData[c][j+1];
				}  
		 clusterUtilities[c]=repOrder(stmt, res, productName, region, dataCluster, clusteredData[c][0], "utility", conFeatureN, boolFeatureN, clusteredDataOrder[c], weights);
        for (int j = 0; j < clusteredData[c][0]; j++) free(dataCluster[j]);

	  }


	clusterOrder(clusteredDataOrder, clusterN, clusterUtilities, clusteredDataOrderU);			
	saveClusteredData(temp_data, temp_idA, non_out_index.size(), temp_brands, parent_id, clusteredDataOrderU, layer, clusterN, conFeatureN, 
				   							boolFeatureN, conFeatureNames, boolFeatureNames, stmt, productName, version, region);

		
	   for (int c=0; c<clusterN; c++)
			if (clusteredData[c][0]>maxSize) maxSize = clusteredData[c][0];
	  for (int j = 0; j < sized; j++)  free(tdata[j]);
      for (int j = 0; j < size; j++) {
          free(data[j]); free(dataN[j]);
      }
      for (int j = 0; j < clusterN; j++) {
         free(clusteredData[j]); free(clusteredDataOrderU[j]);  free(clusteredDataOrder[j]); 
      }
      free(dataCluster); free(data); free(tdata); free(dataN); delete clusteredData;
	}
			
  if (layer > 1) {
	  // getting all cluster ids in this layer
	  string command = queryClusters(productName, region, version, layer-1);
	  resClus = stmt->executeQuery(command); 
	  
	  while(resClus->next()) {	    
		  parent_id = resClus->getInt("id");
		  command = "SELECT product_id FROM nodes WHERE product_type=\'";
		  command += productName;
		  command += "_";
		  command += region;
		
		  command += "\' AND version=";
		  ostringstream vstream;
		  vstream << version;
		  command += vstream.str();
		  command += " AND cluster_id=";
		  ostringstream cidStream;
		  ostringstream cluster_idStream;
		  cluster_id = resClus->getInt("id");
		  cluster_idStream<<cluster_id;
		  command += cluster_idStream.str();
		  command += ";";
		  resNodes = stmt->executeQuery(command); 
		  size = resNodes->rowsCount();
		  if (size <= 1) continue; 
	
			double **tdata = new double*[size];
			idA = new int [size];
			brands = new string [size];
			for (int j=0; j<size; j++){
				tdata[j] = new double[conFeatureN+boolFeatureN];
			}
			int s = 0;
	
			while(resNodes->next()) {
				prodId = resNodes->getInt("product_id");
				readData(tdata[s], brands, s, prodId, res, stmt, conFeatureNames, conFeatureN, boolFeatureNames, boolFeatureN, catFeatureNames, catFeatureN);
				idA[s] = prodId;
			//	brands[s] = resNodes->getString("brand");
			//	for (int f=0; f<conFeatureN; f++) average[f] += tdata[s][f];    
		        s++;	
				if (s == size) break;			
	    }
			data = new double*[size];
			for (int j=0; j<size; j++) {
				data[j] = new double[conFeatureN+2*boolFeatureN+brand2int.size()];
				for (int d = 0; d < conFeatureN; d++)
					data[j][d] = tdata[j][d];
				for (int d = 0; d < boolFeatureN; d++) {
					data[j][conFeatureN+2*d] = tdata[j][conFeatureN+d]; data[j][conFeatureN+2*d+1] = 1 - tdata[j][conFeatureN+d];
				}						
				for (int d = conFeatureN+2*boolFeatureN; d < conFeatureN+2*boolFeatureN+brand2int.size(); d++)
					data[j][d] = 0;
				data[j][conFeatureN+2*boolFeatureN + brand2int[brands[j]]] = 1;	
			}	 
      dataN = new double*[size];
 	   	for(int j=0; j<size; j++)
 	   				dataN[j] = new double[conFeatureN+2*boolFeatureN+brand2int.size()]; 	
			
      standarize_data(data, size, conFeatureN, 2*boolFeatureN+brand2int.size(), mean, var, dataN); 

			int	centersA[size];	
			clusterN = hartigan_qmeasure(dataN, size, conFeatureN, 2*boolFeatureN+brand2int.size(), max_k, method, 
                                   restart_num, weights, to_clip, &disc_domains,centersA); //reza

  
			if (clusterN < 2) continue; //it prevents going into infinite loop

	        double **dist = new double* [size];
			for(int j=0; j<size; j++) 	dist[j] = new double[clusterN]; 	
			////////////////////////////////  Change clusteredData to vector 
		  int **clusteredData = new int* [clusterN];
			for (int j=0; j<clusterN; j++)	clusteredData[j] = new int[size+1];
	   	for (int c=0; c<clusterN; c++)	clusteredData[c][0] = 0;
			for (int j=0; j<size; j++)
			 		clusteredData[centersA[j]][++clusteredData[centersA[j]][0]] = idA[j];
		  int** clusteredDataOrder = new int* [clusterN];
			int** clusteredDataOrderU = new int* [clusterN];
			double ** dataCluster;
			for (int c=0; c<clusterN; c++){
					clusteredDataOrder[c] = new int[size+1]; 
					clusteredDataOrderU[c] = new int[size+1];
					for (int j=0; j<clusteredData[c][0]; j++) 
              clusteredDataOrder[c][j] = clusteredData[c][j+1];
		}

	       double* clusterUtilities = new double[clusterN];
	
			for (int c=0; c<clusterN; c++) {
			  	dataCluster = new double* [clusteredData[c][0]];
			   	for (int j=0; j<clusteredData[c][0]; j++){
			   		 dataCluster[j] = new double [conFeatureN+boolFeatureN]; 
			   		 for (int f=0; f<conFeatureN; f++)
                dataCluster[j][f] = tdata[find(idA, clusteredData[c][j+1], size)][f]; 
                }
			   clusterUtilities[c]=repOrder(stmt, res, productName, region, dataCluster, clusteredData[c][0], "utility", conFeatureN, boolFeatureN, clusteredDataOrder[c], weights);
               for (int j = 0; j < clusteredData[c][0]; j++) free(dataCluster[j]);
               free(dataCluster);
	    	}
 

		  clusterOrder(clusteredDataOrder, clusterN, clusterUtilities, clusteredDataOrderU);


		  saveClusteredData(tdata, idA, size, brands, parent_id,clusteredDataOrderU, layer, clusterN, conFeatureN, 
			       				boolFeatureN, conFeatureNames, boolFeatureNames, stmt, productName, version, region);

		  for (int c=0; c<clusterN; c++)
			 if (clusteredData[c][0]>maxSize) maxSize = clusteredData[c][0];
         for (int j = 0; j < clusterN; j++) {
             free(clusteredDataOrder[j]); free(clusteredDataOrderU[j]); free(clusteredData[j]);
         }
        free(clusteredDataOrder); free(clusteredDataOrderU); free(clusteredData); 
   
        for (int j = 0; j < size; j++) {
           free(tdata[j]); free(data[j]); free(dataN[j]); free(dist[j]);
        }
	   free(data); free(tdata); free(dataN);free(dist); 
     }
  }	
  return maxSize;

}
