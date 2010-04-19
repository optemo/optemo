
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

#include </usr/local/include/mysql-connector-c++/driver/mysql_public_iface.h>
#include <time.h>

#include "hClustering.h"
#include "preProcessing.h"
#include "smallNumberClustering.h"

using namespace std;

int main(int argc, char** argv){	
    string path = string(argv[0]);
    int found=path.rfind('/hCluster');
	string logFile = path; 
	logFile.replace (found-7, found,"../../../../log/clustering.log");

	stringstream sql;
	int clusterN;
	int conFeatureN;
	int catFeatureN;
	int boolFeatureN;
	int range;
	int layer = 1;
	int version;
	string var;
	int keepStep = 5;
    string exampleUsage = "Example: " + string(argv[0]) + " Printer us development 9\n";

	//argument is the productName
    if (argc <5){
		cout<<"Wrong number of arguments; you need 4 (product name, region, environment and number of clusters)" << endl << exampleUsage;
		return EXIT_FAILURE;
	}
	string productName = argv[1];
	//cout<<productName<<endl;
	if (!(productName == "camera" || productName == "printer" || productName == "flooring")){
		cout<<"Unrecognized product type. Please enter 'printer', 'pamera', or 'flooring'." << endl << exampleUsage;
		return EXIT_FAILURE;
	}

	string region = argv[2];
	//cout<<region<<endl;
	if ((region != "us") && (region != "ca")){
		cout<<"Wrong Region. Please enter either 'us' or 'ca'." << endl << exampleUsage;
		return EXIT_FAILURE;
	}

	string env = argv[3];
	if ((env != "test") && (env != "development") && (env != "production") && (env != "bestbuy")){
		cout<<"Wrong environment. You should either enter 'test', 'development', 'bestbuy' or 'production'." << endl << exampleUsage;
		return EXIT_FAILURE;
	}

	clusterN = atoi(argv[4]);
	if (clusterN<2 || clusterN>9){
		cout<<"Please enter a number of clusters between 2 and 9" << endl << exampleUsage;
		return EXIT_FAILURE;
	}

	string tableName = productName;
	tableName.append("s");
	map<const string, int> productNames;
	productNames["camera"] = 1;
	productNames["printer"] = 2;
    productNames["flooring"] = 3;
	double* weights;
	map<const string, double> weightHash;
	weightHash["price"] = 1;
	// weightHash["itemweight"] = 0;
    weightHash["opticalzoom"] = 4;
    weightHash["displaysize"] = 1;
    weightHash["maximumresolution"] = 1;
	// weightHash["slr"] = 0;
	// weightHash["waterproof"] = 0;
	// When entering a new product, conFeatureN is the number of continuous features, catFeatureN is the number of categorical features. range is usually 2 (min and max).
	// Look in, for example, app/models/camera.rb to see where this is specified. 
	// Long-term goal: Go straight to the camera table in the database to get this information
	switch(productNames[productName]) {
		case 1:
            conFeatureN = 4;
            catFeatureN = 1;
            boolFeatureN = 0;
            range = 2;
            break;
		case 2:
            conFeatureN = 5;
            catFeatureN = 1;
            boolFeatureN = 2;
            weights = new double [conFeatureN + boolFeatureN];
            range = 2;
            weights[0] = 1;
            for (int f=1; f<conFeatureN-1; f++){
            	weights[f] = 1;
            }					
            	weights[conFeatureN-1] = 1;

                for (int f=0; f<boolFeatureN; f++){
                	weights[conFeatureN+f] = 1;
                }
            break;
		case 3:
            conFeatureN = 3; // Thickness has been taken out for now
            catFeatureN = 4; // This should be 4, but right now just set it up for brand only.
            boolFeatureN = 0;
            range = 2;
            break;

		default:		
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
	string command, command2, nullCheck;

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
    // conFeatureNames[4]="itemweight";

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

	nullCheck = "Select * from ";
	nullCheck += productName;
	nullCheck += "s where (instock=1 AND ((price IS NULL) ";
    for (int f=1; f<conFeatureN; f++){
        nullCheck += "OR (";
        nullCheck += conFeatureNames[f];
        nullCheck += " IS NULL "; 
        nullCheck += ") ";
    }
    nullCheck += "))";

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
    string ymlFile = path;
    ymlFile.replace (found-7, found,"../../../../config/database.yml");

    myfile.open(ymlFile.c_str());

    if (myfile.is_open()){
        while (! myfile.eof()){
            getline (myfile,line);
			stringstream ss(line);
			while(ss>>buf){
				tokens.push_back(buf);
				i++;
			}
		}
	    myfile.close();
    } else {
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
    	sql::Driver * driver = get_driver_instance();

	    std::auto_ptr< sql::Connection > con(driver->connect(HOST, USER, PASS));        
		sql::Statement*  stmt(con->createStatement());

		command = "USE ";
		command += databaseName;

		stmt->execute(command);

		res = stmt->executeQuery(nullCheck);

	    if (res->rowsCount() >0){
	      cout<<"There are some null values in "<<productName<<"s table"<<endl;
	    }
        else {
            cout << "There are no null values in "<<productName<<"s table"<<endl;
        }
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
		cout<<"version is "<<version<<endl;

	   if (version > keepStep){
			///Archiving the old clusters and nodes & deleteing the old ones
			command2 = "INSERT into ";
			command2 += productName;
			command2 += "_clusters_archive select * from ";
			command2 += productName;
			command2 += "_clusters where version=";
			ostringstream vstr1; 
			vstr1 << version-keepStep;
			command2 += vstr1.str();
			command2 += " and region=\'";
			command2 += region;
			command2 += "\';";	
			stmt->execute(command2);

			command2 = "INSERT into ";
			command2 += productName;
			command2 += "_nodes_archive select * from ";
			command2 += productName;
			command2 += "_nodes where version=";
			ostringstream vstr2; 
			vstr2 << version - keepStep;
			command2 += vstr2.str();
			command2 += " and region=\'";
			command2 += region;
			command2 += "\';";

			stmt->execute(command2); 
		}
        bool clustered = 0;
        res = stmt->executeQuery(filteringCommand); 
        int maxSize = res->rowsCount();
        time_t rawtime;
        struct tm * timeinfo;

        time ( &rawtime );
        timeinfo = localtime( &rawtime );
        ofstream myfile2;

        myfile2.open(logFile.c_str(), ios::app);
        myfile2 <<endl<<timeinfo->tm_year+1900<<"-"<< timeinfo->tm_mon+1<<"-"<<timeinfo->tm_mday<<" "<< timeinfo->tm_hour<<endl;
        myfile2<<"Version: "<<version<<endl;

        while (maxSize>clusterN){

        	for (int j=0; j<conFeatureN; j++){
        		average[j] = 0.0;
        	}
            cout << "maxSize: " << maxSize << " and clusterN: " << clusterN << endl;
        	maxSize = hClustering(layer, clusterN,  conFeatureN,  boolFeatureN, average, conFeatureRange, conFeatureRangeC, res, res2, resClus, resNodes, 
        			stmt, conFeatureNames, boolFeatureNames, productName, weightHash, version, region);	
        	myfile2<<"layer "<<layer<<endl;
        	cout<<"layer "<<layer<<endl;
        	layer++;
        	clustered = 1;
        }
		if (clustered) {
    		leafClustering(conFeatureN, boolFeatureN, clusterN, conFeatureNames, boolFeatureNames,res, res2, res3, stmt, productName, version, region);	
    		myfile2<<"layer "<<layer<<endl;
        } else {
			smallNumberClustering(conFeatureN, boolFeatureN, clusterN, conFeatureNames, boolFeatureNames, res, res2, stmt, productName, version, region);	
			myfile2<<"layer "<<layer<<endl;
		}

        //Clearing the old clusters and nodes
        command2 = "DELETE from ";
        command2 += productName;
        command2 += "_clusters where version=";
        ostringstream vstr3; 
        vstr3 << version-keepStep;
        command2 += vstr3.str();
        command2 += " and region=\'";
        command2 += region;
        command2 += "\';";
        stmt->execute(command2);

        command2 = "DELETE from ";
        command2 += productName;
        command2 += "_nodes where version=";
        ostringstream vstr4; 
        vstr4 << version-keepStep;
        command2 += vstr4.str();
        command2 += " and region=\'";
        command2 += region;
        command2 += "\';";
        stmt->execute(command2);

        myfile2<<"The end."<<endl;
        myfile2.close();

        } catch (sql::SQLException &e) {
            cout << "# ERR: SQLException in " << __FILE__;
            cout << "(" << __FUNCTION__ << ") on line " << __LINE__ << endl;
            cout << "# ERR: " << e.what();
            cout << " (MySQL error code: " << e.getErrorCode();
            cout << ", SQLState: " << e.getSQLState() << " )" << endl;
            return EXIT_FAILURE;
        }
    return 1; //EXIT_SUCCESS;
}
