
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
#include "filtering.h"


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
	int session_id = 1; 
	int clusterID = 0;
	
	bool smallNFlag =false;
	
	ostringstream session_idStream;

			
	string *varNames = new string[varNamesN];	
	string *catFeatureNames = new string[catFeatureN];
	string *boolFeatureNames = new string [boolFeatureN];
	string *conFeatureNames = new string[conFeatureN];
	double **filteredRange = new double* [conFeatureN];
	bool *conFilteredFeatures = new bool[conFeatureN];   
	bool *catFilteredFeatures = new bool[catFeatureN];
	bool *boolFilteredFeatures = new bool[boolFeatureN];
	
	
	catFeatureNames[0]= "brand";
	conFeatureNames[0]= "price";
	conFeatureNames[1]= "displaysize";  
    conFeatureNames[2]= "opticalzoom";
    conFeatureNames[3]= "maximumresolution";


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

	string argu = argv[1];
	int ind, endit, startit, lengthit;
	string var;

	varNames[0] = "session_id";
	varNames[1] = "cluster_id";
	varNames[2] = "brand";
	varNames[3] = "price_min";
	varNames[4] = "price_max";
	varNames[5] = "displaysize_min";
	varNames[6] = "displaysize_max";
	varNames[7] = "opticalzoom_min";
	varNames[8] = "opticalzoom_max";
	varNames[9] = "maximumresolution_min";
	varNames[10] = "maximumresolution_max";

	
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
					if (brand == "All Brands"){
						catFilteredFeatures[0] = 0;
					}
		   }

		   else if(var == "cluster_id"){
			    	clusterID = atoi((argu.substr(startit, lengthit)).c_str());
	
				
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
			//    res = stmt->executeQuery("SELECT * FROM cameras"); 
				string command;	
				int clusterIDN;
				int size;
				string out = "";
				int repW = 9;
				bool reped = false;
				
			if (clusterID == 0){
				command = "SELECT id from cameras;";
				res = stmt->executeQuery(command);
				size = res->rowsCount();
			}
			else{
				int parentID; 
				command = "SELECT id from nodes where cluster_id=";
				ostringstream cid;
				cid<<clusterID;
				command += cid.str();
				command += ";";
				res = stmt->executeQuery(command);
				size = res->rowsCount();
			//	repW--;
			}	
			int* cameraIDs = new int [size];
			int ** indicators = new int*[conFeatureN];
			double** conFeatureRange = new double* [conFeatureN];
			for (int f=0; f<conFeatureN; f++){
				conFeatureRange[f] = new double [2];
				indicators[f] = new int[repW];
				for (int i=0; i<repW; i++){
				indicators[f][i] = 0;
				}
			}
		
			int cameraN = filter2(filteredRange, brand, stmt, res, res2, cameraIDs, conFilteredFeatures, catFilteredFeatures, clusterID, clusterN, conFeatureN, conFeatureRange);
			if (cameraN> 0){
				if (cameraN<=repW){
					repW = cameraN;                 
					smallNFlag = true;
				}
				int* reps = new int [repW];		
				int* clusterIDs = new int[repW];
				int* clusterCounts = new int[repW];
				
				reped = getRep2(reps, cameraIDs, cameraN, clusterIDs, clusterCounts, conFeatureN, repW, stmt, res, res2, clusterID, smallNFlag);
		
				if(reped){
					getIndicators4(clusterIDs,repW, conFeatureN, indicators, stmt, res);
				}
			
//Generating the output string 
			
					string* indicatorNames = new string[4];
					indicatorNames[0] = "Price";
					indicatorNames[1] = "Display Size";
					indicatorNames[2] = "Optical Zoom";
					indicatorNames[3] = "MegaPixels";
					out = "--- !map:HashWithIndifferentAccess \n";
					out.append("result_count: ");
					ostringstream resultCountStream;
				
					resultCountStream << cameraN;
					out.append(resultCountStream.str());
					out.append("\n");
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
					out.append("cameras: \n");
				    for(int c=0; c<repW; c++){
						    out.append("- ");
					        std::ostringstream oss; 		  
						 	oss<<reps[c];
							out.append(oss.str()); 
						 	out.append("\n");
					}
				if (reped){
					out.append("clusters: \n");
			        for(int c=0; c<repW; c++){
					       out.append("- ");
				           std::ostringstream oss; 		  
						   oss<<clusterIDs[c];
						   out.append(oss.str()); 
						   out.append("\n");
					} 
				
					out.append("chosen: \n");

					for(int c=0; c<repW; c++){		  
					     	out.append("- {");
					   		out.append("cluster_id: ");
					   		std::ostringstream oss2; 		  
					   		oss2<<clusterIDs[c];
					   		out.append(oss2.str());
					  		out.append(", ");
							out.append("cluster_count: ");
							std::ostringstream oss3; 		  
							oss3<<clusterCounts[c];
							out.append(oss3.str());

					   		for (int f=0; f<4; f++){
								out.append(", ");
								out.append(indicatorNames[f]);
								out.append(": ");
								std::ostringstream oss; 
								oss<<indicators[f][c];
								out.append(oss.str());
							}
					   		out.append("}\n");
					}
				}	
							
}
			else{	//cameraN=0;
				out = "--- !map:HashWithIndifferentAccess \n";
				out.append("result_count: ");
				ostringstream resultCountStream;
				resultCountStream << cameraN;
				out.append(resultCountStream.str());
				out.append("\n");
	
			}	
	
//
   			cout<<out<<endl;

				
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