
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

//
#include "hClustering.h"

using namespace std;

/**
* Usage example for Driver Manager, Connection, (simple) Statement, ResultSet
*/
int main(int argc, char** argv) {
	
//void initialize(int arcCount, char** argArray)
//{
	stringstream sql;
	int clusterN = 9; 
	int conFeatureN = 4;
	int catFeatureN = 1;
	int boolFeatureN = 0;
	int varNamesN = 12;
	int range = 2;
    int inputID = 8;
	int layer = 2;
	int session_id = 1; 
	ostringstream session_idStream;
	ostringstream layerStream;
	layerStream<<layer;

	string nodeString;
	
	char** indicatorNames = new char* [4];
	indicatorNames[0] = "Price";
	indicatorNames[1] = "Display Size";
	indicatorNames[2] = "Optical Zoom";
	indicatorNames[3] = "Megapixels";
		
	string *varNames = new string[varNamesN];	
	string *catFeatureNames = new string[catFeatureN];
	string *boolFeatureNames = new string [boolFeatureN];
	string *conFeatureNames = new string[conFeatureN];
	double **filteredRange = new double* [conFeatureN];
	
	double ***conFeatureRangeC = new double** [clusterN];
	
	catFeatureNames[0] = "brand";
	
	conFeatureNames[0]="listpriceint";
	conFeatureNames[1]="displaysize";  
    conFeatureNames[2]="opticalzoom";
    conFeatureNames[3]="maximumresolution";
    
	double *average = new double[conFeatureN]; 
	


  	bool *conFilteredFeatures = new bool[conFeatureN];   
	bool *catFilteredFeatures = new bool[catFeatureN];
	bool *boolFilteredFeatures = new bool[boolFeatureN];

   	for(int f=0; f<conFeatureN; f++){
		conFilteredFeatures[f] = 0;
		filteredRange[f] = new double [range];
		
	}

	//price
	filteredRange[0][0] = 10000;
	filteredRange[0][1] = 100000;
	conFilteredFeatures[0] = 1;
	
	//displyasize
	filteredRange[1][0] = 0.5;
	filteredRange[1][1] = 4;
	conFilteredFeatures[1] = 1;
	
	//optical zoom
	filteredRange[2][0] = 1;
	filteredRange[2][1] = 10;
	conFilteredFeatures[2] = 1;
	
	//maximumresolution
	filteredRange[3][0] = 4;
	filteredRange[3][1] = 12;
 	conFilteredFeatures[3] = 1;
	
	for (int c=0; c<clusterN; c++){
		conFeatureRangeC[c] = new double* [conFeatureN]; 
		for(int f=0; f<conFeatureN; f++){
			conFeatureRangeC[c][f] = new double [range];
		}
	} 
	

	for (int f=0; f<catFeatureN; f++){
	    catFilteredFeatures[f] = 0;
	}

    for (int f=0; f<boolFeatureN; f++){
		boolFilteredFeatures[f] = 0;
	}

	string argu = argv[1];
	int ind, endit, startit, lengthit;
	string var;

	varNames[0] = "layer";
	varNames[1] = "camid";
	varNames[2] = "brand";
	varNames[3] = "price_min";
	varNames[4] = "price_max";
	varNames[5] = "displaysize_min";
	varNames[6] = "displaysize_max";
	varNames[7] = "opticalzoom_min";
	varNames[8] = "opticalzoom_max";
	varNames[9] = "maximumresolution_min";
	varNames[10] = "maximumresolution_max";
	varNames[11] = "session_id";	
   
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
					catFilteredFeatures[0] = 1;
					if (brand != "All Brands"){
						catFilteredFeatures[0] = 0;
					}
		   }
		   else if(var == "layer"){
		        	layer = atoi((argu.substr(startit, lengthit)).c_str());
	    	}
		   else if(var == "camid"){
			    	inputID = atoi((argu.substr(startit, lengthit)).c_str());
		    }
		   else if(var == "price_min"){
				    filteredRange[0][0] = atof((argu.substr(startit, lengthit)).c_str()) * 100;
		        	conFilteredFeatures[0] = 1;
	    	}
		   else if(var == "price_max"){
			
	  				filteredRange[0][1] = atof((argu.substr(startit, lengthit)).c_str()) ;	
					filteredRange[0][1] = filteredRange[0][1]* 100;
			    	conFilteredFeatures[0] = 1;
		    }
		   else if(var == "displaysize_min"){
				    filteredRange[1][0] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[1] = 1;
		    }
		   else if(var == "displaysize_max"){
			    	filteredRange[1][1] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[1] = 1;
		    }
		   else if(var == "opticalzoom_min"){
			    	filteredRange[2][0] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[2] = 1;
		    }
		   else if(var == "opticalzoom_max"){
				    filteredRange[2][1] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[2] = 1;
			}
		   else if (var == "maximumresolution_min"){
					filteredRange[3][0] = atof((argu.substr(startit, lengthit)).c_str());
			   		conFilteredFeatures[3] = 1;
		    }	
		   else if (var == "maximumresolution_max"){
		     	    filteredRange[3][1] = atof((argu.substr(startit, lengthit)).c_str());
				   	conFilteredFeatures[3] = 1;
					
			}
		   else if (var == "session_id"){
					session_id = atoi((argu.substr(startit, lengthit)).c_str());
		    } 		 
	    }
	}
	
//}
// Driver Manager

   	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection	*con;
	sql::Statement	*stmt;
	
	sql::ResultSet	*res;
	sql::ResultSet	*res2;
   // sql::ResultSet	*resClus;
   // sql::ResultSet	*resNodes;
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
		#define EXAMPLE_HOST hostString    
		#define EXAMPLE_USER usernameString 
	    #define EXAMPLE_PASS passwordString 


///////////////////////////////////////////////
		
			try {
				// Using the Driver to create a connection
				driver = sql::mysql::get_mysql_driver_instance();
				con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);
				stmt = con->createStatement();
				stmt->execute("USE "  EXAMPLE_DB);
			    res = stmt->executeQuery("SELECT * FROM cameras"); 
				int size = res->rowsCount();
	
////{}

				int* cameraIDs = new int [size];
				
				int cameraN = filter(filteredRange, brand, layer,stmt, res, res2, cameraIDs, conFilteredFeatures, catFilteredFeatures);
		
				cout <<cameraN<<endl;	
				
				for (int j=0; j<cameraN; j++){
					cout<<cameraIDs[j]<<endl;
				}
			
			
			
//Generating the output string 


//////
            
	// Clean up

 	delete stmt;
 	delete con;
  //  delete data;
    
 	 
 //	delete medians;
 

 	} catch (sql::mysql::MySQL_DbcException *e) {

		delete e;
		return EXIT_FAILURE;

	} catch (sql::DbcException *e) {
		/* Exception is not caused by the MySQL Server */

		delete e;
		return EXIT_FAILURE;
	}


return 1; //EXIT_SUCCESS;
}