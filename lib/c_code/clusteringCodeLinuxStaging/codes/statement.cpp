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
* Example of sql::Statement - "simple" (not prepared) statements
*
*/

// Standard C++ includes
#include <stdlib.h>
#include <iostream>
#include <sstream>

// Public interface of the MySQL Connector/C++
#include "cppconn/mysql_public_iface.h"
// Connection parameter and sample data
#include "examples.h"

using namespace std;

/**
* Example of statements - not to be confused with prepared statements
*/
int main()
{
	// Driver Manager
	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection		*con;
	sql::Statement		*stmt;
	sql::ResultSet		*res;

	/* sql::ResultSet.rowsCount() returns size_t */
	size_t row;
	stringstream sql;
	int i, ok;

	cout << boolalpha;
	cout << "Connector/C++ (simple) statement example.." << endl << endl;

	try {
		// Using the Driver to create a connection
		driver = sql::mysql::get_mysql_driver_instance();
		con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);

		// Creating a "simple" statement - "simple" = not a prepared statement
		stmt = con->createStatement();

		// Create a test table demonstrating the use of sql::Statement.execute()
		stmt->execute("USE " EXAMPLE_DB);
		stmt->execute("DROP TABLE IF EXISTS "EXAMPLE_DB);
		stmt->execute("CREATE TABLE "EXAMPLE_DB"(id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, label CHAR(1))");
//		cout << "\tTest table created" << endl;

		// Populate the test table with data
//		for (i = 0; i < EXAMPLE_NUM_TEST_ROWS; i++) {
			// KLUDGE: You should take measures against SQL injections!
			// example.h contains the test data
//			sql.str("");
//			sql << "INSERT INTO "EXAMPLE_DB"(id, label) VALUES (";
//			sql << test_data[i].id << ", '" << test_data[i].label << "')";
//			stmt->execute(sql.str());
//		}
//		cout << "\tTest table populated" << endl << endl;

		// NOTE: Use execute() instead of the more convenient executeQuery()
		// See the other example file for executeQuery() and executeUpdate() examples
		// However, if you are executing SQL dynamically, you might have to use execute()
		ok = stmt->execute("SELECT id, label FROM " EXAMPLE_DB" ORDER BY id ASC");
		cout << "\tstmt->execute('SELECT id, label FROM "EXAMPLE_DB" ORDER BY id ASC') = ";
		cout << ok << endl;
		if (ok == true) {
			// The first result is a result set
			cout << "\t\tFetching results" << endl;
			// NOTE: If stmt.getMoreResults() would be implemented already one
			// KLUDGE: would use a do { ... } while (stmt.getMoreResults()) loop
			res = stmt->getResultSet();
			row = 0;
			while (res->next()) {
				cout << "\t\tRow " << row << " - id = " << res->getInt("id");
				cout << ", label = '" << res->getString("label") << "'" << endl;
				row++;
			}
			delete res;

		} else if (ok == false) {
			// The first result is an update count
			cout << "FAILURE Expecting regular result set." << endl;
		}

		// Clean up
//		stmt->execute("DROP TABLE IF EXISTS "EXAMPLE_DB);
		cout << "done!" << endl;
		cout << endl;

		delete stmt;
		delete con;
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
//		cout << "ERR: MySQL_DbcException in " << __FILE__;
//		cout << "(" << __FUNCTION__ << ") on line " << __LINE__ << endl;

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

