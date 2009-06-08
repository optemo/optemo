
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

													//return 9 cameras
// Public interface of the MySQL Connector/C++
#include <cppconn/mysql_public_iface.h>


//
#include "hClustering.h"
#include "preProcessing.h"

using namespace std;

int main(int argc, char** argv){	

	stringstream sql;
	int clusterN;
	int conFeatureN;
	int catFeatureN;
	int boolFeatureN;
	int varNamesN;
	int range;
	int layer = 1;
	string var;
	
	//argument is the productName

	string productName = argv[1];
	string tableName = productName;
	tableName.append("s");
	map<const string, int> productNames;
	productNames["camera"] = 1;
	productNames["printer"] = 2;
	
	switch(productNames[productName]){
		
		case 1:
		
					clusterN = 9; 
					conFeatureN= 4;
					catFeatureN= 1;
					boolFeatureN= 0;
					varNamesN= 12;
					range= 2;
					break;
			
		case 2:
					clusterN = 9; 
					conFeatureN= 5;
					catFeatureN= 1;
					boolFeatureN= 2;
					varNamesN= 12;
					range= 2;
					break;
		default:
					clusterN = 9; 
					conFeatureN= 4;
					catFeatureN= 1;
					boolFeatureN= 0;
					varNamesN= 12;
					range= 2;
					break;
	}
	
	
	
	double* weights = new double [conFeatureN+catFeatureN];
	weights[0] = 1.3;
	for (int f=1; f<conFeatureN; f++){
		weights[f] = 0.9;
	}
	for (int f=0; f<catFeatureN; f++){
		weights[conFeatureN+f] = 0.1;
	}

	ostringstream session_idStream;
	ostringstream layerStream;
	layerStream<<layer;

	string nodeString;
	
	string* indicatorNames = new string [conFeatureN + boolFeatureN];

		
	string *varNames = new string[varNamesN];	
	string *catFeatureNames = new string[catFeatureN];
	string *boolFeatureNames = new string [boolFeatureN];
	string *conFeatureNames = new string[conFeatureN];
	double **conFeatureRange = new double* [conFeatureN];
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
		conFeatureRange[f] = new double [range];
	}

	
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


//	string var;

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
   
//void preClustering(string* varNames, map<const string, int>productNames, string productName, string* conFeatureNames, string* catFeatureNames, string* indicatorNames)
	

 string filteringCommand = preClustering(varNames, productNames, productName, conFeatureNames, catFeatureNames, boolFeatureNames, indicatorNames);


//}
// Driver Manager

   	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection	*con;
	sql::Statement	*stmt;
	
	sql::ResultSet	*res;
	sql::ResultSet	*res2;
	sql::ResultSet	*res3;
    sql::ResultSet	*resClus;
    sql::ResultSet	*resNodes;
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
	string databaseName = tokens.at(findVec(tokens, "database:") + 1);
	
	    #define PORT "3306"       
		#define DB   databaseName
		#define HOST hostString    
		#define USER usernameString 
	    #define PASS passwordString 


///////////////////////////////////////////////
		
			try {
		
				// Using the Driver to create a connection
				driver = sql::mysql::get_mysql_driver_instance();
				con = driver->connect(HOST, PORT, USER, PASS);
				stmt = con->createStatement();
				string command = "USE ";
				command += databaseName;
						
				stmt->execute(command);
					
				//deleting the current node and cluster tables
				command = "DELETE FROM ";
				command += productName;
				command += "_clusters;";
				stmt->execute(command);
					
				command = "DELETE FROM ";
				command += productName;
				command += "_nodes;";
		
				stmt->execute(command);
			
			
			    res = stmt->executeQuery(filteringCommand); 

				int maxSize = 10000;
			
			   while (maxSize>clusterN){
							
					for (int j=0; j<conFeatureN; j++){
						average[j] = 0.0;
					}
			
					maxSize = hClustering(layer, clusterN,  conFeatureN,  boolFeatureN, average, conFeatureRange, conFeatureRangeC, res, res2, resClus, resNodes, 
							stmt, conFeatureNames, boolFeatureNames, productName, weights);	
		
					layer++;
					
				}
		
				leafClustering(conFeatureN, boolFeatureN, clusterN, conFeatureNames, boolFeatureNames, res, res2, res3, stmt, productName);
		
		
//Generating the output string 


 	delete stmt;
 	delete con;

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