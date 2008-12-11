
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
	int conFeatureN = 4;
	int catFeatureN = 1;
	int boolFeatureN = 0;
	int varNamesN = 11;
	int featureN = conFeatureN + catFeatureN + boolFeatureN;    
	int range = 2;
    int inputID = 220;
	int layer = 2;
		
	string *varNames = new string[varNamesN];	
	string *catFeatureNames = new string[catFeatureN];
	string *boolFeatureNames = new string [boolFeatureN];
	string *conFeatureNames = new string[conFeatureN];
	double **conFeatureRange = new double* [conFeatureN];
	
	catFeatureNames[0] = "brand";
	
	conFeatureNames[0]="listpriceint";
	conFeatureNames[1]="displaysize";  
    conFeatureNames[2]="opticalzoom";
    conFeatureNames[3]="maximumresolution";
    
  	bool *conFilteredFeatures = new bool[conFeatureN];   
	bool *catFilteredFeatures = new bool[catFeatureN];
	bool *boolFilteredFeatures = new bool[boolFeatureN];

	
	for (int f=0; f<conFeatureN; f++){
		conFilteredFeatures[f] = 0;
		conFeatureRange[f] = new double[range]; 
	} 

	for (int f=0; f<catFeatureN; f++){
	    catFilteredFeatures[f] = 0;
	}

    for (int f=0; f<boolFeatureN; f++){
		boolFilteredFeatures[f] = 0;
	}

  // 	bool filter = false;
  //  for(int f=0; f<conFeatureN; f++){
  //  	filter = filter || conFilteredFeatures[f];
  //  }
  //  for(int f=0; f<catFeatureN; f++){
  //  	filter = filter || catFilteredFeatures[f];
  //  }
  //  for(int f=0; f<boolFeatureN; f++){
  //  	filter = filter || boolFilteredFeatures[f];
  //  }
   

	string argu = argv[1];
	int ind, endit, startit, lengthit;
	string var;

	varNames[0] = "layer";
	varNames[1] = "ids";
	varNames[2] = "brand";
	varNames[3] = "price_min";
	varNames[4] = "price_max";
	varNames[5] = "displaysize_min";
	varNames[6] = "displaysize_max";
	varNames[7] = "opticalzoom_min";
	varNames[8] = "opticalzoom_max";
	varNames[9] = "maximumresolution_min";
	varNames[10] = "maximumresolution_max";
	
	
    
	varNamesN = 11;
    
	string brand = "";
	for (int j=0; j<varNamesN; j++){
		var = varNames[j];
		ind = argu.find(var, 0);
		endit = argu.find("\n", ind);
		startit = ind + var.length() + 2;
		lengthit = endit - startit;
		if(lengthit > 0){
			if (var=="brand"){
					brand = (argu.substr(startit, lengthit)).c_str();
					if (brand != "All Brands"){
						catFilteredFeatures[0] = 1;
					}
		
		   }
		   else if(var == "layer"){
		        	layer = atoi((argu.substr(startit, lengthit)).c_str());
	    	}
		   else if(var == "ids"){
			    	inputID = atoi((argu.substr(startit, lengthit)).c_str());
		    }
		   else if(var == "price_min"){
					conFeatureRange[0][0] = atof((argu.substr(startit, lengthit)).c_str()) * 100;
		        	conFilteredFeatures[0] = 1;
	    	}
		   else if(var == "price_max"){
			
			conFeatureRange[0][1] = atof((argu.substr(startit, lengthit)).c_str()) ;
					
					conFeatureRange[0][1] = conFeatureRange[0][1]* 100;
			    	conFilteredFeatures[0] = 1;
		    }
		   else if(var == "displaysize_min"){
				    conFeatureRange[1][0] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[1] = 1;
		    }
		   else if(var == "displaysize_max"){
			    	conFeatureRange[1][1] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[1] = 1;
		    }
		   else if(var == "opticalzoom_min"){
			    	conFeatureRange[2][0] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[2] = 1;
		    }
		   else if(var == "opticalzoom_max"){
				    conFeatureRange[2][1] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[2] = 1;
			}
		   else if (var == "maximumresolution_min"){
					conFeatureRange[3][0] = atof((argu.substr(startit, lengthit)).c_str());
			   		conFilteredFeatures[3] = 1;
		    }	
		   else if (var == "maximumresolution_max"){
				    conFeatureRange[3][1] = atof((argu.substr(startit, lengthit)).c_str());
				   	conFilteredFeatures[3] = 1;
			}	 
	    }
		
		else{      //if lengthit = 0
		//	cout<<"Error, you didn't specify a value for "<<var<<endl;
			}
		//layer = atoi((argu.substr(startit, lengthit)).c_str());
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
						data[j] = new double[conFeatureN]; 
				}
				string *brands = new string [size];
				int *idA = new int[size];	
				idA[0] = -10;
			    row = 1;
				sane = 0;
				bool include = true;
				double listprice = 0.0;
				double saleprice = 0.0;
				double price = 0.0;
				 
		//cout<<"conFeatureRange[0][0] is "<<conFeatureRange[0][0]<<"  and conFeatureRange[0][1] is  "<<conFeatureRange[0][1];
	
				
				while (res1->next() && res->next() && res2->next() && res3->next() & res4->next() & res5->next()) {
				
					idA[row] = -10;
		//	cout<<"     res->getInt(conFeatureNames[0])  is  "<<res->getInt(conFeatureNames[0])<<endl;
				 if (res->getDouble("listpriceint")!=NULL){  
					listprice =  res->getDouble("listpriceint");
					}
				
				 if(res4->getDouble("salepriceint")!=NULL ) {	
					
				    saleprice = res4->getDouble("salepriceint");
					}
						
				   price = min(listprice, saleprice);
					
				 if (
			 (price>0.0 && res1->getDouble("displaysize")!=NULL && res2->getDouble("opticalzoom")!=NULL && res3->getDouble("maximumresolution")!=NULL && res5->getString("brand")!="")&& 
		     (!conFilteredFeatures[0]  || ((price>=(conFilteredFeatures[0]*conFeatureRange[0][0])) && (price<=(conFilteredFeatures[0]*conFeatureRange[0][1])))) &&  
			  (!conFilteredFeatures[1]  ||((res1->getDouble(conFeatureNames[1])>=(conFilteredFeatures[1]*conFeatureRange[1][0])) && (res1->getDouble(conFeatureNames[1])<=(conFilteredFeatures[1]*conFeatureRange[1][1])))) && 
			  (!conFilteredFeatures[2]  ||((res2->getDouble(conFeatureNames[2])>=(conFilteredFeatures[2]*conFeatureRange[2][0])) && (res2->getDouble(conFeatureNames[2])<=(conFilteredFeatures[2]*conFeatureRange[2][1])))) && 
	     	 (!conFilteredFeatures[3]  ||((res3->getDouble(conFeatureNames[3])>=(conFilteredFeatures[3]*conFeatureRange[3][0])) && (res3->getDouble(conFeatureNames[3])<=(conFilteredFeatures[3]*conFeatureRange[3][1])))) &&
			 
			(!catFilteredFeatures[0]  ||((res5->getString("brand")==brand))) 
				)	
				{              
			
							data[sane][0] = price;
						//	cout<<" min is "<<data[sane][0]<<endl;
						    data[sane][1] = res1->getDouble("displaysize");
							data[sane][2] = res2->getDouble("opticalzoom");
							data[sane][3] = res3->getDouble("maximumresolution");
							idA[row] = sane; 
							brands[sane] = res5->getString("brand");
						
							sane++;
				}
					row++;
					
				}	

	   
