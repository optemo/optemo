/* Copyright (C) 2007-2008 Sun Microsystems

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "cppconn/mysql_public_iface.h"

#define ensure(msg, stmt)				do {total_tests++;if(!(stmt)){printf("\nError! line=%d: %s\n",__LINE__,msg);total_errors++;throw new sql::DbcException(CPPCONN_FUNC, __LINE__,"error");}} while (0)
#define ensure_equal(msg, op1, op2)	do {total_tests++;if((op1)!=(op2)){printf("\nError! line=%d: %s\n",__LINE__,msg);total_errors++;throw new sql::DbcException(CPPCONN_FUNC, __LINE__, "error");}}while(0)
#define ensure_equal_int(msg, op1, op2)	do {total_tests++;if((op1)!=(op2)){printf("\nError! line=%d: %s Op1=%d Op2=%d\n",__LINE__,msg,op1,op2);total_errors++;throw new sql::DbcException(CPPCONN_FUNC, __LINE__, "error");}}while(0)

static int total_errors = 0;
static int total_tests = 0;
static int silent = 1;

#define USED_DATABASE "test"
#define DATABASE_TO_USE "USE test"

#define ENTER_FUNCTION()		if (!silent) printf(">>>>   %s\n", CPPCONN_FUNC); else printf(".");
#define LEAVE_FUNCTION()		if (!silent) printf("<<<<   %s\n", CPPCONN_FUNC); else printf(".");

#if defined(_WIN32) || defined(_WIN64)
#pragma warning(disable:4251)
#pragma warning(disable:4800)
#endif

#ifdef __GNUC__
#if __GNUC__ >= 2
#define CPPCONN_FUNC __FUNCTION__
#endif
#else
#define CPPCONN_FUNC "<unknown>"
#endif

/* {{{	*/
sql::Connection *
get_connection(const std::string& host, const std::string& port,
			const std::string& user, const std::string& pass)
{
	return new sql::mysql::MySQL_Connection(host, port, user, pass);
}
/* }}} */


/* {{{	*/
static bool populate_insert_data(sql::Statement * stmt)
{
	return stmt->execute("INSERT INTO test_function (a,b,c,d,e) VALUES(1, 111, NULL, \"222\", \"xyz\")");
}
/* }}} */


/* {{{	*/
static bool populate_test_table(sql::Connection * conn)
{
	std::auto_ptr<sql::Statement> stmt(conn->createStatement());
	ensure("stmt is NULL", stmt.get() != NULL);

	stmt->execute(DATABASE_TO_USE);
	stmt->execute("DROP TABLE IF EXISTS test_function");
	if (true == stmt->execute("CREATE TABLE test_function (a integer unsigned not null, b integer, c integer default null, d char(10), e varchar(10) character set utf8 collate utf8_bin)")) {
		return false;
	}

	if (true == populate_insert_data(stmt.get())) {
		stmt->execute("DROP TABLE test_function");
		return false;
	}
	return true;
}
/* }}} */


/* {{{	*/
static bool populate_TX_insert_data(sql::Statement * stmt)
{
	return stmt->execute("INSERT INTO test_function_tx (a,b,c,d,e) VALUES(1, 111, NULL,  \"222\", \"xyz\")");
}
/* }}} */


/* {{{	*/
static bool populate_TX_test_table(sql::Connection * conn)
{
	std::auto_ptr<sql::Statement> stmt(conn->createStatement());
	ensure("stmt is NULL", stmt.get() != NULL);

	stmt->execute(DATABASE_TO_USE);
	stmt->execute("DROP TABLE IF EXISTS test_function_tx");
	if (true == stmt->execute("CREATE TABLE test_function_tx(a integer unsigned not null, b integer, c integer default null, d char(10), e varchar(10) character set utf8 collate utf8_bin) engine = innodb")) {
		return false;
	}

	if (true == populate_TX_insert_data(stmt.get())) {
		stmt->execute("DROP TABLE test_function_tx");
		return false;
	}
	stmt->getConnection()->commit();
	return true;
}
/* }}} */


/* {{{	*/
static bool populate_test_table_PS(sql::Connection * conn)
{
	std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
	ensure("stmt1 is NULL", stmt1.get() != NULL);
	stmt1->execute(DATABASE_TO_USE);

	std::auto_ptr<sql::PreparedStatement> stmt2(conn->prepareStatement("DROP TABLE IF EXISTS test_function"));
	ensure("stmt2 is NULL", stmt2.get() != NULL);
	stmt2->executeUpdate();

	std::auto_ptr<sql::PreparedStatement> stmt3(conn->prepareStatement("CREATE TABLE test_function(a integer unsigned not null, b integer, c integer default null, d char(10), e varchar(10) character set utf8 collate utf8_bin)"));
	ensure("stmt3 is NULL", stmt3.get() != NULL);
	stmt3->executeUpdate();

	std::auto_ptr<sql::PreparedStatement> stmt4(conn->prepareStatement("INSERT INTO test_function (a,b,c,d,e) VALUES(1, 111, NULL, \"222\", \"xyz\")"));
	ensure("stmt4 is NULL", stmt4.get() != NULL);
	stmt4->executeUpdate();

	return true;
}
/* }}} */


