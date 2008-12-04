/* Copyright (C) 2007-2008 Sun Microsystems

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   There are special exceptions to the terms and conditions of the GPL 
   as it is applied to this software. View the full text of the 
   exception in file EXCEPTIONS-CONNECTOR-C++ in the directory of this 
   software distribution.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* *
* Basic example demonstrating connect and simple queries
*
*/

// Standard C++ includes
#include <stdlib.h>
#include <iostream>
#include <sstream>

// Public interface of the MySQL Connector/C++
#include <cppconn/mysql_public_iface.h>
// Connection parameter and sample data
#include "examples.h"

using namespace std;

/**
* Usage example for Driver Manager, Connection, (simple) Statement, ResultSet
*/
int main() {
	// Driver Manager
	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection	*con;
	sql::Statement	*stmt;
	sql::ResultSet	*res;
    sql::ResultSet	*res2; 
    sql::ResultSet	*res3;
    sql::ResultSet	*res4;    
    
       

	/* sql::ResultSet.rowsCount() returns size_t */
	size_t row;
	stringstream sql;
	int i, affected_rows;

	cout << boolalpha;
	cout << "Connector/C++ connect basic usage example.." << endl << endl;

	try {
		// Using the Driver to create a connection
		driver = sql::mysql::get_mysql_driver_instance();
		con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);

		// Creating a "simple" statement - "simple" = not a prepared statement
		stmt = con->createStatement();

		// Create a test table demonstrating the use of sql::Statement.execute()
		stmt->execute("USE " EXAMPLE_DB);
	//	stmt->execute("DROP TABLE IF EXISTS "EXAMPLE_DB);
//		stmt->execute("CREATE TABLE "EXAMPLE_DB"(id INT, label CHAR(1))");
		cout << "\tTest table created" << endl;

		cout << "\tTest table populated" << endl << endl;


		// Fetching again but using type convertion methods
		res = stmt->executeQuery("SELECT listpriceint FROM cameras"); // ORDER BY id DESC");
		res2 = stmt->executeQuery("SELECT displaysize FROM cameras"); 
		res3 = stmt->executeQuery("SELECT opticalzoom FROM cameras"); 
		res4 = stmt->executeQuery("SELECT maximumresolution FROM cameras"); 
		
		
		//listpriceint
	    //displaysize
		//optical zoom
		//maximumresolution
	
			cout << "\t\tNumber of rows\t";
	//		cout << "res->rowsCount() = " << res->rowsCount() << endl;
			int *listpriceA = new int[res->rowsCount()];
	//		cout << "res2->rowsCount() = " << res2->rowsCount() << endl;
			double *displaysizeA = new double[res2->rowsCount()];
	//		cout << "res3->rowsCount() = " << res3->rowsCount() << endl;
			double *opticalzoomA = new double[res3->rowsCount()];
	  //      cout << "res4->rowsCount() = " << res4->rowsCount() << endl;
		    double *maxResolutionA = new double[res4->rowsCount()]; 

		
	   row = 0;
		i = 0;
		while (res2->next() && res->next() && res3->next() && res4->next()) {
		//	cout << "\t\tFetching row " << row;
			if (res->getInt("listpriceint")>0 && res2->getDouble("displaysize")>0 && res3->getDouble("opticalzoom")>0 && res4->getDouble("maximumresolution")>0){
			    	i++;
					cout << "\tlistprice int = " << res->getInt("listpriceint") <<endl;
				// 	cout << "\tid (boolean) = " << res->getBoolean("id");
					cout << "\t display size = " << res2->getDouble("displaysize") << endl;
		    		cout << "\t optical zoom = " << res3->getDouble("opticalzoom") << endl; 
					cout << "\t maxResolution = " << res4->getDouble("maximumresolution") << endl; 
					cout << "\t i is "<<i<<endl;
					cout<<endl;
		}
			row++;
		}
		delete res;
		delete res2;
		delete res3;
		delete res4;

		cout << endl;
		// Clean up

		delete stmt;
		delete con;

		cout << "done!" << endl;
	} catch (sql::mysql::MySQL_DbcException *e) {
		/*
		The MySQL Connector/C++ throws four different exceptions:

		- sql::mysql::MySQL_DbcException (derived from sql::DbcException)
		- sql::DbcMethodNotImplemented (derived from sql::DbcException)
		- sql::DbcInvalidArgument (derived from sql::DbcException)
		- sql::DbcException (derived from std::runtime_error)

		All MySQL Server related errors will be reported by throwing a MySQL_DbcException.
		MySQL_DbcException is the only of the four above mentioned which
		can return a MySQL Server error code through the method int getMySQLErrno().
		*/

		cout << endl;
		cout << "ERR: MySQL_DbcException in " << __FILE__;
		cout << "(" << __FUNCTION__ << ") on line " << __LINE__ << endl;

		// Use what() and getMySQLErrno()
		cout << "ERR: " << e->what();
		cout << " (MySQL error code: " << e->getMySQLErrno() << " )" << endl;

		delete e;
		return EXIT_FAILURE;

	} catch (sql::DbcException *e) {
		/* Exception is not caused by the MySQL Server */

		cout << endl;
		cout << "ERR: DbcException in " << __FILE__;
		cout << "(" << __FUNCTION__ << ") on line " << __LINE__ << endl;
		// Use what() (derived from std::runtime_error)
		cout << "ERR: " << e->what();

		delete e;
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}

