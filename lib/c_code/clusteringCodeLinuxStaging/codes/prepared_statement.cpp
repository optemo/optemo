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
* Example of sql::PreparedStatement
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

bool prepare_execute(sql::Connection *con, const char *sql);
sql::Statement* emulate_prepare_execute(sql::Connection *con, const char *sql);

using namespace std;

/**
* Example of statements - not to be confused with prepared statements
*
* NOTE: The MySQL Server does not support each and every SQL statement
* to be prepared. The list of statements which can be prepared is available
* in the MySQL Server documentation and the C API documentation:
* http://dev.mysql.com/doc/refman/5.1/en/c-api-prepared-statements.html
* (Link to the MySQL Server 5.1 documentation!)
*
* Connector/C++ is based on the C API and C library "libmysql". Therefore
* it inherits all limitations from the MySQL Server and the MySQL C API.
*
* MySQL 5.1.12 can prepare the following statements:
*
* - CREATE TABLE, DELETE, DO, INSERT, REPLACE, SELECT, SET, UPDATE
* - most SHOW commands
* - ANALYZE TABLE, OPTIMIZE TABLE, REPAIR TABLE
* - CACHE INDEX, CHANGE MASTER, CHECKSUM {TABLE | TABLES},
* - {CREATE | RENAME | DROP} DATABASE, {CREATE | RENAME | DROP} USER
* - FLUSH {TABLE | TABLES | TABLES WITH READ LOCK | HOSTS | PRIVILEGES | LOGS | STATUS | MASTER | SLAVE | DES_KEY_FILE | USER_RESOURCES}
* - GRANT, REVOKE, KILL, LOAD INDEX INTO CACHE, RESET {MASTER | SLAVE | QUERY CACHE}
* - SHOW BINLOG EVENTS, SHOW CREATE {PROCEDURE | FUNCTION | EVENT | TABLE | VIEW}
* - SHOW {AUTHORS | CONTRIBUTORS | WARNINGS | ERRORS}
* - SHOW {MASTER | BINARY} LOGS, SHOW {MASTER | SLAVE} STATUS
* - SLAVE {START | STOP}, INSTALL PLUGIN, UNINSTALL PLUGIN
*
*  ... that's pretty much every *core* SQL statement - but not USE as you'll see below.
*
* Connector/C++ does not include a prepared statement emulation
*
* @link http://dev.mysql.com/doc/refman/5.1/en/c-api-prepared-statements.html
*/
int main()
{
	// Driver Manager
	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection				*con;
	sql::Statement				*stmt;
	sql::PreparedStatement	*prep_stmt, *prep_select;
	sql::ResultSet				*res;

	/* sql::ResultSet.rowsCount() returns size_t */
	size_t row;
	stringstream sql;
	int i, num_rows;

	cout << boolalpha;
	cout << "Connector/C++ prepared statement example.." << endl << endl;

	try {
		// Using the Driver to create a connection
		driver = sql::mysql::get_mysql_driver_instance();
		con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);

		// See above - USE is not supported through the prepared statement protocol
		stmt = con->createStatement();
		stmt->execute("USE " EXAMPLE_DB);
		delete stmt;

		/*
		Prepared statement are unhandy for queries which you execute only once!

		prepare() will send your SQL statement to the server. The server
		will do a SQL syntax check, perform some static rewriting like eliminating
		dead expressions such as "WHERE 1=1" and simplify expressions
		like "WHERE a > 1 AND a > 2" to "WHERE a > 2". Then control gets back
		to the client and the server waits for execute() (or close()).

		On execute() another round trip to the server is done.

		In case you execute your prepared statement only once - like shown below -
		you get two round trips. But using "simple" statements - like above - means
		only one round trip.

		Therefore, the below is *bad* style. WARNING: Although its *bad* style,
		the example program will continue to do it to demonstrate the (ab)use of
		prepared statements (and to prove that you really can do more than SELECT with PS).
		*/
		prep_stmt = con->prepareStatement("DROP TABLE IF EXISTS test");
		prep_stmt->execute();
		delete prep_stmt;

		// Yet another example of *bad* and *slow* code
		prepare_execute(con, "CREATE TABLE test(id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, label CHAR(1))");
		cout << "\tTest table created" << endl;

		/*
		The first useful example - prepare() once, execute() n + 1 times
		NOTE: The MySQL Server does not support named parameters. You have to use
		the placeholder syntax shown below. There is no emulation which would you
		allow to use named parameter like ':param1'. Use '?'. Parameters are 1-based.
		*/
		num_rows = 0;
		prep_stmt = con->prepareStatement("INSERT INTO test(id, label) VALUES (?, ?)");
	/*	for (i = 0; i < EXAMPLE_NUM_TEST_ROWS; i++) {
			// BUG, KNOWN ISSUE: 0-based!
			prep_stmt->setInt(0, test_data[i].id);
			prep_stmt->setString(1, test_data[i].label);
			// executeUpdate() returns the number of affected = inserted rows
			num_rows += prep_stmt->executeUpdate();
		} */
		delete prep_stmt;
		if (EXAMPLE_NUM_TEST_ROWS != num_rows) {
			cout << "\tFAILURE executeUpdate() has returned a wrong number of inserted rows" << endl;
		}

		cout << "\tTest table populated" << endl << endl;

		// We will reuse the SELECT a bit later...
		prep_select = con->prepareStatement("SELECT id, label FROM test ORDER BY id ASC");
		cout << "\tRunning 'SELECT id, label FROM test ORDER BY id ASC'" << endl;
		res = prep_select->executeQuery();
		row = 0;
		while (res->next()) {
			cout << "\t\tRow " << row << " - id = " << res->getInt("id");
			cout << ", label = '" << res->getString("label") << "'" << endl;
			row++;
		}
		delete res;

		cout << endl;
		cout << "\tSimple PS 'emulation' for USE and another SELECT" << endl;
		stmt = emulate_prepare_execute(con, "USE mysql");
		delete stmt;
		stmt = emulate_prepare_execute(con, "USE " EXAMPLE_DB);
		delete stmt;

		stmt = emulate_prepare_execute(con, "SELECT id FROM test ORDER BY id ASC");
		res = stmt->getResultSet();
		if (res != NULL) {
			row = 0;
			while (res->next()) {
				cout << "\t\tRow " << row << " - id = " << res->getInt("id") << endl;
				row++;
			}
			delete res;
		}
		delete stmt;

		// Running the SELECT again but fetching in reverse order
		cout << endl;
		cout << "\tSELECT and fetching in reverse order" << endl;

		res = prep_select->executeQuery();
		row = res->rowsCount();
		cout << "\t\tres->getRowsCount() = " << res->rowsCount() << endl;
		if (row != EXAMPLE_NUM_TEST_ROWS) {
			cout << "\tFAILURE Expecting " << EXAMPLE_NUM_TEST_ROWS;
			cout << " rows; got " << res->rowsCount() << endl;
		}

		// Position the cursor after the last row
		cout << "\t\tPosition the cursor after the last row\n";
		res->afterLast();
		cout << "\t\tres->isafterLast()\t= " << res->isAfterLast() << endl;
		cout << "\t\tres->isLast()\t\t= " << res->isLast() << endl;
		while (res->previous()) {
			cout << "\t\tres->previous()\n";
			cout << "\t\tRow " << row << " - id = " << res->getInt("id");
			cout << ", label = '" << res->getString("label") << "'" << endl;
			row--;
		}
		cout << "\t\tShould be before the first\n";
		cout << "\t\tres->isFirst()\t\t= " << res->isFirst() << endl;
		cout << "\t\tres->isBeforeFirst()\t= " << res->isBeforeFirst() << endl;

		// Now that the cursor is before the first, fetch the first
		cout << "\t\tNow that the cursor is before the first, fetch the first\n";
		cout << "\t\tcalling next() to fetch first row" << endl;
		row++;
		res->next();
		cout << "\t\tres->isFirst()\t\t= " << res->isFirst() << endl;
		cout << "\t\tRow " << row << " - id = " << res->getInt("id");
		cout << ", label = '" << res->getString("label") << "'" << endl;
		row--;

		// For more on curosors see resultset.cpp example
		delete res;

		delete prep_select;

		// Clean up
		stmt = con->createStatement();
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


bool prepare_execute(sql::Connection *con, const char *sql)
{
	sql::PreparedStatement *prep_stmt;

	prep_stmt = con->prepareStatement(sql);
	prep_stmt->execute();
	delete prep_stmt;

	return true;
}


sql::Statement* emulate_prepare_execute(sql::Connection *con, const char *sql)
{
	sql::PreparedStatement *prep_stmt;
	sql::Statement *stmt = NULL;

	cout << "\t\t'emulation': " << sql << endl;

	try {

		prep_stmt = con->prepareStatement(sql);
		prep_stmt->execute();
		cout << "\t\t'emulation': use of sql::PreparedStatement possible" << endl;
		// safe upcast - PreparedStatement is derived from Statement
		stmt = prep_stmt;

	} catch (sql::mysql::MySQL_DbcException *e) {
		/*
		Maybe the command is not supported by the MySQL Server?

		http://dev.mysql.com/doc/refman/5.1/en/error-messages-server.html
		Error: 1295 SQLSTATE: HY000 (ER_UNSUPPORTED_PS)

		Message: This command is not supported in the prepared statement protocol yet
		*/

		if (e->getMySQLErrno() != 1295) {
			// The MySQL Server should be able to prepare the statement
			// but something went wrong. Let the caller handle the error.
			throw ;
		}
		cout << "\t\t'emulation': ER_UNSUPPORTED_PS and fallback to sql::Statement" << endl;
		delete e;

		stmt = con->createStatement();
		stmt->execute(sql);
	}

	return stmt;
}