/* {{{	*/
static bool populate_TX_test_table_PS(sql::Connection * conn)
{
	std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
	ensure("stmt is NULL", stmt1.get() != NULL);
	stmt1->execute(DATABASE_TO_USE);

	std::auto_ptr<sql::PreparedStatement> stmt2(conn->prepareStatement("DROP TABLE IF EXISTS test_function_tx"));
	ensure("stmt2 is NULL", stmt2.get() != NULL);
	stmt2->executeUpdate();

	std::auto_ptr<sql::PreparedStatement> stmt3(conn->prepareStatement("CREATE TABLE test_function_tx(a integer unsigned not null, b integer, c integer default null, d char(10), e varchar(10) character set utf8 collate utf8_bin) engine = innodb"));
	ensure("stmt3 is NULL", stmt3.get() != NULL);
	stmt3->executeUpdate();

	std::auto_ptr<sql::PreparedStatement> stmt4(conn->prepareStatement("INSERT INTO test_function_tx (a,b,c,d,e) VALUES(1, 111, NULL, \"222\", \"xyz\")"));
	ensure("stmt4 is NULL", stmt4.get() != NULL);
	stmt4->executeUpdate();

	return true;
}
/* }}} */


/* {{{	*/
static void test_autocommit(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		conn->setAutoCommit(1);
		ensure("AutoCommit", conn->getAutoCommit() == true);

		conn->setAutoCommit(0);
		ensure("AutoCommit", conn->getAutoCommit() == false);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_connection_0(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		char buff[64];

		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);
		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT CONNECTION_ID()"));
		ensure("res1 is NULL", rset1.get() != NULL);

		ensure("res1 is empty", rset1->next() != false);

		ensure("connection is closed", !conn->isClosed());

		sprintf(buff, "KILL %d", rset1->getInt(1));

		try {
			stmt1->execute(buff);
		} catch (sql::DbcException *e) {
			/*
			  If this is mac, we will get an error.
			  MySQL on Mac closes the connection without sending response
			*/
			delete e;
		}
		try {
			std::auto_ptr<sql::ResultSet> rset2(stmt1->executeQuery("SELECT CONNECTION_ID()"));
			ensure("no exception", false);
		} catch (sql::DbcException *e) {
			ensure("Exception correctly thrown", true);
			delete e;
		}
		ensure("connection is open", conn->isClosed() == false);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_connection_1(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);
		ensure("connection is closed", !conn->isClosed());
		conn->setAutoCommit(false);

		ensure("Data not populated", true == populate_TX_test_table(conn));

		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res1 is NULL", rset1.get() != NULL);
		ensure("res1 is empty", rset1->next() != false);
		int count_full_before = rset1->getInt(1);
		ensure_equal_int("res1 has more rows ", rset1->next(), false);

		std::string savepointName("firstSavePoint");
		std::auto_ptr<sql::Savepoint> savepoint(conn->setSavepoint(savepointName));

		populate_TX_insert_data(stmt1.get());
		std::auto_ptr<sql::ResultSet> rset2(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res2 is NULL", rset2.get() != NULL);
		ensure_equal_int("res2 is empty", rset2->next(), true);
		int count_full_after = rset2->getInt(1);
		ensure_equal_int("res2 has more rows ", rset2->next(), false);
		ensure_equal_int("wrong number of rows", count_full_after, (count_full_before * 2));

		conn->rollback(savepoint.get());
		std::auto_ptr<sql::ResultSet> rset3(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res3 is NULL", rset3.get() != NULL);
		ensure_equal_int("res3 is empty", rset3->next(), true);
		int count_full_after_rollback = rset3->getInt(1);
		ensure_equal_int("res3 has more rows ", rset3->next(), false);
		ensure_equal_int("wrong number of rows", count_full_after_rollback, count_full_before);

		conn->releaseSavepoint(savepoint.get());
		try {
			/* The second call should throw an exception */
			conn->releaseSavepoint(savepoint.get());
			total_errors++;
		} catch (sql::DbcException *e) {
			delete e;
		}

		/* Clean */
		stmt1->execute(DATABASE_TO_USE);
		stmt1->execute("DROP TABLE test_function_tx");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_connection_2(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt1 is NULL", stmt.get() != NULL);

		ensure("Wrong catalog", conn->getCatalog() == NULL);
		stmt->execute(DATABASE_TO_USE);
		std::auto_ptr<std::string> newCatalog(conn->getCatalog());
		ensure("Wrong catalog", *(newCatalog.get()) == std::string(USED_DATABASE));

		try {
			conn->setCatalog(std::string("doesnt_actually_exist"));
			total_errors++;
		} catch (sql::DbcException *e) {
			delete e;
		}
		conn->setCatalog(std::string("information_schema"));
		std::auto_ptr<std::string> newCatalog2(conn->getCatalog());
		ensure("Wrong catalog", *(newCatalog2.get()) == std::string("information_schema"));
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_connection_3(sql::Connection * conn, std::string user)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::DatabaseMetaData> meta(conn->getMetaData());
		ensure("getUserName() failed", user == meta->getUserName().substr(0, user.length()));
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_statement_0(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("AutoCommit", conn == stmt->getConnection());
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test simple update statement against statement object */
static void test_statement_1(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));
		if (false == stmt->execute("SELECT * FROM test_function"))
			ensure("False returned for SELECT", false);

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test simple query against statement object */
static void test_statement_2(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));
		if (false == stmt->execute("SELECT * FROM test_function"))
			ensure("False returned for SELECT", false);

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test executeQuery() - returning a result set*/
static void test_statement_3(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));
		/* Get a result set */
		try {
			std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery("SELECT * FROM test_function"));
			ensure("NULL returned for result set", rset.get() != NULL);
		} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test executeQuery() - returning empty result set */
static void test_statement_4(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));
		/* Get a result set */
		try {
			std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery("SELECT * FROM test_function WHERE 1=2"));
			ensure("NULL returned for result set", rset.get() != NULL);
			ensure_equal_int("Non-empty result set", false, rset->next());

		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test executeQuery() - use it for inserting, should generate an exception */
