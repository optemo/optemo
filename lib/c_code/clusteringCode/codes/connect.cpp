
// Standard C++ includes
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <assert.h>
#include <float.h>
#include <math.h>
#include <vector>
#include <string>
#include <algorithm>
using namespace std;


// Public interface of the MySQL Connector/C++
#include <cppconn/mysql_public_iface.h>
// Connection parameter and sample data
#include "examples.h"

using namespace std;

/**
* Usage example for Driver Manager, Connection, (simple) Statement, ResultSet
*/
int main(int argc, char** argv) {
	
	int row;
	stringstream sql;
	int sane , affected_rows, size;
	int clusterN = 9; 
	int featureN = 4;   
	int range = 2;
    int inputID;
		
	string *catFeatureNames;
	bool *boolFeatureNames;
	string *conFeatureNames = new string[featureN];
	
	conFeatureNames[0]="listpriceint";
	conFeatureNames[1]="displaysize";  
    conFeatureNames[2]="opticalzoom";
    conFeatureNames[3]="maximumresolution";
	bool *filteredFeatures = new bool[featureN+1];   //brand
	for(int f=0; f<featureN+1; f++){
		filteredFeatures[f] = 0;
	}  

	int **conFeatureRange = new int* [featureN];
	for (int f=0; f<featureN; f++){
		conFeatureRange[f] = new int[range];
	}      
	//Intitializing:
	for(int f=0; f<featureN; f++){
			conFeatureRange[f][0] = -1000;
			conFeatureRange[f][1] = 1000000;
		}
    
	int layer;
    string option;
	
	
	//Different values of option: 
	
	// ./connect [-l layerNumber inputID] []
	
	// The original clustering (returning 9 IDs)

//   if (!strcmp(argv[1], "-l")){
//	 layer = atoi(argv[2]);
//	inputID = atoi(argv[3]);
//	}   
//     
//	int a = 4;
//	
//	while(a<argc){
//		for (int f=0; f<featureN; f++){
//			option = "-";
//			option += conFeatureNames[f] ;
//		   if(!option.compare(argv[a])){
//			filteredFeatures[f] = 1;
//			 for (int r=0; r<range; r++){
//				a++;
//			  	conFeatureRange[f][r] = atoi(argv[a]);
//			 }	 
//		   }
//		}a++;	  
//	}


//--- !map:HashWithIndifferentAccess \nbrand: Canon Cameras US\nmaximumresolution_min: 0.21\nids: 0\ndisplaysize_min: 0.23\nprice_max: 0.8\nopticalzoom_max: 0.8\nlayer: 1\nmaximumresolution_max: 0.8\nprice_min: 0.22\ndisplaysize_max: 0.8\nopticalzoom_min: 0.21\n

 //   string varNames = new string[100];
 //   varNames[0] = "layer";
 //   varNames[1] = "ids";
 //   varNames[2] = "brand";
 //   varNames[3] = "price";
 //   varNames[4] = "displaysize_min";
 //   varNames[5] = "displaysize_max";
 //   varNames[6] = "opticalzoom_min";
 //   varNames[7] = "opticalzoom_max";
 //   varNames[8] = "maximumresolution_min";
 //   varNames[9] = "maximumresolution_max";
 //   int varN = 10;
	
	

	string argu = argv[1];
	int ind;
	string var;

	//layer
	var = "layer";
	ind = argu.find("layer", 0);
	int endit = argu.find("\n", ind);
	int startit = ind + var.length() + 2;
	int lengthit = endit - startit;
	//cout<<"brand is :  BBB"<<argu.substr(startit, lengthit)<<"BBB"<<endl;
	layer = atoi((argu.substr(startit, lengthit)).c_str());
	
	//ids
	var = "ids";
	ind = argu.find("ids", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	inputID = atoi((argu.substr(startit, lengthit)).c_str());
	
    //brand
	var = "brand";
    ind = argu.find("brand", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	string brand = (argu.substr(startit, lengthit)).c_str();
	if (brand != ""){
		filteredFeatures[4] = 1;
	}
   	
	//price_min
	var = "price_min"; 
	ind = argu.find("price_min", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit > 0){
		
		conFeatureRange[0][0] = atoi((argu.substr(startit, lengthit)).c_str()) * 100;
        filteredFeatures[0] = 1;
}
	
	//price_max 
	var = "price_max";
	ind = argu.find("price_max", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit > 0){
		conFeatureRange[0][1] = atoi((argu.substr(startit, lengthit)).c_str())* 100;
	     filteredFeatures[0] = 1;
	}

	//displaysize_min
	var = "displaysize_min";
	ind = argu.find("displaysize_min", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit >0){
		conFeatureRange[1][0] = atoi((argu.substr(startit, lengthit)).c_str());
		filteredFeatures[1] = 1;
    }		
	
	//displaysize_max
	var = "displaysize_max";
	ind = argu.find("displaysize_max", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit >0){
		conFeatureRange[1][1] = atoi((argu.substr(startit, lengthit)).c_str());
		filteredFeatures[1] = 1;
	}
	//opticalzoom_min
	var = "opticalzoom_min";
	ind = argu.find("opticalzoom_min", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit >0){
		conFeatureRange[2][0] = atoi((argu.substr(startit, lengthit)).c_str());
		filteredFeatures[2] = 1;
	}
	//opticalzoom_max
	var = "opticalzoom_max";
	ind = argu.find("opticalzoom_max", 0);
    endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit >0){
		conFeatureRange[2][1] = atoi((argu.substr(startit, lengthit)).c_str());
	    filteredFeatures[2] = 1;
	}
	
	
	//maximumresolution_min
	var ="maximumresolution_min";
	ind = argu.find("maximumresolution_min", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit >0){
		conFeatureRange[3][0] = atoi((argu.substr(startit, lengthit)).c_str());
		   filteredFeatures[3] = 1;
		}
	
	//maximumresolution_max
	var = "maximumresolution_max";
	ind = argu.find("maximumresolution_max", 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit >0){
	conFeatureRange[3][1] = atoi((argu.substr(startit, lengthit)).c_str());
	  filteredFeatures[3] = 1;
	}
	
		
	if (layer == 1){
		// Driver Manager
		sql::mysql::MySQL_Driver *driver;

		// Connection, (simple, not prepared) Statement, Result Set
		sql::Connection	*con;
		sql::Statement	*stmt;
		sql::ResultSet	*res;
	    sql::ResultSet	*res1; 
	    sql::ResultSet	*res2;
	    sql::ResultSet	*res3; 
	    sql::ResultSet	*res4;   
	    sql::ResultSet	*res5;  //brand
		  

	  		string line;
			string buf; 
			vector<string> tokens;
			ifstream myfile;
			int i=0;
		   myfile.open("/optemo/site/config/database.yml"); 
		   if (myfile.is_open()){
			while (! myfile.eof()){
				getline (myfile,line);
				stringstream ss(line);

				while(ss>>buf){
					tokens.push_back(buf);
					i++;	}
			}
		    myfile.close();
           }
		   else{
				cout<<"Can't open file "<<myfile<<endl;
		}

		string databaseString = tokens.at(findVec(tokens, "database:") + 1);
		string usernameString = tokens.at(findVec(tokens, "username:") + 1);
		string passwordString = tokens.at(findVec(tokens, "password:") + 1);
		string hostString = tokens.at(findVec(tokens, "host:") + 1);

		    #define EXAMPLE_PORT "3306"       
		 	#define EXAMPLE_DB  "optemo_development"
			#define EXAMPLE_HOST hostString    //"127.0.0.1" // "jaguar"
			#define EXAMPLE_USER usernameString //"maryam" //usernameString //"root"      // "maryam"
		    #define EXAMPLE_PASS passwordString //"sCbub3675NWnNZK2" //"aabb2761"  // 

     
			try {
				// Using the Driver to create a connection
				driver = sql::mysql::get_mysql_driver_instance();
				con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);
				// Creating a "simple" statement - "simple" = not a prepared statement
				stmt = con->createStatement();

				// Create a test table demonstrating the use of sql::Statement.execute()
				stmt->execute("USE "  EXAMPLE_DB);

				// Fetching again but using type convertion methods
				res = stmt->executeQuery("SELECT listpriceint FROM cameras"); // ORDER BY id DESC");
				res1 = stmt->executeQuery("SELECT displaysize FROM cameras"); 
				res2 = stmt->executeQuery("SELECT opticalzoom FROM cameras"); 
				res3 = stmt->executeQuery("SELECT maximumresolution FROM cameras"); 
				res4 = stmt->executeQuery("SELECT salepriceint FROM cameras"); 
				res5 = stmt->executeQuery("SELECT brand FROM cameras"); 
			//	res5 = stmt->executeQuery("SELECT id FROM cameras");

				//listpriceint
			    //displaysize
				//optical zoom
				//maximumresolution

				
				size = res->rowsCount();
				double **data = new double*[size];
		    	for(int j=0; j<size; j++){
						data[j] = new double[featureN]; 
				}
				
				int *idA = new int[size];	
				idA[0] = -10;
			    row = 1;
				sane = 0;
				bool include = true;
				int listprice;
				int saleprice; 
		//cout<<"conFeatureRange[0][0] is "<<conFeatureRange[0][0]<<"  and conFeatureRange[0][1] is  "<<conFeatureRange[0][1];
	
				
				while (res1->next() && res->next() && res2->next() && res3->next() & res4->next() & res5->next()) {
					idA[row] = -10;
		//	cout<<"     res->getInt(conFeatureNames[0])  is  "<<res->getInt(conFeatureNames[0])<<endl;
					
				 if (
		     (!filteredFeatures[0]  || ((res->getInt(conFeatureNames[0])>=(filteredFeatures[0]*conFeatureRange[0][0])) && (res->getInt(conFeatureNames[0])<=(filteredFeatures[0]*conFeatureRange[0][1])))) &&  
			  (!filteredFeatures[1]  ||((res1->getInt(conFeatureNames[1])>=(filteredFeatures[1]*conFeatureRange[1][0])) && (res1->getInt(conFeatureNames[1])<=(filteredFeatures[1]*conFeatureRange[1][1])))) && 
			  (!filteredFeatures[2]  ||((res2->getInt(conFeatureNames[2])>=(filteredFeatures[2]*conFeatureRange[2][0])) && (res2->getInt(conFeatureNames[2])<=(filteredFeatures[2]*conFeatureRange[2][1])))) && 
	     	  (!filteredFeatures[3]  ||((res3->getInt(conFeatureNames[3])>=(filteredFeatures[3]*conFeatureRange[3][0])) && (res3->getInt(conFeatureNames[3])<=(filteredFeatures[3]*conFeatureRange[3][1])))) &&
			  (!filteredFeatures[0]  || ((res4->getInt("salepriceint")>=(filteredFeatures[0]*conFeatureRange[0][0])) && (res4->getInt("salepriceint")<=(filteredFeatures[0]*conFeatureRange[0][1])))) &&
			  (!filteredFeatures[4]  ||((res5->getString("brand")==brand))) && 
				(res->getInt("listpriceint")!=NULL && res1->getDouble("displaysize")!=NULL && res2->getDouble("opticalzoom")!=NULL && res3->getDouble("maximumresolution")!=NULL && res4->getInt("salepriceint")>0 && 
				res5->getString("brand")!=""))	
			{
							listprice =  res->getInt("listpriceint");
						   saleprice = res4->getInt("salepriceint");
						   // cout<<"real min is  "<<min(listprice, saleprice)<<endl;
							data[sane][0] = min(listprice, saleprice);
						//	cout<<" min is "<<data[sane][0]<<endl;
						    data[sane][1] = res1->getInt("displaysize");
							data[sane][2] = res2->getInt("opticalzoom");
							data[sane][3] = res3->getInt("maximumresolution");
							idA[row] = sane; 
							sane++;
				}
					row++;
					
				}	

	   
//////////////////////		
	    double *max = new double[featureN];
		double *min = new double[featureN];
	 	double *dif = new double[featureN];
	    
	    double **dataN = new double*[sane];
	    for(int j=0; j<sane; j++){
				dataN[j] = new double[featureN]; 
		}     
	
		
		for(int f=0; f<featureN; f++){	
  	          max[f] = data[f][0]; 
              min[f] = data[f][0]; 
        }
 
	   
	
		for (int f=0; f<featureN; f++){
	      for(int j = 0; j<sane; j++){
				if(data[j][f] > max[f]){
	                max[f] = data[j][f];
	           }
		       if (data[j][f] < min[f]){
				   min[f] = data[j][f];
			   }
			}
		}	
				
	    	  

		for (int f=0; f<featureN; f++){
			dif[f] = max[f] - min[f];
		}
	
		for (int f=0; f<featureN; f++){
		   for(int j=0; j<sane; j++){
		    dataN[j][f] = (((data[j][f] - min[f])/ dif[f]) * 2 ) - 1;
		   	
	}
	   }
        
   //  delete data;
  
     double** centroids = new double* [clusterN];
    	for(int j=0; j<clusterN; j++){
    		centroids[j]=new double[featureN];
   	}
    
    
       int *centersA = k_means(dataN,sane,featureN, clusterN, 1e-4, centroids); 
      	
    
    		double** dist = new double* [sane];
 
     		for(int j=0; j<sane; j++){
    			dist[j] = new double[clusterN]; 
    		}
  
			double distan;
          for (int j=0; j<sane; j++){
    			for (int c=0; c<clusterN; c++){
    				for (int f=0; f<featureN; f++){
						distan = dist[j][c] + ((centroids[c][f] - dataN[j][f])*(centroids[c][f] - dataN[j][f]) );	 
    				    dist[j][c] = distan;	   
    				}  
   			}	 
    	}
			
			
							////////////////////////////////  Change clusteredData to vector 
  	int **clusteredData = new int* [clusterN];


 		for (int j=0; j<clusterN; j++){
 			clusteredData[j] = new int[sane];	
 		}

 		for (int c=0; c<clusterN; c++){
 			clusteredData[c][0] = 0;
 		}	
 		int *ts = new int[clusterN];
 		for(int j=0; j<clusterN; j++){
 			ts[j] = 0;
 		}
 		for (int j=0; j<sane; j++){
 		    ts[centersA[j]] = ts[centersA[j]]++;		
 			clusteredData[centersA[j]][ts[centersA[j]]] = find(idA, j, size);
 			clusteredData[centersA[j]][0]++;
 		}
 		
 	  
         int *medians = new int [clusterN];
 		
 		double minDist;
 		for(int c =0; c<clusterN; c++){
 			minDist = dist[0][c];
 			medians[c] = clusteredData[c][1];
			if (clusteredData[c][0] == 0){   /////////////LOSER, FIX IT!!
   			medians[c] = clusteredData[c+1][2];
		//	cout<<"loser c is "<<c<<endl;
			   			}
 			for(int j=2; j<clusteredData[c][0]; j++){
 				if(minDist > dist[j-1][c]){
 					minDist = dist[j-1][c];
 					medians[c] = clusteredData[c][j];
 				}
 			}
 		}

 		for (int c=0; c<clusterN; c++){		  
		   		cout<<medians[c]<<" ";
		       }
		   	cout<<endl;

   // Saving 
   
	string fileName = "saveThem.txt"; 

	save2File(fileName, data, clusteredData, centersA, idA, sane, featureN, clusterN, row);  //dataN
	
//	save2dIntArray(fileName, clusteredData, clusterN, sane);
//	
//	save1dIntArray(fileName, medians, clusterN);


	// Clean up

 	delete stmt;
 	delete con;
    delete data;
    delete dataN;
 	delete clusteredData; 
 	delete medians;
 	delete dist;

 	} catch (sql::mysql::MySQL_DbcException *e) {

		delete e;
		return EXIT_FAILURE;

	} catch (sql::DbcException *e) {
		/* Exception is not caused by the MySQL Server */

		delete e;
		return EXIT_FAILURE;
	}



}//////////////////////////////////////////////////


else if(layer == 2){

//inputID = atoi(argv[3]); 
string fileName = "saveThem.txt";
int minDist;
////loading data
//  
//(fileName, dataN, clusteredData, centersA, idA, sane, featureN, clusterN, row);

int *sizes = loadNumbers(fileName); 

int sane = sizes[0];
featureN = sizes[1];
clusterN = sizes[2];
row = sizes[3];

double **oldData = new double*[sane];
for(int j=0; j<sane; j++){
	oldData[j] = new double[featureN]; 
}     

  
 int **clusteredData = new int* [clusterN];
 for (int j=0; j<clusterN; j++){
 			clusteredData[j] = new int[sane];	
 }

 int *centersA = new int[sane];
 int *idA = new int[row];

 loadFile(fileName, oldData, clusteredData, centersA, idA);


 if (inputID > row){
 	cout<<"THE ID NUMBER IS TOO LARGE"<<endl;
 	return 0;
  }

 if (idA[inputID] == -10){
 	cout<<"THIS ID IS NOT ACCEPTABLE"<<endl;
 	return 0;
 }


 int pickedCluster = centersA[idA[inputID]];  

 //removing the inputID from the rest of data   

 int clusterSize = clusteredData[pickedCluster][0];

 clusteredData[pickedCluster][find(clusteredData[pickedCluster], inputID, clusteredData[pickedCluster][0])] = clusteredData[pickedCluster][clusterSize];
 clusteredData[pickedCluster][0]--;
 clusterSize--;
	 	
 
double **data = new double*[clusterSize];
 for(int j=0; j<clusterSize; j++){
	 	data[j] = new double[featureN]; 
  }	
 
// filtering the data

bool include = true;
for (int j=0; j<clusterSize; j++){
 for (int f=0; f<featureN; f++)	{ 
	include = include && ((!filteredFeatures[f]  || (data[idA[clusteredData[pickedCluster][j]]][f]>=(filteredFeatures[f]*conFeatureRange[f][0])) && 
	(data[idA[clusteredData[pickedCluster][j]]][f]<=(filteredFeatures[f]*conFeatureRange[f][1])))); 
  }	
  if (include){
    for (int f=0; f<featureN; f++) {	
      data[j][f] = oldData[idA[(clusteredData[pickedCluster][j+1])]][f];    
    } 
  }
 }

// normalizing of the data

 double **dataN = new double* [clusterSize];
  	
 for(int j=0; j<clusterSize; j++){
	 	dataN[j] = new double[featureN]; 
  }     
  
 
	double *max = new double[featureN];
	double *min = new double[featureN];
	double *dif = new double[featureN];
	
	for(int f=0; f<featureN; f++){	
        max[f] = data[f][0]; 
        min[f] = data[f][0]; 
  }


	for (int f=0; f<featureN; f++){
    for(int j = 0; j<clusterSize; j++){
			if(data[j][f] > max[f]){
              max[f] = data[j][f];
         }
	       if (data[j][f] < min[f]){
			   min[f] = data[j][f];
		   }
		}
	}	
			
  	  

	for (int f=0; f<featureN; f++){
		dif[f] = max[f] - min[f];
	}

	for (int f=0; f<featureN; f++){
	   for(int j=0; j<clusterSize; j++){
	    dataN[j][f] = (((data[j][f] - min[f])/ dif[f]) * 2 ) - 1;
	   	
}
 }

  
  
  double** centroids2 = new double* [clusterN-1];
  for(int j=0; j<clusterN-1; j++){
   	centroids2[j]=new double[featureN];
  }
 

  double** dist2 = new double* [clusterSize];
  	
  for(int j=0; j<clusterSize; j++){
  	dist2[j] = new double[clusterN-1]; 
  }
  
   
 int *centers2A = k_means(dataN,clusterSize, featureN, clusterN - 1, 1e-4, centroids2); 

   
  for (int j=0; j<clusterSize; j++){
 	for (int c=0; c<clusterN-1; c++){
  		for (int f=0; f<featureN; f++){
  			dist2[j][c] = dist2[j][c] + ((centroids2[c][f] - dataN[j][f])*(centroids2[c][f] - dataN[j][f]) );	   
  		}  
  	}	 
  }
  
   	int **clusteredData2 = new int* [clusterN-1];


  	for (int j=0; j<clusterN-1; j++){
  		clusteredData2[j] = new int[clusterSize];	
  	}

  	for (int c=0; c<clusterN-1; c++){
  		clusteredData2[c][0] = 0;
  	}	
  	int *ts2 = new int[clusterN-1];
  	for(int j=0; j<clusterN-1; j++){
  		ts2[j] = 0;
  	}
  	for (int j=0; j<clusterSize; j++){
  	
  	    ts2[centers2A[j]] = ts2[centers2A[j]]++;	
  		clusteredData2[centers2A[j]][ts2[centers2A[j]]] = clusteredData[pickedCluster][j+1];
		clusteredData2[centers2A[j]][0]++;
  	}

   	int *medians2 = new int [clusterN - 1];
   	for(int c =0; c<clusterN - 1; c++){
   		minDist = dist2[0][c];
   			medians2[c] = clusteredData2[c][1];
   			if (clusteredData2[c][0] == 0){   /////////////LOSER, FIX IT!!
   				medians2[c] = clusteredData[pickedCluster][c];
   			}
   	  		for(int j=2; j<clusteredData2[c][0]; j++){
   		 		if(minDist > dist2[j-1][c]){
    					minDist = dist2[j-1][c];
   					medians2[c] = clusteredData2[c][j];		   
   		     	}
   		   	}
   		 }
   	
		
   	for (int c=0; c<clusterN-1; c++){		  
   		cout<<medians2[c]<<" ";
       }
   	cout<<endl;
    // 

   // Clean up


	delete dataN;
	delete clusteredData;
   delete clusteredData2; 
	delete medians2;

}


return 1; //EXIT_SUCCESS;
}