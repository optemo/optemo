
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
using namespace std;


// Public interface of the MySQL Connector/C++
#include <cppconn/mysql_public_iface.h>
// Connection parameter and sample data
#include "examples.h"

using namespace std;

/**
* Usage example for Driver Manager, Connection, (simple) Statement, ResultSet
*/
int main(int argc, const char* argv[]) {
	// Driver Manager
	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection	*con;
	sql::Statement	*stmt;
	sql::ResultSet	*res;
    sql::ResultSet	*res2; 
    sql::ResultSet	*res3;
    sql::ResultSet	*res4;   
    sql::ResultSet	*res5;   
    
	/* sql::ResultSet.rowsCount() returns size_t */
	int row;
	stringstream sql;
	int sane , affected_rows, size;
	int clusterN = 9;    
    int inputID;
   	inputID = atoi(argv[1]); 

    // Connection properties
	  

	string line;
	string buf; 
	vector<string> tokens;
	ifstream myfile;
	int i=0;
   myfile.open("config/database.yml"); 
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
		res2 = stmt->executeQuery("SELECT displaysize FROM cameras"); 
		res3 = stmt->executeQuery("SELECT opticalzoom FROM cameras"); 
		res4 = stmt->executeQuery("SELECT maximumresolution FROM cameras"); 
		res5 = stmt->executeQuery("SELECT id FROM cameras");
		
		//listpriceint
	    //displaysize
		//optical zoom
		//maximumresolution

		
		size = res->rowsCount();
		double **data = new double*[size];
    	for(int j=0; j<size; j++){
				data[j] = new double[4]; 
		}
		int *idA = new int[size];	
	    row = 1;
		sane = 0;
		while (res2->next() && res->next() && res3->next() && res4->next() && res5->next()) {
		    
			idA[row] = -10;
			if (res->getInt("listpriceint")!=NULL && res2->getDouble("displaysize")!=NULL && res3->getDouble("opticalzoom")!=NULL && res4->getDouble("maximumresolution")!=NULL){
			    	
					data[sane][0] = res->getInt("listpriceint");
			//		cout<<"listpriceint of "<<row<<" is "<<data[sane][0]<<endl;
				    data[sane][1] = res2->getInt("displaysize");
					data[sane][2] = res3->getInt("opticalzoom");
					data[sane][3] = res4->getInt("maximumresolution");
					idA[row] = sane; 
					sane++;
		}
			row++;
		}
	  
        if (inputID > row){
			cout<<"THE ID NUMBER IS TOO LARGE"<<endl;
			return 0;
         }

        if (idA[inputID] == -10){
			cout<<"THIS ID IS NOT ACCEPTABLE"<<endl;
			return 0;
		}
		
	    double *max = new double[4];
		double *min = new double[4];
	 	double *dif = new double[4];
	    
	    double **dataN = new double*[sane];
	    for(int j=0; j<sane; j++){
				dataN[j] = new double[4]; 
		}     
	
		
		for(int f=0; f<4; f++){	
  	          max[f] = data[f][0]; 
              min[f] = data[f][0]; 
        }
 
	   
	
		for (int f=0; f<4; f++){
	      for(int j = 0; j<sane; j++){
				if(data[j][f] > max[f]){
	                max[f] = data[j][f];
	           }
		       if (data[j][f] < min[f]){
				   min[f] = data[j][f];
			   }
			}
		}	
				
	    	  

		for (int f=0; f<4; f++){
			dif[f] = max[f] - min[f];
		}
	
		for (int f=0; f<4; f++){
		   for(int j=0; j<sane; j++){
		    dataN[j][f] = (((data[j][f] - min[f])/ dif[f]) * 2 ) - 1;
		   	
	}
	   }
        
   //  delete data;
  
     double** centroids = new double* [clusterN];
    	for(int j=0; j<clusterN; j++){
    		centroids[j]=new double[4];
   	}
    
    
       int *centersA = k_means(dataN,sane,4, clusterN, 1e-4, centroids); 
      	
    
    		double** dist = new double* [sane];
 
     		for(int j=0; j<sane; j++){
    			dist[j] = new double[clusterN]; 
    		}
  
			double distan;
          for (int j=0; j<sane; j++){
    			for (int c=0; c<clusterN; c++){
    				for (int f=0; f<4; f++){
						distan = dist[j][c] + ((centroids[c][f] - dataN[j][f])*(centroids[c][f] - dataN[j][f]) );	 
    				    dist[j][c] = distan;	   
    				}  
   			}	 
    	}
			

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
 		
 	    int pickedCluster = centersA[idA[inputID]];  
 	    int clusterSize = clusteredData[pickedCluster][0];
         int *medians = new int [clusterN];
 		
 		double minDist;
 		for(int c =0; c<clusterN; c++){
 			minDist = dist[0][c];
 			medians[c] = clusteredData[c][1];
 			for(int j=2; j<clusteredData[c][0]; j++){
 				if(minDist > dist[j-1][c]){
 					minDist = dist[j-1][c];
 					medians[c] = clusteredData[c][j];
 				}
 			}
 		}
 

 double **data2N = new double* [clusterSize];
   	
   
   for(int j=0; j<clusterSize; j++){
   	data2N[j] = new double[4]; 
   }     
   
   for (int f=0; f<4; f++){
   	for (int j= 0; j< clusterSize; j++){
   		data2N[j][f] = dataN[idA[(clusteredData[pickedCluster][j+1])]][f];   

   	}
   }	 

   double** centroids2 = new double* [clusterN-1];
   for(int j=0; j<clusterN-1; j++){
    	centroids2[j]=new double[4];
   }
  
   
   
   double** dist2 = new double* [clusterSize];
   	
   for(int j=0; j<clusterSize; j++){
   	dist2[j] = new double[clusterN-1]; 
   }
   
	
  int *centers2A = k_means(data2N,clusterSize, 4, clusterN - 1, 1e-4, centroids2); 
  
for (int j=0; j<clusterSize; j++){
}
    
   for (int j=0; j<clusterSize; j++){
  	for (int c=0; c<clusterN-1; c++){
   		for (int f=0; f<4; f++){
   			dist2[j][c] = dist2[j][c] + ((centroids2[c][f] - data2N[j][f])*(centroids2[c][f] - data2N[j][f]) );	   
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
		
		
		for (int c=0; c<clusterN - 1; c++){		  
			cout<<medians2[c]<<" ";
	   // 	for(int j=0; j<4; j++){
	   // 		cout<<"data "<<j<<" is "<<data[idA[medians2[c]]][j]<<endl;
	   // 	} 	
	    }
		cout<<endl;
	// Clean up

 	delete stmt;
 	delete con;
 	delete data2N;
 	delete clusteredData;
	delete clusteredData2; 
 	delete medians;
 	delete medians2;
 	delete dist;
 	delete dist2;
 
	} catch (sql::mysql::MySQL_DbcException *e) {

		delete e;
		return EXIT_FAILURE;

	} catch (sql::DbcException *e) {
		/* Exception is not caused by the MySQL Server */

		delete e;
		return EXIT_FAILURE;
	}

	
return EXIT_SUCCESS;
	}

