
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

#include <cppconn/mysql_public_iface.h>
//
#include "hClustering.h"
#include "preProcessing.h"
#include "smallNumberClustering.h"
using namespace std;

int main(int argc, char** argv){	

	stringstream sql;
	int clusterN;
	int conFeatureN;
	int catFeatureN;
	int boolFeatureN;
	int range;
	int layer = 1;
	int version;
	string var;
	
	//argument is the productName
    if (argc <4){
		cout<<" Wrong number of arguments, you need 3 (product name, region and environment)"<<endl;
		return EXIT_FAILURE;
	}
	string productName = argv[1];
	//cout<<productName<<endl;
	if ((productName != "camera") && (productName != "printer")){
		cout<<"Wrong Product Type! You should enter either printer or camera"<<endl;
		return EXIT_FAILURE;
	}
	
	string region = argv[2];
	//cout<<region<<endl;
	if ((region != "us") && (region != "ca")){
		cout<<"Wrong Region! You should enter either us or ca"<<endl;
		return EXIT_FAILURE;
	}
	
	string env = argv[3];
	if ((env != "test") && (env != "development") && (env != "production") && (env != "bestbuy")){
		cout<<"Wrong environment! You should either enter test, development, bestbuy or production"<<endl;
		return EXIT_FAILURE;
	}
	

	string tableName = productName;
	tableName.append("s");
	map<const string, int> productNames;
	productNames["camera"] = 1;
	productNames["printer"] = 2;
	double* weights;
	map<const string, double> weightHash;
	weightHash["price"] = 1;
		//weightHash["itemweight"] = 1;
		weightHash["opticalzoom"] = 5;
		weightHash["displaysize"] = 0.5;
		weightHash["maximumresolution"] = 1;
		//weightHash["minimumfocallength"] = 0.08;
		//weightHash["maximumfocallength"] = 0.08;
		//weightHash["minimumshutterspeed"] = 1;
		//weightHash["maximumshutterspeed"] = 1;
	    //weightHash["bulb"] = 0.001;
		//weightHash["slr"] = 1;
		//weightHash["waterproof"] = 0.5;
	switch(productNames[productName]){
		
		case 1:
					clusterN = 9; 
					conFeatureN= 4;
					catFeatureN= 1;
					boolFeatureN= 0;
					weights = new double [conFeatureN + boolFeatureN];
					for (int f=0; f<conFeatureN; f++){
						weights[f] = 1;
					}
					//weights[conFeatureN] = 2;
					//weights[conFeatureN+1] = 0.01;
					//weights[conFeatureN+2] = 0.01;
					range= 2;
					break;
			
		case 2:
					clusterN = 9; 
					conFeatureN= 5;
					catFeatureN= 1;
					boolFeatureN= 2;
					weights = new double [conFeatureN + boolFeatureN];
					range= 2;
					weights[0] = 1;
					for (int f=1; f<conFeatureN; f++){
						weights[f] = 1;
					}					
					//	weights[conFeatureN-1] = 0.9;

					    for (int f=0; f<boolFeatureN; f++){
					    	weights[conFeatureN+f] = 0.5;
					    }
					break;
		default:
					clusterN = 9; 
					conFeatureN= 4;
					catFeatureN= 1;
					boolFeatureN= 0;
					range= 2;
					break;
	}

	ostringstream session_idStream;
	ostringstream layerStream;
	layerStream<<layer;

	string nodeString;
	
	string* indicatorNames = new string [conFeatureN + boolFeatureN];

			
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
	
 string filteringCommand = preClustering(productNames, productName, conFeatureNames, catFeatureNames, boolFeatureNames, indicatorNames, region);


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

	env += ":";
	
	while (tokens.size() > 0 && tokens.at(0) != env){
		tokens.erase(tokens.begin());
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
			
				command = "SELECT version from ";
				command += productName;
				command += "_clusters where (region='";
				command += region;
				command += "') order by id DESC LIMIT 1";
				res = stmt->executeQuery(command);

				
				if (res->next()){
					version = res->getInt("version");
					version++;
				}
				else{
					version = 0;
				}
				bool clustered = 0;
			
			    res = stmt->executeQuery(filteringCommand); 
			
				int maxSize = res->rowsCount();
			
				cout<<"Version: "<<version<<endl;	
			   while (maxSize>clusterN){
							
					for (int j=0; j<conFeatureN; j++){
						average[j] = 0.0;
					}
					maxSize = hClustering(layer, clusterN,  conFeatureN,  boolFeatureN, average, conFeatureRange, conFeatureRangeC, res, res2, resClus, resNodes, 
							stmt, conFeatureNames, boolFeatureNames, productName, weightHash, version, region);	
					cout<<"layer "<<layer<<endl;
					layer++;
					clustered = 1;
				}
				if (clustered){
				leafClustering(conFeatureN, boolFeatureN, clusterN, conFeatureNames, boolFeatureNames, res, res2, res3, stmt, productName, version, region);	
				cout<<"layer "<<layer<<endl;
			}else{
					smallNumberClustering(conFeatureN, boolFeatureN, clusterN, conFeatureNames, boolFeatureNames, res, res2, stmt, productName, version, region);	
					cout<<"layer "<<layer<<endl;
				}
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
