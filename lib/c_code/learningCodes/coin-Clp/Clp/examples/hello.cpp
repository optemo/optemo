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
	int visitId = 8963;
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
			cout<<"prefs count is "<<resPref->rowsCount()<<endl;;
			ClpSimplex model3;
			string productName = "Camera";
			int conFeatureN = 2;
			string* conFeatureNames = new string[conFeatureN];
			conFeatureNames[0] = "price";
			conFeatureNames[1] = "maximumresolution";
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

cout<<"after"<<endl;

ClpSimplex  modelByRow, modelByColumn;

  // This very simple example shows how to create a model by row and by column
  int numberRows=3;
  int numberColumns=5;
  // Rim of problem is same in both cases
  double objective [] = {1000.0,400.0,500.0,10000.0,10000.0};
  double columnLower[] = {0.0,0.0,0.0,0.0,0.0};
  double columnUpper[] = {COIN_DBL_MAX,COIN_DBL_MAX,COIN_DBL_MAX,20.0,20.0};
  double rowLower[] = {20.0,-COIN_DBL_MAX,8.0};
  double rowUpper[] = {COIN_DBL_MAX,30.0,8.0};
  // Matrix by row
  int rowStart[] = {0,5,10,13};
  int column[] = {0,1,2,3,4,
		  0,1,2,3,4,
		  0,1,2};
  double elementByRow[] = {8.0,5.0,4.0,4.0,-4.0,
			 8.0,4.0,5.0,5.0,-5.0,
			 1.0,-1.0,-1.0};
  // Matrix by column
  int columnStart[] = {0,3,6,9,11,13};
  int row[] = {0,1,2,
	       0,1,2,
	       0,1,2,
	       0,1,
	       0,1};
  double elementByColumn[] = {8.0,8.0,1.0,
			      5.0,4.0,-1.0,
			      4.0,5.0,-1.0,
			      4.0,5.0,
			      -4.0,-5.0};
  int numberElements;
  // Do column version first as it can be done two ways
  // a) As one step using matrix as stored
  modelByColumn.loadProblem(numberColumns,numberRows,columnStart,row,elementByColumn,
			    columnLower,columnUpper,objective,
			    rowLower,rowUpper);
  // Solve
  modelByColumn.dual();
  // check value of objective
 // assert (fabs(modelByColumn.objectiveValue()-76000.0)<1.0e-7);



  //ClpSimplex  model;
  //int status;
  //// Keep names
  //if (argc<2) {
  //  status=model.readMps("o",true);
  //} else {
  //  status=model.readMps(argv[1],true);
  //}
  //if (status)
  //  exit(10);
  //
  //int numberColumns = model.numberColumns();
  //int numberRows = model.numberRows();
  //
  //if (numberColumns>80||numberRows>80) {
  //  printf("model too large\n");
  //  exit(11);
  //}


// printf("This prints x wherever a non-zero elemnt exists in matrix\n\n\n");
//
// char x[81];
//
// int iRow;
// // get row copy
// CoinPackedMatrix rowCopy = *model.matrix();
// rowCopy.reverseOrdering();
// const int * column = rowCopy.getIndices();
// const int * rowLength = rowCopy.getVectorLengths();
// const CoinBigIndex * rowStart = rowCopy.getVectorStarts();
// 
// x[numberColumns]='\0';
// for (iRow=0;iRow<numberRows;iRow++) {
//   memset(x,' ',numberColumns);
//   for (int k=rowStart[iRow];k<rowStart[iRow]+rowLength[iRow];k++) {
//     int iColumn = column[k];
//     x[iColumn]='x';
//   }
//   printf("%s\n",x);
// }
// printf("\n\n");
  return 0;
}    
