/* Copyright (C) 2004, International Business Machines Corporation 
   and others.  All Rights Reserved.

   This sample program is designed to illustrate programming 
   techniques using CoinLP, has not been thoroughly tested
   and comes without any warranty whatsoever.

   You may copy, modify and distribute this sample program without 
   any restrictions whatsoever and without any payment to anyone.
*/

/* This shows how to provide a simple picture of a matrix.
   The default matrix will print Hello World
*/

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


#include "ClpSimplex.hpp"
#include <../../../cppconn/mysql_public_iface.h>

#include "formulate.h"

int main (int argc, const char *argv[])
{
		stringstream sql;


	//}
	// Driver Manager

	sql::mysql::MySQL_Driver *driver;
	
    driver = sql::mysql::get_mysql_driver_instance();

  	sql::Connection	*con;
	sql::Statement	*stmt;
	sql::Statement	*stmt2;
	sql::Statement	*stmt3;
	
	sql::ResultSet	*resPref;
	sql::ResultSet	*resFactor;
	int session = 328;  
	string productName= "Printer"; 
    if (argc<3){
   		cout<<"Err - Enter product type and optemo_session id"<<endl;
		return 0;
   	}else{
		productName = argv[1];
   		session = atoi(argv[2]);
		
    }

	int conFeatureN = 5;
	string* conFeatureNames = new string[conFeatureN];
    double* solutions = new double[conFeatureN];

	ostringstream sessionStr;
	sessionStr << session;
	string databaseName = "prefpwk";
	string tableName = "piwik_log_preferences";
	    #define PORT "3306"       
		#define DB   databaseName
		#define HOST "optemo"    
		#define USER "remoteaccess" 
	    #define PASS "pre78fs" 

		try {
	
			// Using the Driver to create a connection
			driver = sql::mysql::get_mysql_driver_instance();
			con = driver->connect(HOST, PORT, USER, PASS);
			stmt = con->createStatement();
		
			stmt2 = con->createStatement();
			stmt3 = con->createStatement();
			string command = "USE ";
			//string prefTable = "piwik_log_preferences";
			command += databaseName;
			stmt->execute(command);

			command= "SELECT * from ";
			command += tableName;
			command += " where product_picked IS NOT NULL and optemo_session=";
			command += sessionStr.str();
			command += " order by servertime DESC limit 100;";
			resPref = stmt->executeQuery(command);
			resFactor = resPref;
		
		
			
			conFeatureNames[0] = "resolutionmax";
			conFeatureNames[1] = "price";
			conFeatureNames[2] = "ppm";
			conFeatureNames[3] = "itemwidth";
			conFeatureNames[4] = "paperinput";
        	stmt2->execute("USE optemo_production");
				
			formulate(stmt2, resPref, resFactor, productName,conFeatureNames, conFeatureN, solutions);	
		
		  
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

  return 0;
}    
