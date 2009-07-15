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

#include <stdexcept>
#include "mysql_connection.h"
#include <cppconn/driver.h>
#include <cppconn/exception.h>
#include <cppconn/resultset.h>
#include <cppconn/statement.h>

#define HOST "jaguar"
#define USER "maryam"
#define PASS "sCbub3675NWnNZK2"
#define DB "optemo_development"


int main(int argc, char** argv){
	
	stringstream sql;
	string command, command2;
	int size;
	cout<<"in BarrierConnect"<<endl;
	
	
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
  
 //   string databaseString = tokens.at(findVec(tokens, "database:") + 1);
 //   string usernameString = tokens.at(findVec(tokens, "username:") + 1);
 //   string passwordString = tokens.at(findVec(tokens, "password:") + 1);
 //   string hostString = tokens.at(findVec(tokens, "host:") + 1);
 //   string databaseName = tokens.at(findVec(tokens, "database:") + 1);
 // 
 //  #define PORT "3306"       
 //  #define DB   databaseName
 //  #define HOST hostString    
 //  #define USER usernameString 
 //  #define PASS passwordString
	#define PORT "3306"       
 	#define DB   databaseName
 	#define HOST hostString    
 	#define USER usernameString 
 	#define PASS passwordString
	
	
	// Driver Manager

	try {
		sql::Driver * driver = get_driver_instance();
		
		// Connection, (simple, not prepared) Statement, Result Set
		std::auto_ptr< sql::Connection > con(driver->connect(HOST, USER, PASS));
		std::auto_ptr< sql::Statement > stmt(con->createStatement());
		
	    string command = "USE ";
		command += databaseName; 
       
        std::auto_ptr< sql::ResultSet > res(stmt->executeQuery(command));
	
		int session_id = 24; 
		string productName = "Printer";
	
	//	command = "SELECT * from factors where product_type=";
	//	command += productName;
	//	command += ";";
	//	cout<<command<<endl;
		
		
   	command += "Select * from preference_relations where session_id=";
   	ostringstream sids;
   	sids << session_id;
   	command += sids.str();
         
   	size = res->rowsCount();
   	double** utilities = new double*[2];
   	utilities[0] = new double [size];
   	utilities[1] = new double [size];
 
   	int i = 0;
   	int hId, lId;
    while(res->next()){
   	
   	   	 hId = res->getInt("higher");	
   	   	 lId = res->getInt("lower");
		 command2 = "SELECT from factors where product_id=";
		 ostringstream lst, hst;
		 lst << res->getInt("lower");
		 hst << res->getInt("higher");
	}		
				  

	 }catch (std::runtime_error &e) {
			/* Exception is not caused by the MySQL Server */

			return EXIT_FAILURE;
	}

	return 1; //EXIT_SUCCESS;
	}	
	