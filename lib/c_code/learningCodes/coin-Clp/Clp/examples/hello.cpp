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
	
	sql::ResultSet	*resPref;
	sql::ResultSet	*resFactor;
	sql::ResultSet	*res3;
    sql::ResultSet	*resClus;
    sql::ResultSet	*resNodes;
	int visitId = 8125;
	ostringstream visitIdStr;
	visitIdStr << visitId;
	string databaseName = "optemo_development";
	string tableName = "prefs";
	    #define PORT "3306"       
		#define DB   databaseName
		#define HOST "jaguar"    
		#define USER "maryam" 
	    #define PASS "sCbub3675NWnNZK2" 

		try {
	
			// Using the Driver to create a connection
			driver = sql::mysql::get_mysql_driver_instance();
			con = driver->connect(HOST, PORT, USER, PASS);
			stmt = con->createStatement();
			string command = "USE ";
			//string prefTable = "piwik_log_preferences";
			command += databaseName;
			stmt->execute(command);
			command= "SELECT * from ";
			command += tableName;
			command += " where product_picked IS NOT NULL and idvisit=";
			command += visitIdStr.str();
			command += " order by servertime DESC limit 20;";
			resPref = stmt->executeQuery(command);
			ClpSimplex model3;
			string productName = "Camera";
			int conFeatureN = 4;
			string* conFeatureNames = new string[conFeatureN];
			conFeatureNames[0] = "maximumresolution";
			conFeatureNames[1] = "price";
			conFeatureNames[2] = "displaysize";
			conFeatureNames[3] = "opticalzoom";
			formulate(stmt, resPref, resFactor, model3, productName,conFeatureNames, conFeatureN);	

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