static void test_statement_5(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));
		/* Get a result set */
		try {
			std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery("INSERT INTO test_function VALUES(2,200)"));
			ensure("NULL returned for result set", rset.get() == NULL);
			ensure_equal_int("Non-empty result set", false, rset->next());
		} catch (sql::DbcException *e) {
			delete e;
		} catch (...) {
			printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
			total_errors++;
		}
		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test executeUpdate() - check the returned value */
static void test_statement_6(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));
		/* Get a result set */
		try {
			ensure("Number of updated rows", stmt->executeUpdate("UPDATE test_function SET a = 123") == 1);
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test executeUpdate() - execute a SELECT, should get an exception */
static void test_statement_7(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));
		/* Get a result set */
		try {
			stmt->executeUpdate("SELECT * FROM test_function");
			ensure("No exception thrown", false);
		} catch (sql::DbcException *e) {
			delete e;
		} catch (...) {
			printf("ERR: Incorrectly sql::DbcException ist not thrown\n");
			total_errors++;
		}

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


#if 0
/* {{{ Test getFetchSize() - should return int value */
/* XXX: Test fails because getFetchSize() is not implemented*/
static void test_statement_xx(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("fetchSize is negative", stmt->getFetchSize() > 0);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */

/* {{{ Test setFetchSize() - set and get the value */
/* XXX: Doesn't pass because setFetchSize() is unimplemented */
static void test_statement_xx(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		int setFetchSize = 50;

		stmt->setFetchSize(setFetchSize);

		ensure_equal("Non-equal", setFetchSize, stmt->getFetchSize());
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
}
/* }}} */


/* {{{ Test setFetchSize() - set negative value and expect an exception */
/* XXX: Doesn't pass because setFetchSize() is unimplemented */
static void test_statement_xx(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		try {
			stmt->setFetchSize(-1);
			ensure("No exception", false);
		} catch (sql::DbcInvalidArgument) {
			printf("INFO: Caught sql::DbcInvalidArgument\n");
		}
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test setQueryTimeout() - set negative value and expect an exception */
/* XXX: Doesn't pass because setQueryTimeout() is unimplemented */
static void test_statement_xx(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		try {
			stmt->setQueryTimeout(-1);
			printf("ERR: No exception\n");
		} catch (sql::DbcInvalidArgument *e) {
			delete e;
		}
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */
#endif


/* {{{ Test getResultSet() - execute() a query and get the result set */
static void test_statement_8(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));

		ensure("sql::Statement::execute returned false", true == stmt->execute("SELECT * FROM test_function"));

		std::auto_ptr<sql::ResultSet> rset(stmt->getResultSet());
		ensure("rset is NULL", rset.get() != NULL);

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
}
/* }}} */


/* {{{ Test getResultSet() - execute() an update query and get the result set - should be empty */
static void test_statement_9(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("stmt is NULL", stmt.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));

		ensure("sql::Statement::execute returned true", false == stmt->execute("UPDATE test_function SET a = 222"));

		std::auto_ptr<sql::ResultSet> rset(stmt->getResultSet());
		ensure("rset is not NULL", rset.get() == NULL);

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);
		stmt2->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_result_set_0(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());
		ensure("AutoCommit", conn == stmt->getConnection());

		std::auto_ptr<sql::ResultSet> result(stmt->executeQuery("SELECT 1, 2, 3"));

		ensure_equal_int("isFirst", result->isFirst(), false);

		ensure_equal_int("isLast", result->isLast(), false);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_result_set_1(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);

		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT 1"));
		ensure("res1 is NULL", rset1.get() != NULL);

		std::auto_ptr<sql::ResultSet> rset2(stmt1->executeQuery("SELECT 1"));
		ensure("res2 is NULL", rset2.get() != NULL);

		ensure("res1 is empty", rset1->next() != false);
		ensure("res2 is empty", rset2->next() != false);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_result_set_2(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));

		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT 1"));
		ensure("res1 is NULL", rset1.get() != NULL);
		ensure_equal_int("res1 is empty", rset1->next(), true);
		ensure_equal_int("res1 is empty", rset1->next(), false);

		ensure("No rows updated", stmt1->executeUpdate("UPDATE test_function SET a = 2") > 0);

		stmt1->execute("DROP TABLE test_function");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
