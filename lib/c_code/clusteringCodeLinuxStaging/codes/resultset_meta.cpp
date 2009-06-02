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
* Example of sql::ResultSetMetaData - meta data of a result set
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

static void printResultSetMetaData(sql::ResultSet *res);

using namespace std;

/**
* Meta data of a (simple) statements result set - not prepared statements
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
	stringstream sql;
int i;

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
		stmt->execute("DROP TABLE IF EXISTS test");
		stmt->execute("CREATE TABLE test(id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, label CHAR(1))");
		cout << "\tTest table created" << endl;

		// Populate the test table with data
		for (i = 0; i < EXAMPLE_NUM_TEST_ROWS; i++) {
			// KLUDGE: You should take measures against SQL injections!
			// example.h contains the test data
			sql.str("");
			sql << "INSERT INTO test(id, label) VALUES (";
			sql << test_data[i].id << ", '" << test_data[i].label << "')";
			stmt->execute(sql.str());
		}
		cout << "\tTest table populated" << endl << endl;

		res = stmt->executeQuery("SELECT id AS column_alias, label FROM test AS table_alias LIMIT 1");
		cout << "\tSELECT id AS column_alias, label FROM test AS table_alias LIMIT 1" << endl;
		printResultSetMetaData(res);
		delete res;

		res = stmt->executeQuery("SELECT 1.01, 'Hello world!'");
		cout << "\tSELECT 1.01, 'Hello world!'" << endl;
		printResultSetMetaData(res);
		delete res;

		res = stmt->executeQuery("DESCRIBE test");
		cout << "\tDESCRIBE test" << endl;
		printResultSetMetaData(res);
		delete res;

		// Clean up
		stmt->execute("DROP TABLE IF EXISTS test");
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

/**
* Prints all meta data associated with an result set
*
*/
static void printResultSetMetaData(sql::ResultSet *res)
{
	// ResultSetMetaData object
	sql::ResultSetMetaData const *meta;
	int column;

	if (res->rowsCount() == 0) {
		cout << "FAILURE - no rows" << endl;
		return;
	}

	// Get the meta data - we leave all the exception handling to the caller...
	meta = res->getMetaData();

	cout << endl;
	cout << "\tPrinting result set meta data" << endl;
	cout << "\tres->rowsCount() = " << res->rowsCount() << endl;
	cout << "\tmeta->getColumnCount() = " << meta->getColumnCount() << endl;

	// Dump information for every column
	// NOTE: column indexing is 1-based not zero-based!
	for (column = 1; column <= meta->getColumnCount(); column++) {
		cout << "\t\tColumn " << column << "\t\t\t= " << meta->getColumnName(column)<< endl;
		cout << "\t\tmeta->getCatalogName()\t\t= " << meta->getCatalogName(column) << endl;
		// Not implemented
		// cout << "\t\tmeta->getColumnDisplaySize() = " << meta->getColumnDisplaySize(column) << endl;
		cout << "\t\tmeta->getColumnLabel()\t\t= " << meta->getColumnLabel(column) << endl;
		cout << "\t\tmeta->getColumnName()\t\t= " << meta->getColumnName(column) << endl;
		cout << "\t\tmeta->getColumnType()\t\t= " << meta->getColumnType(column) << endl;
		cout << "\t\tmeta->getColumnTypeName()\t= " << meta->getColumnTypeName(column) << endl;
		// Not implemented
		// cout << "\t\tmeta->getPrecision()\t\t= " << meta->getPrecision(column) << endl;
		// cout << "\t\tmeta->getScale()\t\t= " << meta->getScale(column) << endl;
		cout << "\t\tmeta->getSchemaName()\t\t= " << meta->getSchemaName(column) << endl;
		cout << "\t\tmeta->getTableName()\t\t= " << meta->getTableName(column) << endl;
		cout << "\t\tmeta->isAutoIncrement()\t\t= " << meta->isAutoIncrement(column) << endl;
		cout << "\t\tmeta->isCaseSensitive()\t\t= " << meta->isCaseSensitive(column) << endl;
		cout << "\t\tmeta->isCurrency()\t\t= " << meta->isCurrency(column) << endl;
		cout << "\t\tmeta->isDefinitelyWritable()\t= " << meta->isDefinitelyWritable(column) << endl;
		cout << "\t\tmeta->isNullable()\t\t= " << meta->isNullable(column) << endl;
		cout << "\t\tmeta->isReadOnly()\t\t= " << meta->isReadOnly(column) << endl;
		cout << "\t\tmeta->isSearchable()\t\t= " << meta->isSearchable(column) << endl;
		cout << "\t\tmeta->isSigned()\t\t= " << meta->isSigned(column) << endl;
		cout << "\t\tmeta->isWritable()\t\t= " << meta->isWritable(column) << endl;
		cout << endl;
	}
}

