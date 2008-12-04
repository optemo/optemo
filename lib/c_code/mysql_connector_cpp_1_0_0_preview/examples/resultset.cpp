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
* Basic example demonstrating scrolling through a result set
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

// static void validateRow(sql::ResultSet *res, struct _test_data *exp);

using namespace std;

/**
* Example how to scroll through a result set
*/
int main()
{
	// Driver Manager
	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection	*con;
	sql::Statement	*stmt;
	sql::ResultSet	*res;

	/* sql::ResultSet.rowsCount() returns size_t */
	size_t row;
	stringstream sql;
	 //int i;
	struct max //_test_data min, max;

	cout << boolalpha;
	cout << "Connector/C++ result set.." << endl << endl;

	try {
		// Using the Driver to create a connection
		driver = sql::mysql::get_mysql_driver_instance();
		con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);

		// Creating a "simple" statement - "simple" = not a prepared statement
		stmt = con->createStatement();

		// Create a test table demonstrating the use of sql::Statement.execute()
		stmt->execute("USE " EXAMPLE_DB);
		stmt->execute("DROP TABLE IF EXISTS test");
		stmt->execute("CREATE TABLE test(id INT, label CHAR(1))");
		cout << "\tTest table created" << endl;

		// Populate the test table with data
		min = max = 0 //test_data[0];
	/*	for (i = 0; i < EXAMPLE_NUM_TEST_ROWS; i++) {
			// Remember the l id value for later testing
			if (test_data[i].id < min.id) {
				min = test_data[i];
			}
			if (test_data[i].id > max.id) {
				max = test_data[i];
			} */

			// KLUDGE: You should take measures against SQL injections!
			// example.h contains the test data
			sql.str("");
			sql << "INSERT INTO test(id, label) VALUES (";
		//	sql << test_data[i].id << ", '" << test_data[i].label << "')";
			stmt->execute(sql.str());
		}
		cout << "\tTest table populated" << endl << endl;

		/*
		This is an example how to fetch in reverse order using the ResultSet cursor.
		Every ResultSet object maintains a cursor, which points to its current
		row of data. The cursor is 1-based. The first row has the cursor position 1.

		NOTE: The Connector/C++ preview uses buffered results for this. C/C++ will
		always fetch all data no matter how big the result set is!
		*/
		res = stmt->executeQuery("SELECT id, label FROM test ORDER BY id ASC");
		cout << "\tSelecting in ascending order but fetching in descending (reverse) order" << endl;

		// Move the cursor after the last row - n + 1
		res->afterLast();
		row = res->rowsCount() - 1;
		// Move the cursor backwards to: n, n - 1, ... 1, 0. Return true if rows are available.
		while (res->previous()) {
			cout << "\t\tRow " << row << " id = " << res->getInt("id");
			cout << ", label = '" << res->getString("label") << "'" << endl;
			row--;
		}
		// The last call to res->previous() has moved the cursor before the first row
		// Cursor position is 0, recall: rows are from 1 ... n
		cout << "\t\tisBeforeFirst() = " << res->isBeforeFirst() << endl;
		cout << endl;

		// Move the cursor forward again to position 1 - the first row
		res->next();
		cout << "\tPositioning cursor to 1 using next(), isFirst() = " << res->isFirst() << endl;
		validateRow(res, &min);

		// Move the cursor to position 0 = before the first row
		if (false != res->absolute(0)) {
			cout << "FAILURE Cannot position cursor before first row" << endl;
		}
		cout << "\tPositioning before first row using absolute(0), isFirst() = " << res->isFirst() << endl;
		// Move the cursor forward to position 1 = the first row
		res->next();
		validateRow(res, &min);

		// Move the cursor to position 0 = before the first row
		res->beforeFirst();
		cout << "\tPositioning cursor using beforeFirst(), isFirst() = " << res->isFirst() << endl;
		// Move the cursor forward to position 1 = the first row
		res->next();
		cout << "\t\tMoving cursor forward using next(), isFirst() = " << res->isFirst() << endl;
		validateRow(res, &min);

		cout << endl;
		cout << "\tFinally, reading in descending (reverse) order again" << endl;
		// Move the cursor after the last row - n + 1
		res->afterLast();
		row = res->rowsCount() - 1;
		// Move the cursor backwards to: n, n - 1, ... 1, 0. Return true if rows are available.
		while (res->previous()) {
			cout << "\t\tRow " << row << " id = " << res->getInt("id");
			cout << ", label = '" << res->getString("label") << "'" << endl;
			row--;
		}
		// The last call to res->previous() has moved the cursor before the first row
		// Cursor position is 0, recall: rows are from 1 ... n
		cout << "\t\tisBeforeFirst() = " << res->isBeforeFirst() << endl;
		cout << endl;

		cout << "\tAnd in regular order..." << endl;
		res->beforeFirst();
		row = 0;
		while (res->next()) {
			cout << "\t\tRow " << row << " id = " << res->getInt("id");
			cout << ", label = '" << res->getString("label") << "'" << endl;
			row++;
		}
		cout << "\t\tisAfterLast() = " << res->isAfterLast() << endl;

		// Move to the last entry using a negative offset for absolute()
		cout << endl;
		cout << "\tTrying absolute(-1) to fetch last entry..." << endl;
		if (true != res->absolute(-1)) {
			cout << "FAILURE absolute(-1) should return true" << endl;
		}
		cout << "\t\tisAfterLast() = " << res->isAfterLast() << endl;
		cout << "\t\tisLast() = " << res->isLast() << endl;
	//	validateRow(res, &max);

		delete res;

		// Clean up
		stmt->execute("DROP TABLE IF EXISTS test");
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

/*static void validateRow(sql::ResultSet *res, struct _test_data *exp)
{
	cout << "\t\tFetching the first row, id = " << res->getInt("id");
	cout << "\t\tlabel = '" << res->getString("label") << "'" << endl;

	if ((res->getInt("id") != exp->id) || (res->getString("label") != exp->label)) {
		cout << "\t\tFAILURE Wrong results"	<< "; expected (" << exp->id;
		cout << "," << exp->label << ") got (" << res->getInt("id");
		cout <<", " << res->getString("label") << ")" << endl;
	} 
}*/