static void test_result_set_3(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);

		ensure_equal("sql::Connection differs", conn, stmt1->getConnection());
		int old_commit_mode = conn->getAutoCommit();
		conn->setAutoCommit(0);

		ensure("Data not populated", true == populate_TX_test_table(conn));

		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res1 is NULL", rset1.get() != NULL);
		ensure("res1 is empty", rset1->next() != false);
		int count_full_before = rset1->getInt(1);
		ensure("res1 has more rows ", rset1->next() == false);

		/* Let's delete and then rollback */
		ensure_equal("Deleted less rows",
									stmt1->executeUpdate("DELETE FROM test_function_tx WHERE 1"),
									count_full_before);

		std::auto_ptr<sql::ResultSet> rset2(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res2 is NULL", rset2.get() != NULL);
		ensure("res2 is empty", rset2->next() != false);
		ensure("Table not empty after delete", rset2->getInt(1) == 0);
		ensure("res2 has more rows ", rset2->next() == false);

		stmt1->getConnection()->rollback();

		std::auto_ptr<sql::ResultSet> rset3(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res3 is NULL", rset3.get() != NULL);
		ensure("res3 is empty", rset3->next() != false);
		int count_full_after = rset3->getInt(1);
		ensure("res3 has more rows ", rset3->next() == false);

		ensure("Rollback didn't work", count_full_before == count_full_after);

		/* Now let's delete and then commit */
		ensure_equal("Deleted less rows",
									stmt1->executeUpdate("DELETE FROM test_function_tx WHERE 1"),
									count_full_before);
		stmt1->getConnection()->commit();

		std::auto_ptr<sql::ResultSet> rset4(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res4 is NULL", rset4.get() != NULL);
		ensure("res4 is empty", rset4->next() != false);
		ensure("Table not empty after delete", rset4->getInt(1) == 0);
		ensure("res4 has more rows ", rset4->next() == false);

		stmt1->execute("DROP TABLE test_function_tx");

		conn->setAutoCommit(old_commit_mode);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test commit and rollback (autocommit on) */
static void test_result_set_4(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);

		ensure_equal("sql::Connection differs", conn, stmt1->getConnection());

		int old_commit_mode = conn->getAutoCommit();
		conn->setAutoCommit(true);
		ensure_equal_int("Data not populated", true, populate_TX_test_table(conn));


		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res1 is NULL", rset1.get() != NULL);
		ensure_equal_int("res1 is empty", rset1->next(), true);
		int count_full_before = rset1->getInt(1);
		ensure_equal_int("res1 has more rows ", rset1->next(), false);

		/* Let's delete and then rollback */
		ensure_equal_int("Deleted less rows",
									stmt1->executeUpdate("DELETE FROM test_function_tx WHERE 1"),
									count_full_before);

		std::auto_ptr<sql::ResultSet> rset2(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res2 is NULL", rset2.get() != NULL);
		ensure_equal_int("res2 is empty", rset2->next(), true);
		ensure_equal_int("Table not empty after delete", rset2->getInt(1), 0);
		ensure_equal_int("res2 has more rows ", rset2->next(), false);

		/* In autocommit on, this is a no-op */
		stmt1->getConnection()->rollback();

		std::auto_ptr<sql::ResultSet> rset3(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res3 is NULL", rset3.get() != NULL);
		ensure_equal_int("res3 is empty", rset3->next(), true);
		ensure_equal_int("Rollback didn't work", rset3->getInt(1), 0);
		ensure_equal_int("res3 has more rows ", rset3->next(), false);

		ensure("Data not populated", true == populate_TX_test_table(conn));

		/* Now let's delete and then commit */
		ensure_equal("Deleted less rows",
									stmt1->executeUpdate("DELETE FROM test_function_tx WHERE 1"),
									count_full_before);
		/* In autocommit on, this is a no-op */
		stmt1->getConnection()->commit();

		std::auto_ptr<sql::ResultSet> rset4(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res4 is NULL", rset4.get() != NULL);
		ensure_equal_int("res4 is empty", rset4->next(), true);
		ensure_equal_int("Table not empty after delete", rset4->getInt(1), 0);
		ensure_equal_int("res4 has more rows ", rset4->next(), false);

		conn->setAutoCommit(false);
		ensure("Data not populated", true == populate_TX_test_table(conn));
		ensure_equal("Deleted less rows",
									stmt1->executeUpdate("DELETE FROM test_function_tx WHERE 1"),
									count_full_before);
		/* In autocommit iff, this is an op */
		stmt1->getConnection()->rollback();
		std::auto_ptr<sql::ResultSet> rset5(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx"));
		ensure("res5 is NULL", rset5.get() != NULL);
		ensure_equal_int("res5 is empty", rset5->next(), true);
		ensure_equal_int("Table empty after delete", rset5->getInt(1), count_full_before);
		ensure_equal_int("res5 has more rows ", rset5->next(), false);

		stmt1->execute("DROP TABLE test_function_tx");

		conn->setAutoCommit(old_commit_mode);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test multistatement off - send two queries in one call */
static void test_result_set_5(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);

		try {
			std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT COUNT(*) FROM test_function_tx; DELETE FROM test_function_tx"));
			ensure("ERR: Exception not thrown", false);
		} catch (sql::DbcException *e) {
			delete e;
		}
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


static void test_result_set_check_out_of_bound(sql::ResultSet *rset1)
{
	ensure("res1 is empty", rset1->next() != false);
	try {
		rset1->getInt(-123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getInt(123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getInt("no_such_column");
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getString(-123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getString(123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getString("no_such_column");
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getDouble(-123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getDouble(123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getDouble("no_such_column");
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->getInt(rset1->getInt(1) + 1000);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->isNull(-123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->isNull(123);
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {
		rset1->isNull("no_such_column");
		ensure("ERR: No sql::DbcInvalidArgument thrown", false);
	} catch (sql::DbcInvalidArgument *e) {
		delete e;
	}
	try {

		ensure_equal_int("res1 has more rows ", rset1->getInt(1), 1);
		ensure_equal_int("res1 has more rows ", rset1->getInt("count of rows"), 1);

//		ensure("res1 has more rows ", rset1->getDouble(1) - 1 < 0.1);
//		ensure("res1 has more rows ", rset1->getDouble("count of rows") - 1 < 0.1);
//		with libmysq we don't support these conversions,  on the fly :(
//		ensure("res1 has more rows ", rset1->getString(1).compare("1"));
//		ensure("res1 has more rows ", rset1->getString("count of rows").compare("1"));

		ensure_equal_int("c is not null", rset1->isNull(1), false);

		ensure_equal_int("res1 has more rows ", rset1->next(), false);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
}


/* {{{ Test out of bound extraction of data */
static void test_result_set_6(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);

		ensure_equal("sql::Connection differs", conn, stmt1->getConnection());

		ensure("Data not populated", true == populate_TX_test_table(conn));

		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT COUNT(*) AS 'count of rows' FROM test_function_tx"));
		ensure("res1 is NULL", rset1.get() != NULL);

		test_result_set_check_out_of_bound(rset1.get());

		stmt1->execute("DROP TABLE test_function_tx");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test out of bound extraction of data - PS version */
static void test_result_set_7(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		ensure("Data not populated", true == populate_TX_test_table(conn));

		std::auto_ptr<sql::PreparedStatement> stmt1(conn->prepareStatement("SELECT COUNT(*) AS 'count of rows' FROM test_function_tx"));
		ensure("stmt1 is NULL", stmt1.get() != NULL);
		ensure_equal("sql::Connection differs", conn, stmt1->getConnection());

		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery());
		ensure("res1 is NULL", rset1.get() != NULL);

		test_result_set_check_out_of_bound(rset1.get());

		std::auto_ptr<sql::PreparedStatement> stmt2(conn->prepareStatement("DROP TABLE test_function_tx"));
		stmt2->execute();
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test commit and rollback (autocommit on) - PS version */
static void test_result_set_8(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		int count_full_before;
		std::auto_ptr<sql::PreparedStatement> stmt0(conn->prepareStatement("SELECT 1"));
		ensure("stmt0 is NULL", stmt0.get() != NULL);

		ensure_equal("sql::Connection differs", conn, stmt0->getConnection());

		int old_commit_mode = conn->getAutoCommit();
		conn->setAutoCommit(true);
		ensure("Data not populated", true == populate_TX_test_table_PS(conn));

		std::auto_ptr<sql::PreparedStatement> stmt1(conn->prepareStatement("SELECT COUNT(*) FROM test_function_tx"));
		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery());
		ensure("res1 is NULL", rset1.get() != NULL);
		ensure_equal_int("res1 is empty", rset1->next(), true);
		count_full_before = rset1->getInt(1);
		ensure_equal_int("res1 has more rows ", rset1->next(), false);

		std::auto_ptr<sql::PreparedStatement> stmt2(conn->prepareStatement("DELETE FROM test_function_tx WHERE 1"));
		/* Let's delete and then rollback */
		ensure_equal_int("Deleted less rows", stmt2->executeUpdate(), count_full_before);

		std::auto_ptr<sql::PreparedStatement> stmt3(conn->prepareStatement("SELECT COUNT(*) FROM test_function_tx"));
		std::auto_ptr<sql::ResultSet> rset2(stmt3->executeQuery());
		ensure("res2 is NULL", rset2.get() != NULL);
		ensure_equal_int("res2 is empty", rset2->next(), true);
		ensure_equal_int("Table not empty after delete", rset2->getInt(1), 0);
		ensure_equal_int("res2 has more rows ", rset2->next(), false);

		/* In autocommit on, this is a no-op */
		stmt1->getConnection()->rollback();

		std::auto_ptr<sql::PreparedStatement> stmt4(conn->prepareStatement("SELECT COUNT(*) FROM test_function_tx"));
		std::auto_ptr<sql::ResultSet> rset3(stmt4->executeQuery());
		ensure("res3 is NULL", rset3.get() != NULL);
		ensure_equal_int("res3 is empty", rset3->next(), true);
		ensure_equal_int("Rollback didn't work", rset3->getInt(1), 0);
		ensure_equal_int("res3 has more rows ", rset3->next(), false);

		ensure("Data not populated", true == populate_TX_test_table_PS(conn));

		std::auto_ptr<sql::PreparedStatement> stmt5(conn->prepareStatement("DELETE FROM test_function_tx WHERE 1"));
		/* Let's delete and then rollback */
		ensure_equal_int("Deleted less rows", stmt5->executeUpdate(), count_full_before);

		/* In autocommit on, this is a no-op */
		stmt1->getConnection()->commit();

		std::auto_ptr<sql::PreparedStatement> stmt6(conn->prepareStatement("SELECT COUNT(*) FROM test_function_tx"));
		std::auto_ptr<sql::ResultSet> rset4(stmt6->executeQuery());
		ensure("res4 is NULL", rset4.get() != NULL);
		ensure_equal_int("res4 is empty", rset4->next(), true);
		ensure_equal_int("Rollback didn't work", rset4->getInt(1), 0);
		ensure_equal_int("res4 has more rows ", rset4->next(), false);

		conn->setAutoCommit(false);
		ensure("Data not populated", true == populate_TX_test_table_PS(conn));
		std::auto_ptr<sql::PreparedStatement> stmt7(conn->prepareStatement("DELETE FROM test_function_tx WHERE 1"));
		/* Let's delete and then rollback */
		ensure("Deleted less rows", stmt7->executeUpdate() == count_full_before);
		/* In autocommit iff, this is an op */
		stmt1->getConnection()->rollback();

		std::auto_ptr<sql::PreparedStatement> stmt8(conn->prepareStatement("SELECT COUNT(*) FROM test_function_tx"));
		std::auto_ptr<sql::ResultSet> rset5(stmt8->executeQuery());
		ensure("res5 is NULL", rset5.get() != NULL);
		ensure_equal_int("res5 is empty", rset5->next(), true);
		ensure_equal_int("Rollback didn't work", rset5->getInt(1), 0);
		ensure_equal_int("res5 has more rows ", rset5->next(), false);

		std::auto_ptr<sql::PreparedStatement> stmt9(conn->prepareStatement("DROP TABLE test_function_tx"));
		stmt1->execute();

		conn->setAutoCommit(old_commit_mode);
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test multistatement off - send two queries in one call - PS version */
static void test_result_set_9(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {

		try {
			std::auto_ptr<sql::PreparedStatement> stmt1(conn->prepareStatement("SELECT COUNT(*) FROM test_function_tx; DELETE FROM test_function_tx"));
			ensure("ERR: Exception not thrown", false);
		} catch (sql::DbcException *e) {
			delete e;
		}
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test multiresults - SP with normal and prepared statement */
static void test_result_set_10(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt0(conn->createStatement());
		ensure("stmt0 is NULL", stmt0.get() != NULL);
		stmt0->execute(DATABASE_TO_USE);

#if 0
	/* Doesn't work with libmysql - a limitation of the library, might work with mysqlnd if it lies under */
		{
			/* Create procedure is not supported for preparing */
			std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
			stmt1->execute("DROP PROCEDURE IF EXISTS CPP1");
			stmt1->execute("CREATE PROCEDURE CPP1() SELECT 42");

			std::auto_ptr<sql::PreparedStatement> stmt2(conn->prepareStatement("CALL CPP1()"));
			stmt2->execute();

			std::auto_ptr<sql::ResultSet> rset1(stmt2->getResultSet());
			ensure("res1 is NULL", rset1.get() != NULL);
			ensure_equal_int("res1 is empty", rset1->next(), true);
			eensure_equal_intsure("Wrong data", rset1->getInt(1), 42);
			ensure_equal_int("res1 has more rows ", rset1->next(), false);

			/* Here comes the status result set*/
			std::auto_ptr<sql::ResultSet> rset2(stmt2->getResultSet());
			ensure("res2 is not NULL", rset2.get() == NULL);

			/* drop procedure is not supported for preparing */
			stmt1->execute("DROP PROCEDURE CPP1");
		}

		{
			std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
			stmt1->execute("DROP PROCEDURE IF EXISTS CPP1");
			stmt1->execute("CREATE PROCEDURE CPP1() SELECT 42");

			stmt1->execute("CALL CPP1()");
			std::auto_ptr<sql::ResultSet> rset1(stmt1->getResultSet());
			ensure("res1 is NULL", rset1.get() != NULL);
			ensure_equal_int("res1 is empty", rset1->next(), true);
			ensure_equal_int("Wrong data", rset1->getInt(1), 42);
			ensure_equal_int("res1 has more rows ", rset1->next(), false);

			/* Here comes the status result set*/
			std::auto_ptr<sql::ResultSet> rset2(stmt1->getResultSet());
			ensure_equal_int("res2 is not NULL", rset2.get(), NULL);

			stmt1->execute("DROP PROCEDURE CPP1");
		}
#endif
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ getMetadata() */
static void test_result_set_11(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt1(conn->createStatement());
		ensure("stmt1 is NULL", stmt1.get() != NULL);

		ensure("Data not populated", true == populate_test_table(conn));

		std::auto_ptr<sql::ResultSet> rset1(stmt1->executeQuery("SELECT * FROM test_function"));
		ensure("res1 is NULL", rset1.get() != NULL);
		ensure("res1 is empty", rset1->next() != false);

		std::auto_ptr<const sql::ResultSetMetaData> meta1(rset1->getMetaData());
		ensure("column name differs", !meta1->getColumnName(1).compare("a"));
		ensure("column name differs", !meta1->getColumnName(2).compare("b"));
		ensure("column name differs", !meta1->getColumnName(3).compare("c"));
		ensure("column name differs", !meta1->getColumnName(4).compare("d"));
		ensure("column name differs", !meta1->getColumnName(5).compare("e"));

		ensure_equal_int("bad case sensitivity", meta1->isCaseSensitive(1), false);
		ensure_equal_int("bad case sensitivity", meta1->isCaseSensitive(2), false);
		ensure_equal_int("bad case sensitivity", meta1->isCaseSensitive(3), false);
		ensure_equal_int("bad case sensitivity", meta1->isCaseSensitive(4), false);
		ensure_equal_int("bad case sensitivity", meta1->isCaseSensitive(5), true);

		ensure_equal_int("bad case sensitivity", meta1->isCurrency(1), false);
		ensure_equal_int("bad case sensitivity", meta1->isCurrency(2), false);
		ensure_equal_int("bad case sensitivity", meta1->isCurrency(3), false);
		ensure_equal_int("bad case sensitivity", meta1->isCurrency(4), false);
		ensure_equal_int("bad case sensitivity", meta1->isCurrency(5), false);

		try {
			meta1->getColumnName(0);
			meta1->isCaseSensitive(0);
			meta1->isCurrency(0);
			ensure("Exception not correctly thrown", false);
		} catch (sql::DbcException *e) {
			ensure("Exception correctly thrown", true);
			delete e;
		}
		try {
			meta1->getColumnName(100);
			meta1->isCaseSensitive(100);
			meta1->isCurrency(100);
			ensure("Exception not correctly thrown", false);
		} catch (sql::DbcException *e) {
			ensure("Exception correctly thrown", true);
			delete e;
		}
		/*
			a integer unsigned not null,
			b integer,
			c integer default null,
			d char(10),
			e varchar(10) character set utf8 collate utf8_bin
		*/


	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */

#if 0
/* {{{ General test 0 */
static void test_general_0(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::DatabaseMetaData> meta(conn->getMetaData());
		std::auto_ptr<sql::ResultSet> rset(meta->getSchemata());

		while (rset->next()) {
			std::auto_ptr<sql::ResultSet> rset2(meta->getSchemaObjects("", rset->getString("schema_name")));

			while (rset2->next())  {
				rset2->getString("object_type").c_str();
				rset2->getString("name").c_str();
				rset2->getString("ddl").c_str();
			}
		}
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ General test 1 */
static void test_general_1(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::Statement> stmt(conn->createStatement());

		stmt->execute("DROP TABLE IF EXISTS test.product");
		stmt->execute("CREATE TABLE test.product(idproduct INT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(80))");

		conn->setAutoCommit(0);


		std::auto_ptr<sql::PreparedStatement> prepStmt(conn->prepareStatement("INSERT INTO test.product (idproduct, name) VALUES(?, ?)"));
		prepStmt->setInt(0, 1);
		prepStmt->setString(1, "The answer is 42");
		prepStmt->executeUpdate();

		std::auto_ptr<sql::ResultSet> rset1(stmt->executeQuery("SELECT * FROM test.product"));

		ensure_equal_int("Empty result set", rset1->next(), true);
		ensure("Wrong data", !rset1->getString(2).compare("The answer is 42"));
		ensure("Wrong data", !rset1->getString("name").compare("The answer is 42"));
		ensure_equal_int("Non-Empty result set", rset1->next(), false);

		conn->rollback();

		std::auto_ptr<sql::ResultSet> rset2(stmt->executeQuery("SELECT * FROM test.product"));

		ensure_equal_int("Non-Empty result set", rset1->next(), false);

		stmt->execute("DROP TABLE IF EXISTS test.product");
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */
#endif

/* {{{	*/
static void test_prep_statement_0(sql::Connection * conn)
{
	ENTER_FUNCTION();
	try {
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT 1"));
			stmt->execute();
			std::auto_ptr<sql::ResultSet> rset1(stmt->getResultSet());
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?"));
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		/* Bind but don't execute. There should be no leak */
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?, ?, ?"));
			stmt->setInt(0, 1);
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		/* Bind two different types for the same column. There should be no leak */
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?"));
			stmt->setString(0, "Hello MySQL");
			stmt->setInt(0, 42);
			stmt->execute();
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		/* Execute without fetching the result set. The connector should clean the wire */
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?, ?, ?, ?"));
			stmt->setInt(0, 1);
			stmt->setDouble(1, 2.25);
			stmt->setString(2, "Здрасти МySQL");
			stmt->setDateTime(3, "2006-11-10 16:17:18");
			stmt->execute();
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

#if 0
		/* Bind one parameter less than needed - NULL should be sent to the server . Check also multibyte fetching. */
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ? as \"Здравей_МySQL\" , ?, ?"));
			stmt->setInt(2, 42);
			stmt->setString(0, "Здравей МySQL! Как си?");
			stmt->execute();
			std::auto_ptr<sql::ResultSet> rset(stmt->getResultSet());
			ensure("No result set", rset.get() != NULL);
			ensure("Result set is empty", rset->next() != false);
			ensure("Incorrect value for col 1", rset->getInt(2) == 0 && true == rset->wasNull());

			ensure("Incorrect value for col 0", !rset->getString(1).compare("Здравей МySQL! Как си?") && false == rset->wasNull());
			ensure("Incorrect value for col 0", !rset->getString("Здравей_МySQL").compare("Здравей МySQL! Как си?") && false == rset->wasNull());

			ensure("Incorrect value for col 2", rset->getInt(3) == 42 && false == rset->wasNull());
			ensure("Incorrect value for col 2", !rset->getString(3).compare("42") && false == rset->wasNull());
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}
#endif
		/* try double ::execute() */
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?"));
			stmt->setString(0, "Hello World");
			for (int i = 0; i < 100; i++) {
				std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery());
			}
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			delete e;
			total_errors++;
		}

		/* try clearParameters() call */
		{
#if 0
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?, ?, ?, ?"));
			/* Step 1 */
			try {
				stmt->setInt(2, 13);
				stmt->setString(1, "Hello WORLD");
				stmt->setDouble(3, 1.25);

				stmt->clearParameters();

				stmt->execute();

				std::auto_ptr<sql::ResultSet> rset(stmt->getResultSet());

				ensure("No result set", rset.get() != NULL);
				ensure("Result set is empty", rset->next() != false);
				ensure("Incorrect value for col 1", rset->getInt(2) == 0 && true == rset->wasNull());

				ensure("Incorrect value for col 2", !rset->getString(1).compare("") && true == rset->wasNull());

				ensure("Incorrect value for col 2", rset->getInt(3) == 0 && true == rset->wasNull());
				ensure("Incorrect value for col 2", !rset->getString(3).compare("") && true == rset->wasNull());

			} catch (sql::DbcException *e) {
				printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
				delete e;
				total_errors++;
			}
			/* Step 2 */
#endif
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?, ?, ?, NULL"));
			try {
				stmt->setInt(2, 42);
				stmt->setString(0, "Hello MYSQL");
				stmt->setDouble(1, 1.25);
				std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery());
				ensure("No result set", rset.get() != NULL);
				ensure("Result set is empty", rset->next() != false);
				ensure("Incorrect value for col 1", !rset->getString(4).compare("") && true == rset->wasNull());

				ensure("Incorrect value for col 0", !rset->getString(1).compare("Hello MYSQL") && false == rset->wasNull());

				ensure("Incorrect value for col 2", rset->getInt(3) == 42 && false == rset->wasNull());
//				ensure("Incorrect value for col 2", !rset->getString(3).compare("42") && false == rset->wasNull());

				ensure("Incorrect value for col 3", rset->getDouble(2) == 1.25 && false == rset->wasNull());
			} catch (sql::DbcException *e) {
				printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
				delete e;
				total_errors++;
			}
		}
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT ?"));
			stmt->setInt(0, 1);
			stmt->execute();
			std::auto_ptr<sql::ResultSet> rset(stmt->getResultSet());
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d\n", CPPCONN_FUNC, __LINE__);
			delete e;
			total_errors++;
		}

	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test simple update statement against statement object */
static void test_prep_statement_1(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		std::auto_ptr<sql::PreparedStatement> stmt0(conn->prepareStatement("SELECT 1, 2, 3"));
		ensure("stmt0 is NULL", stmt0.get() != NULL);

		ensure("Data not populated", true == populate_test_table_PS(conn));

		std::auto_ptr<sql::PreparedStatement> stmt1(conn->prepareStatement("SELECT * FROM test_function"));
		ensure("stmt1 is NULL", stmt1.get() != NULL);
		if (false == stmt1->execute())
			ensure("False returned for SELECT", false);
		std::auto_ptr<sql::ResultSet> rset(stmt1->getResultSet());

		/* Clean */
		std::auto_ptr<sql::Statement> stmt2(conn2->createStatement());
		ensure("stmt2 is NULL", stmt2.get() != NULL);
		stmt2->execute(DATABASE_TO_USE);

		std::auto_ptr<sql::PreparedStatement> stmt3(conn2->prepareStatement("DROP TABLE test_function"));
		ensure("stmt3 is NULL", stmt3.get() != NULL);
		stmt3->execute();
	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{ Test simple update statement against statement object */
static void test_prep_statement_2(sql::Connection * conn, sql::Connection * conn2)
{
	ENTER_FUNCTION();
	try {
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("ELECT 1"));
			ensure("ERR: Exception not thrown", false);
		} catch (sql::DbcException *e) {
			delete e;
		}

		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("SELECT '1"));
			ensure("ERR: Exception not thrown", false);
		} catch (sql::DbcException *e) {
			delete e;
		}

		/* USE still cannot be prepared */
		try {
			std::auto_ptr<sql::PreparedStatement> stmt(conn->prepareStatement("USE test"));
			ensure("ERR: Exception not thrown", false);
		} catch (sql::DbcException *e) {
			delete e;
		}

	} catch (sql::DbcException *e) {
		printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
		delete e;
		total_errors++;
	} catch (...) {
		printf("ERR: Caught unknown exception at %s::%d\n", CPPCONN_FUNC, __LINE__);
		total_errors++;
	}
	LEAVE_FUNCTION();
}
/* }}} */


/* {{{	*/
int main(int argc, const char **argv)
{
	int loops;
	mysql_library_init(0, NULL, NULL);

	printf("%s\n", mysql_get_client_info());

	sql::Connection *conn, *conn2;

	const std::string port(argc >=3? argv[2]:"3306");
	const std::string user(argc >=4? argv[3]:"root");
	const std::string pass(argc >=5? argv[4]:"root");

	for (loops = 0; loops < 1; loops++) {
		const std::string host(argc >=2? argv[1]:(loops % 3 == 0 ? "127.0.0.1":(loops % 3 == 1? "localhost":"127.0.0.1")));
		printf("\n---------------  %d -----------------\n", loops + 1);

		try {
			conn = get_connection(host, port, user, pass);
		} catch (sql::mysql::MySQL_DbcException *e) {
			printf("ERR: Caught sql::mysql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			return 1;
		} catch (sql::DbcException *e) {
			printf("ERR: Caught sql::DbcException at %s::%d  %s\n", CPPCONN_FUNC, __LINE__, e->what());
			return 1;
		}
		/* XXX : Doing upcast, not the best thing, but tests getMySQLVariable */
		ensure("Testing getSessionVariable",
					0 == ((sql::mysql::MySQL_Connection *) conn)->getSessionVariable("version").compare(
								mysql_get_server_info(((sql::mysql::MySQL_Connection *) conn)->getMySQLHandle())
																							)
			);
		delete conn;

		test_connection_0(conn = get_connection(host, port, user, pass));delete conn;
		test_connection_1(conn = get_connection(host, port, user, pass));delete conn;
		test_connection_2(conn = get_connection(host, port, user, pass));delete conn;
		test_connection_3(conn = get_connection(host, port, user, pass), user);delete conn;
		test_autocommit(conn = get_connection(host, port, user, pass));delete conn;
		test_statement_0(conn = get_connection(host, port, user, pass));delete conn;

		test_statement_1(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_2(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_3(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_4(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_5(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_6(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_7(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_8(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_statement_9(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;

		test_result_set_0(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_1(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_2(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_3(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_4(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_5(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_6(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_7(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_8(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_9(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_10(conn = get_connection(host, port, user, pass));delete conn;
		test_result_set_11(conn = get_connection(host, port, user, pass));delete conn;
#if 0
		test_general_0(conn = get_connection(host, port, user, pass));delete conn;
		test_general_1(conn = get_connection(host, port, user, pass));delete conn;
#endif
		test_prep_statement_0(conn = get_connection(host, port, user, pass)); delete conn;
		test_prep_statement_1(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;
		test_prep_statement_2(conn = get_connection(host, port, user, pass), conn2 = get_connection(host, port, user, pass)); delete conn; delete conn2;

		printf("\n---------------  %d -----------------\n", loops + 1);
	}
	printf("Loops=%2d Tests= %4d Failures= %3d \n", loops, total_tests, total_errors);

	mysql_library_end();
	return 0;
}
/* }}} */


/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
