
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
#include <map>

using namespace std;


// Public interface of the MySQL Connector/C++
#include <cppconn/mysql_public_iface.h>
#include "filtering.h"
#include "preprocessing.h"

using namespace std;
 
/**
* Usage example for Driver Manager, Connection, (simple) Statement, ResultSet
*/

int main(int argc, char** argv) {
	
	string productName = "Camera";	
	stringstream sql;
	
	int clusterN; 
	int conFeatureN;
	int catFeatureN;
	int boolFeatureN;
	int varNamesN;
	int range;  
	int session_id;
	int repW; 
	int clusterID = 0;
	
	string argu = argv[1];
	int ind, endit, startit, lengthit;
	string var;

	//productName
	var = "product_name";
	ind = argu.find(var, 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit>0){
		productName = (argu.substr(startit, lengthit)).c_str();
	}
	else{
		cout<<"ERROR - Specify a productName"<<endl;
	}
	//session_id
	var = "session_id";
	ind = argu.find(var, 0);
	endit = argu.find("\n", ind);
	startit = ind + var.length() + 2;
	lengthit = endit - startit;
	if (lengthit>0){
		session_id = atoi((argu.substr(startit, lengthit)).c_str());
	}
	
	string tableName = productName;
	tableName.append("s");
	map<const string, int> productNames;
	productNames["camera"] = 1;
	productNames["printer"] = 2;
	
	switch(productNames[productName]){
		
		case 1:
					//productName = "Camera";
					clusterN = 9; 
					conFeatureN= 4;
					catFeatureN= 1;
					boolFeatureN= 0;
					varNamesN= 12;
					range= 2;
					repW = 9; 
					break;
			
		case 2: 	
				//	productName = "Printer";
					clusterN = 9; 
					conFeatureN= 4;
					catFeatureN= 1;
					boolFeatureN= 0;
					varNamesN= 12;
					range= 2;
					repW = 9; 
					break;
		default:
					clusterN = 9; 
					conFeatureN= 4;
					catFeatureN= 1;
					boolFeatureN= 0;
					varNamesN= 12;
					range= 2;
					repW = 9; 
					break;
	}
	
	string* brands = new string [40] ;
	int* mergedClusterIDInput = new int[clusterN];
	bool smallNFlag =false;
	string* indicatorNames = new string[conFeatureN];
	int ** indicators = new int*[conFeatureN];
	double** conFeatureRange = new double* [conFeatureN];
	
	for (int f=0; f<conFeatureN; f++){
		conFeatureRange[f] = new double [2];
		indicators[f] = new int[repW];
		for (int i=0; i<repW; i++){
		indicators[f][i] = 0;
		}
	}
	ostringstream session_idStream;
	
	string *varNames = new string[varNamesN];
	string *catFeatureNames = new string [catFeatureN];
	string *conFeatureNames = new string[conFeatureN];
	double **filteredRange = new double* [conFeatureN];
	bool *conFilteredFeatures = new bool[conFeatureN];   
	bool *catFilteredFeatures = new bool[catFeatureN];
	bool *boolFilteredFeatures = new bool[boolFeatureN];
	map<const string, string*> productFeatures;
   	for(int f=0; f<conFeatureN; f++){
		conFilteredFeatures[f] = 0;
		filteredRange[f] = new double [range];		
	}
	
	for (int f=0; f<catFeatureN; f++){
	    catFilteredFeatures[f] = 0;
	}

    for (int f=0; f<boolFeatureN; f++){
		boolFilteredFeatures[f] = 0;
	}


	//cluster_id
	var = "cluster_id";
	ind = argu.find(var, 0);
	endit = argu.find("\n", ind);
	
	startit = ind + var.length() + 2;
	lengthit = endit - startit;


	if(lengthit>0){
		
		string valueString = argu.substr(startit, lengthit);
		int found = valueString.find("-");
		int mergedClusterN=0;
		while ( found != (int)string::npos){	
			mergedClusterIDInput[mergedClusterN] = atoi((valueString.substr(found+1,1)).c_str());
			found = valueString.find("-", found+2, 1);
			mergedClusterN++; 
		}	
		if (mergedClusterN >0){
			clusterID = -1 * mergedClusterN;
		}
		if (found == (int)string::npos){
				clusterID = atoi((argu.substr(startit, lengthit)).c_str());
		}
	}
	
		
	int brandN = parseInput(varNames, productNames, productName, argu, brands, catFilteredFeatures, conFilteredFeatures, boolFilteredFeatures, filteredRange, 
				varNamesN, conFeatureNames, catFeatureNames, indicatorNames);

    	
	string brand = brands[0];
// Driver Manager

   	sql::mysql::MySQL_Driver *driver;

	sql::Connection	*con;
	sql::Statement	*stmt;
	
	sql::ResultSet	*res;
	sql::ResultSet	*res2;
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

	    #define PORT "3306"       
	 	#define DB  "optemo_development"
		#define HOST hostString    
		#define USER usernameString 
	    #define PASS passwordString 


///////////////////////////////////////////////
		
			try {
						
				// Using the Driver to create a connection
				driver = sql::mysql::get_mysql_driver_instance();
				con = driver->connect(HOST, PORT, USER, PASS);
				stmt = con->createStatement();
				stmt->execute("USE "  DB);
				string command;	
				int size;
				string out = "";
			
				bool reped = false;
			
			if (clusterID == 0){
				command = "SELECT id from ";
				command += tableName;
				command += ";";
 				res = stmt->executeQuery(command);
				size = res->rowsCount();	
			}
			else{
				command = "SELECT id from ";
				command += productName;
				command += "_nodes where cluster_id=";
				ostringstream cid;
				cid<<clusterID;
				command += cid.str();
				command += ";";
				res = stmt->executeQuery(command);
				size = res->rowsCount();
			}	
			int* productIDs = new int [size];
			int productN = filter2(filteredRange, brands, brandN, stmt, res, res2, productIDs, conFilteredFeatures, catFilteredFeatures, clusterID, clusterN, conFeatureN, conFeatureRange, productName, conFeatureNames);
			if (productN> 0){
				if (productN<=repW){
					repW = productN;                 
					smallNFlag = true;
				}
				
				int* reps = new int [repW];		
				int* clusterIDs = new int[repW];
				int* clusterCounts = new int[repW];
				int* mergedClusterIDs;
			
				reped = getRep(reps, productIDs, productN, clusterIDs, clusterCounts, conFeatureN, repW, stmt, res, res2, clusterID, smallNFlag, mergedClusterIDs, mergedClusterIDInput, productName, conFeatureNames);
					
		
				if(reped){
						
					getIndicators(clusterIDs,repW, conFeatureN, indicators, stmt, res, mergedClusterIDs, productName, conFeatureNames);
				}
		
//Generating the output string 
			//	repW = 9;
		
			
				out = generateOutput(indicatorNames, conFeatureN, productN, conFeatureRange, varNames, repW, reps, reped, clusterIDs, mergedClusterIDs, clusterCounts, indicators);
			}
			else{	//productN=0;
				out = "--- !map:HashWithIndifferentAccess \n";
				out.append("result_count: ");
				ostringstream resultCountStream;
				resultCountStream << productN;
				out.append(resultCountStream.str());
				out.append("\n");

			}
		cout<<out<<endl;
		

	// Clean up

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