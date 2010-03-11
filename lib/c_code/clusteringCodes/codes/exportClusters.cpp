
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
   
	string logFile = path; 
	
     	
	string clustersFile = "~/clustersMatlab/out_hartigan_qmeasure.tree";
 	string nodesFile = "~/clustersMatlab/out_hartigan_qmeasure.leaf";
	string env = "development";
	
	stringstream sql;
	int clusterN;
	int conFeatureN;
	int catFeatureN;
	int boolFeatureN;
	int range;
	int layer = 1;
	int version;
	conFeatureN = 4;
	string * conFeatureNames = new string [conFeatureN];
	
	conFeatureNames[0] = "price";
	conFeatureNames[1] = "maximumresolution";
	conFeatureNames[2] = "displaysize";
	conFeatureNames[3] = "opticalzoom";
	string command = "";
	string command2 = "";

   sql::Statement	*stmt;
	
	sql::ResultSet	*res;
	sql::ResultSet	*res2;
	sql::ResultSet	*res3;
    sql::ResultSet	*resClus;
    sql::ResultSet	*resNodes;
	
	string line;
	string buf; 
	vector<string> tokens;
	vector<string> tokens2;
	vector<string> tokens3;
	ifstream myfile;
	int i=0;
//	string ymlFile = "/optemo/site/config/database.yml";
    
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

	
	while (tokens.size() > 0 && tokens.at(0) != env){
		tokens.erase(tokens.begin());
	}
	
	//development:
	//    adapter: mysql
	//    database: optemo_development
	//    username: maryam
	//    password: sCbub3675NWnNZK2
	//    host:     jaguar    
	
	
	
	//cout<<"env is :"<<env<<endl;
    //
	//string databaseString = tokens.at(findVec(tokens, "database:") + 1);
	//	  cout<<"HERE"<<endl;
	//string usernameString = tokens.at(findVec(tokens, "username:") + 1);
	//string passwordString = tokens.at(findVec(tokens, "password:") + 1);
	//string hostString = tokens.at(findVec(tokens, "host:") + 1);
	//string databaseName = tokens.at(findVec(tokens, "database:") + 1);
	
	string databaseName = "optemo_development";
	string usernameString = "optemo";
	string passwordString = "tinydancer";
	string hostString = "jaguar";
	


	    #define PORT "3306"       
		#define DB   "optemo_development"
		#define HOST "jaguar"    
		#define USER "maryam" 
	    #define PASS "sCbub3675NWnNZK2"