//////////////////////		
	   // double *max = new double[featureN];
	//	double *min = new double[featureN];
	 	double *dif = new double[conFeatureN];
	    
	    double **dataN = new double*[sane];
	    for(int j=0; j<sane; j++){
				dataN[j] = new double[conFeatureN]; 
		}     
	
		
		for(int f=0; f<conFeatureN; f++){	
  	          conFeatureRange[f][1] = data[0][f]; 
              conFeatureRange[f][0] = data[0][f]; 
        }
 
	   
	
		for (int f=0; f<conFeatureN; f++){
	      for(int j = 0; j<sane; j++){
				if(data[j][f] > conFeatureRange[f][1]){
	                conFeatureRange[f][1] = data[j][f];
	           }
		       if (data[j][f] < conFeatureRange[f][0]){
				   conFeatureRange[f][0] = data[j][f];
			   }
			}
		//	cout<< "Min of "<<f<<" is "<< 	conFeatureRange[f][0]<<endl;
		}	
				
	 
		for (int f=0; f<conFeatureN; f++){
			dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
		}
	
		for (int f=0; f<conFeatureN; f++){
		   for(int j=0; j<sane; j++){
			if (dif[f] == 0){
				dataN[j][f] = 0;
			}
			else{
		    	dataN[j][f] = (((data[j][f] - conFeatureRange[f][0])/ dif[f]) * 2 ) - 1;
		   	}
	}
	   }
        
   //  delete data;
  
     double** centroids = new double* [clusterN];
    	for(int j=0; j<clusterN; j++){
    		centroids[j]=new double[conFeatureN];
   	}
    
    
       int *centersA = k_means(dataN,sane,conFeatureN, clusterN, 1e-4, centroids); 
      	
    
    		double** dist = new double* [sane];
 
     		for(int j=0; j<sane; j++){
    			dist[j] = new double[clusterN]; 
    		}
  
			double distan;
          for (int j=0; j<sane; j++){
    			for (int c=0; c<clusterN; c++){
    				for (int f=0; f<conFeatureN; f++){
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
//Generating the output string 
	

		
		
	
		string out = "--- !map:HashWithIndifferentAccess \n";
		
		conFeatureRange[0][0] = conFeatureRange[0][0] / 100;
		conFeatureRange[0][1] = conFeatureRange[0][1] / 100;
		for (int j=0; j<(conFeatureN*2); j++){
			out.append(varNames[j+3]);
			out.append(": ");
			if ((j%2) == 0){  // j is even for mins
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][0];
		     	out.append(oss.str());
			}
			else{
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][1];
		     	out.append(oss.str());
				}
			out.append("\n");
		}
		out.append("ids: \n");
        for(int c=0; c<clusterN; c++){
		       out.append("- ");
	           std::ostringstream oss; 		  
			   oss<<medians[c];
			   out.append(oss.str()); 
			   out.append("\n");
		} 
//
		cout<<out<<endl;

   // Saving 
   
		string fileName = "tmp/cachedFiles/saveClustered";	 
		std::ostringstream layerS;
		layerS<<layer;
		fileName.append(layerS.str());


	save2File(fileName, data, clusteredData, centersA, brands, idA, sane, conFeatureN, clusterN, row);  //dataN
	
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


else if(layer >1){

   string fileName = "tmp/cachedFiles/saveClustered";	 
   std::ostringstream layerS;
   layerS<<layer-1;
   fileName.append(layerS.str());

int minDist;

////loading data

int *sizes = loadNumbers(fileName); 

int sane = sizes[0];
conFeatureN = sizes[1];
clusterN = sizes[2];
row = sizes[3];

double **oldData = new double*[sane];
for(int j=0; j<sane; j++){
	oldData[j] = new double[conFeatureN]; 
}     


 int **oldClusteredData = new int* [clusterN];
 for (int j=0; j<clusterN; j++){
 			oldClusteredData[j] = new int[sane];	
 }

 int *oldCentersA = new int[sane];
 int *oldIdA = new int[row];

string *oldBrands = new string[sane]; 



 loadFile(fileName, oldData, oldClusteredData, oldCentersA, oldBrands, oldIdA);
//for (int j=0; j<sane; j++){
//	cout<<"oldBrand is "<<oldBrands[j]<<endl;
//}

 if (inputID > row){
 	cout<<"THE ID NUMBER IS TOO LARGE"<<endl;
 	return 0;
  }

 if (oldIdA[inputID] == -10){
 	cout<<"THIS ID IS NOT ACCEPTABLE"<<endl;
 	return 0;
 }


 int pickedCluster = oldCentersA[oldIdA[inputID]];  

 //removing the inputID from the rest of data   

 int clusterSize = oldClusteredData[pickedCluster][0];

 oldClusteredData[pickedCluster][find(oldClusteredData[pickedCluster], inputID, oldClusteredData[pickedCluster][0])] = oldClusteredData[pickedCluster][clusterSize];
 oldClusteredData[pickedCluster][0]--;
 clusterSize--;


double **data = new double*[clusterSize];
 for(int j=0; j<clusterSize; j++){
	 	data[j] = new double[conFeatureN]; 
  }	
 
string *brands = new string [clusterSize]; 
int *idA = new int[clusterSize];

// filtering the data

bool include = true;
for (int j=0; j<clusterSize; j++){
 for (int f=0; f<conFeatureN; f++)	{ 
	include = include && (!conFilteredFeatures[f]  || ((oldData[oldClusteredData[pickedCluster][j]][f]>=(conFilteredFeatures[f]*conFeatureRange[f][0])) && 
	(oldData[oldClusteredData[pickedCluster][j]][f]<=(conFilteredFeatures[f]*conFeatureRange[f][1])))); 
  }	
//cout<<":Here "<<endl; 
//cout<<"oldIdA[oldClusteredData[pickedCluster][j]]  is  "<<oldIdA[oldClusteredData[pickedCluster][j+1]]<<endl;
//cout<<"brand is "<<brand<<"  and  oldBrand is "<<oldBrands[oldIdA[oldClusteredData[pickedCluster][j+1]]]<<endl;
include = include && (!catFilteredFeatures[0] || (brand == oldBrands[oldIdA[oldClusteredData[pickedCluster][j+1]]])); 
//cout<<" not including yet"<<endl;  
if (include){
//	cout<<"including "<<endl;
    for (int f=0; f<conFeatureN; f++) {	
      data[j][f] = oldData[oldIdA[(oldClusteredData[pickedCluster][j+1])]][f];  
     }
      brands[j]  = oldBrands[oldIdA[oldClusteredData[pickedCluster][j+1]]];
      idA[j] = oldClusteredData[pickedCluster][j+1]; 
  }
 }

//Delete old stuff

delete oldIdA;
delete oldData;
delete oldCentersA;



// normalizing of the data
 
 double **dataN = new double* [clusterSize];
  	
 for(int j=0; j<clusterSize; j++){
	 	dataN[j] = new double[conFeatureN]; 
  }     
  
 for(int f=0; f<conFeatureN; f++){	
        conFeatureRange[f][1] = data[0][f]; 
        conFeatureRange[f][0] = data[0][f]; 
  }

	double *dif = new double[conFeatureN];


	for (int f=0; f<conFeatureN; f++){
       for(int j = 0; j<clusterSize; j++){
			if(data[j][f] > conFeatureRange[f][1]){
               conFeatureRange[f][1] = data[j][f];
         }
	       if (data[j][f] < conFeatureRange[f][0]){
			   conFeatureRange[f][0] = data[j][f];
		   }
		}
	}	

	for (int f=0; f<conFeatureN; f++){
		dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
	}

	for (int f=0; f<conFeatureN; f++){
	   for(int j=0; j<clusterSize; j++){
		if (dif[f] == 0){
			dataN[j][f] = -1;	
		}
	    else{
		dataN[j][f] = (((data[j][f] - conFeatureRange[f][0])/ dif[f]) * 2 ) -1;
   	}
}
 }
  
  double** centroids = new double* [clusterN-1];
  for(int j=0; j<clusterN-1; j++){
   	centroids[j]=new double[conFeatureN];
  }
 

  double** dist = new double* [clusterSize];
  	
  for(int j=0; j<clusterSize; j++){
  	dist[j] = new double[clusterN-1]; 
  }
  

 
 int *centersA = k_means(dataN,clusterSize, conFeatureN, clusterN - 1, 1e-4, centroids); 


  for (int j=0; j<clusterSize; j++){
 	for (int c=0; c<clusterN-1; c++){
  		for (int f=0; f<conFeatureN; f++){
  			dist[j][c] = dist[j][c] + ((centroids[c][f] - dataN[j][f])*(centroids[c][f] - dataN[j][f]));	
      
  		}  
  	}	 
  }
  
   	int **clusteredData = new int* [clusterN-1];


  	for (int j=0; j<clusterN-1; j++){
  		clusteredData[j] = new int[clusterSize];	
  	}

  	for (int c=0; c<clusterN-1; c++){
  		clusteredData[c][0] = 0;
  	}	
  	int *ts = new int[clusterN-1];
  	for(int j=0; j<clusterN-1; j++){
  		ts[j] = 0;
  	}
  	for (int j=0; j<clusterSize; j++){
  	
  	    ts[centersA[j]] = ts[centersA[j]]++;	
  		clusteredData[centersA[j]][ts[centersA[j]]] = oldClusteredData[pickedCluster][j+1];
		clusteredData[centersA[j]][0]++;
  	}
 
   	int *medians = new int [clusterN - 1];
   	for(int c =0; c<clusterN - 1; c++){
   		minDist = dist[0][c];
   		medians[c] = clusteredData[c][1];
   			if (clusteredData[c][0] == 0){   /////////////LOSER, FIX IT!!
			//	cout<<"loser"<<endl;
   				medians[c] = oldClusteredData[pickedCluster][c];
   			}
		
   	  		for(int j=2; j<clusteredData[c][0]; j++){
   		 		if(minDist > dist[j-1][c]){
    					minDist = dist[j-1][c];
   					medians[c] = clusteredData[c][j];		   
   		     	}
   		   	}
   		 }
	
	///save to file

		fileName="tmp/cachedFiles/saveClustered";
		std::ostringstream layerO;
		layerO<<layer;
		fileName.append(layerO.str());
		
		save2File(fileName, data, clusteredData, centersA, brands, idA, clusterSize, conFeatureN, clusterN-1, clusterSize);  //dataN

  
		// Clean up


	    delete data;
	    delete dataN;
	 	delete clusteredData; 
	 	delete dist;
	



  // 	for (int c=0; c<clusterN-1; c++){		  
  // 		cout<<medians[c]<<" ";
  //     }
  // 	cout<<endl;
    // 

		string out = "--- !map:HashWithIndifferentAccess \n";
		
		conFeatureRange[0][0] = conFeatureRange[0][0] / 100;
		conFeatureRange[0][1] = conFeatureRange[0][1] / 100;
		for (int j=0; j<(conFeatureN*2); j++){
			out.append(varNames[j+3]);
			out.append(": ");
			if ((j%2) == 0){  // j is even for mins
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][0];
		     	out.append(oss.str());
			}
			else{
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][1];
		     	out.append(oss.str());
				}
			out.append("\n");
		}
		out.append("ids: \n");
        for(int c=0; c<clusterN-1; c++){
		       out.append("- ");
	           std::ostringstream oss; 		  
			   oss<<medians[c];
			   out.append(oss.str()); 
			   out.append("\n");
		} 
//
		cout<<out<<endl;
delete oldClusteredData; 
}

return 1; //EXIT_SUCCESS;
}