
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

//#include "coin-Clp/include/coin/ClpSimplex.hpp"
#include <cppconn/mysql_public_iface.h>

using namespace std;

int main(int argc, char** argv){	

	stringstream sql;
	

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
	int visitId = 2175;
	string databaseName = "optemo_development";
	    #define PORT "3306"       
		#define DB   databaseName
		#define HOST "jaguar"    
		#define USER "maryam" 
	    #define PASS "sCbub3675NWnNZK2"
	
///////////////////////////////////////////////
		
			try {
		
				// Using the Driver to create a connection
				driver = sql::mysql::get_mysql_driver_instance();
				cout<<"before"<<endl;
				con = driver->connect(HOST, PORT, USER, PASS);
				stmt = con->createStatement();
				string command = "USE ";
				//string prefTable = "piwik_log_preferences";
				command += databaseName;
			//	command= "SELECT  from ";
				stmt->execute(command);
			
			
			
				cout<<"after"<<endl;
		
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