///////////////////////////////////////////////
		
			try {
	

				sql::Driver * driver = get_driver_instance();
			    std::auto_ptr< sql::Connection > con(driver->connect(HOST, USER, PASS));        
				sql::Statement*  stmt(con->createStatement());

				command = "USE ";
				command += databaseName;
				stmt->execute(command);         
				version = 22;
				stringstream verStr; 
				verStr<< version;
	  
			
/*				command = "delete from camera_nodes where version=";
				command += verStr.str();
				command += ";";
				stmt->execute(command);
				
				command = "delete from camera_clusters where version=";
				command += verStr.str();
				command += ";";
				stmt->execute(command);
*/		
		
			  ifstream myfile2;
			  ifstream myfile3;
			  
	     	  myfile2.open("/Users/maryam/clustersMatlab/out_hartigan_qmeasure.tree");	
			  myfile3.open("/Users/maryam/clustersMatlab/out_hartigan_qmeasure.leaf");
/*
			i=0;
			string tok = "";
			int c1, c2, len, cId, pId;
			 if (myfile2.is_open()){	
				while (! myfile2.eof()){
					getline (myfile2,line);
					stringstream ss(line);
					while(ss>>buf){
						tokens2.push_back(buf);
							
						i++;
					}	
						
				}
					for (int j=0; j<i; j++){
						tok = tokens2.at(j); 
						c1 = tok.find_first_of(",") + 1;
						c2 = tok.find_last_of(",");
						len = c2 - c1;
						
						command = "INSERT into camera_clusters (id, parent_id, layer, version, region) VALUES (";
						command += tok.substr(c1, len);
						command += ", ";
						command += tok.substr(c2+1);
						command += "-1, ";
						command += tokens2.at(j)[0];
						command += "-1, ";
						command += verStr.str();
						command += ", \'us\');";
						stmt->execute(command);						
					}
			}
			else{
				cout<<"cant open the tree file"<<endl;
			}	

			string clusterId, parent_id;        
        	i=0;
           if (myfile3.is_open()){
				while (! myfile3.eof()){
					getline (myfile3,line);
					stringstream ss(line);
					while(ss>>buf){
						tokens3.push_back(buf);
						i++;
					}	
				}	
				for (int j=0; j<i; j++){
					
					tok = tokens3.at(j);
					c1 = tok.find_first_of(",");
					string productId = tok.substr(0, c1);
					clusterId = tok.substr(c1+1);
					command = "INSERT into camera_nodes (product_id, cluster_id, version, region) VALUES (";
					command +=  productId;
					command += ", ";
					command += clusterId;
					command += "-1, ";
					command += verStr.str();
					command += ", \'us\');";
					stmt->execute(command);
					
					command2 = "select parent_id from camera_clusters where id=";
					command2 += clusterId;
					command2 += "-1;";
				
					res = stmt->executeQuery(command2);
					res->next(); 
					int pId = res->getInt("parent_id");
					stringstream pIdS;
					pIdS << pId;
					string parentId = pIdS.str();
					
					command = "INSERT into camera_nodes (product_id, cluster_id, version, region) VALUES (";
					command +=  productId;
					command += ", ";
					command += parentId; 
					command += "-1, ";
					command += verStr.str();
					command += ", \'us\');";
			      
			
					while (pId >1){
					   stmt->execute(command);
					   clusterId = parentId;   
					   command2 = "select parent_id from camera_clusters where id=";
					   command2 += clusterId;
					   command2 += ";";
					   res = stmt->executeQuery(command2);
					   res->next();
					   pId = res->getInt("parent_id");
					   stringstream pIdS2;
					   pIdS2 << pId;
					   parentId = pIdS2.str();
					
					   command = "INSERT into camera_nodes (product_id, cluster_id, version, region) VALUES (";
					   command +=  productId;
					   command += ", ";
					   command += parentId; 
					   command += "-1, ";
					   command += verStr.str();
					   command += ", \'us\');";
      				   clusterId = parentId;
					
					}
					//Filling out the other info in the node_table


				   command = "update camera_nodes set brand = (select brand from cameras where id=";
				   command += productId;
				//   command += "), ";
				//   command += "utility = (select utility from camera_nodes where version=59 and product_id=";
				//   command += productId;  
				   command += ")";
				   for (int f=0; f<conFeatureN; f++){
				   	command += ", ";
				   	command += conFeatureNames[f]; 
				   	command += "=";
				   	command += "(select ";
				   	command += conFeatureNames[f];
				   	command += " from cameras where id=";
				   	command += productId;
				   	command += ")";
				   }
				   command += "where product_id=";
				   command += productId;
				   command += " and version=";
				   command += verStr.str();
				   command += ";";	
					
				//cout<<"command is "<<command<<endl;
				stmt->execute(command);
 				}	
				cout<<"the end of if"<<endl;		
		   }
		
		  else{
			cout<<"can't open leaf file"<<endl;
		}
*/
		cout<<"here"<<endl;
		command = "SELECT id from camera_clusters where version=";
		command += verStr.str();
		res = stmt->executeQuery(command);
		int size;
		double maximumresolutionmax;
		string command3 = "";
		while(res->next()){
			int cId = res->getInt("id");
			stringstream clusId;
			clusId << cId;
			command = "select max(maximumresolution), min(maximumresolution), max(opticalzoom), min(opticalzoom), max(displaysize), min(displaysize), max(price), min(price) from camera_nodes where cluster_id=";
			command += clusId.str();
			command += " and version=";
			command += verStr.str();
			command += ";"; 
			//cout<<"command is "<<command<<endl;
			res2 = stmt->executeQuery(command);
			size = res2->rowsCount();
			stringstream sizeS;
			sizeS << size;
			
			res2->next();
		
			for (int f=0; f<conFeatureN; f++){
			
				command = "UPDATE camera_clusters set ";
				command += conFeatureNames[f];
				command += "_max=";
				stringstream fstr; 
				stringstream fstr2;
				command3 = "max(";
				command3 += conFeatureNames[f];
				command3 += ")";
				fstr << res2->getDouble(command3);
				command += fstr.str();
				command += ", ";
				command += conFeatureNames[f];
				command += "_min=";
				command3 = "min(";
				command3 += conFeatureNames[f];
				command3 += ")";
				fstr2 << res2->getDouble(command3);
				command += fstr2.str();
				command += " where id=";
				command += clusId.str();
				command += " and version=";
				command += verStr.str();
				command += ";";
				
				stmt->execute(command);
			}	
			
			//cluster_size
			command = "select count(id) from camera_nodes where cluster_id=";
			command += clusId.str();
			
			res2= stmt->executeQuery(command);
			res2->next();
			
			stringstream sizestr; 
			sizestr << res2->getInt("count(id)");
			command = "UPDATE camera_clusters set cluster_size=";
			command += sizestr.str();
			command += ";";
			stmt->execute(command);
				
			//brands
			
			command ="select distinct(brand) from camera_nodes where cluster_id=";
			command += clusId.str();
			string brands ="";
			res2= stmt->executeQuery(command);
			res2->next();
			brands += res2->getString("brand");
			
			while(res2->next()){
				brands +="*";
				brands += res2->getString("brand");
			}
			
			command = "UPDATE camera_clusters set brand=\'";
			command += brands;
			command += "\';";
			
			stmt->execute(command);
		
		}


	//	command = "select count(id) from camera_nodes where cluster_id=";
	//	command += cluster_id;
		
		
//   	command = "Select * from cameras;";
//   	res = stmt->executeQuerry(command);
//   	
//   	sized = res->rowsCount();
//   	data = new double*[sized];
//   
//   	for(int j=0; j<sized; j++){
//   			data[j] = new double[conFeatureN+boolFeatureN];  
//   	}
//   	brands = new string [sized];
//   	idA = new int[sized];	
//   	int saleprice = 0;
//   	int price = 0;
//   
//   	size = 0;
//   	while (res->next()) 
//   	{
//   	
//   			saleprice = res->getInt("price");
//   			price = saleprice;
//   			data[size][0] = price;
//   		    
//			
//   			for (int f=1; f<conFeatureN; f++){
//					data[size][f] = res->getDouble(conFeatureNames[f]);
//   	
//				}	
//
//				for (int f=0; f<boolFeatureN; f++){
//					data[size][conFeatureN+f] = res->getDouble(boolFeatureNames[f]);
//   	
//				}
//			
//				idA[size] = res->getInt("id"); 	
//	    		brands[size] = res->getString("brand");
//				for (int f=0; f<conFeatureN; f++){
//					average[f] += data[size][f];
//				}
//   			size++;
//   								
//   	}

 myfile2.close();
 myfile3.close();


 	} catch (sql::SQLException &e) {

		return EXIT_FAILURE;

	} 


return 1; //EXIT_SUCCESS;
}
