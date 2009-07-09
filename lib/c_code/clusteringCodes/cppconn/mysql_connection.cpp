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

#include "mysql_connection.h"
#include "mysql_prepared_statement.h"
#include "mysql_statement.h"
#include "mysql_exception.h"
#include "mysql_metadata.h"
#include "mysql_resultset.h"

#ifdef __GNUC__
#if __GNUC__ >= 2
#define CPPCONN_FUNC __FUNCTION__
#endif
#else
#define CPPCONN_FUNC "<unknown>"
#endif

namespace sql
{
namespace mysql
{

/* {{{ MySQL_Savepoint::MySQL_Savepoint() -I- */
MySQL_Savepoint::MySQL_Savepoint(const std::string &savepoint):
  name(savepoint)
{
}
/* }}} */


/* {{{ MySQL_Savepoint::getSavepointId() -I- */
int
MySQL_Savepoint::getSavepointId()
{
	throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__ , "Only named savepoints are supported.");
}
/* }}} */


/* {{{ MySQL_Savepoint::getSavepointName() -I- */
std::string &
MySQL_Savepoint::getSavepointName()
{
	return name;
}
/* }}} */


/* {{{ MySQL_Connection::MySQL_Connection() -I- */
MySQL_Connection::MySQL_Connection(const std::string& hostName, 
									const std::string& port, 
									const std::string& userName, 
									const std::string& password)
{
	is_valid = true;
	if (!(mysql = mysql_init(NULL))){
		throw new MySQL_DbcException(0, "OOM");	
	}
	if (!(mysql = mysql_real_connect(mysql, 
						hostName.c_str(), 
						userName.c_str(), 
						password.c_str(), 
						NULL /* schema */,
						atoi(port.c_str()),
						NULL /*socket*/,
						0))) {
		throw new MySQL_DbcException(0, "Cannot connect");
	}
	mysql_set_server_option(mysql, MYSQL_OPTION_MULTI_STATEMENTS_OFF);
	setAutoCommit(true);
	setTransactionIsolation(sql::TRANSACTION_REPEATABLE_READ);
}
/* }}} */


/* {{{ MySQL_Connection::~MySQL_Connection() -I- */
MySQL_Connection::~MySQL_Connection()
{
	if (is_valid) {
		mysql_close(mysql);
	}
}
/* }}} */


/* {{{ MySQL_Connection::clearWarnings() -I- */
void
MySQL_Connection::clearWarnings()
{
	warnings.clear();
}
/* }}} */


/* {{{ MySQL_Connection::checkClosed() -I- */
void
MySQL_Connection::checkClosed()
{
	if (!is_valid) {
		throw new MySQL_DbcException(0, "Connection has been closed");
	}
}
/* }}} */


/* {{{ MySQL_Connection::close() -I- */
void
MySQL_Connection::close()
{
	checkClosed();
	mysql_close(mysql);
	mysql = NULL;
	is_valid = false;
}
/* }}} */


/* {{{ MySQL_Connection::commit() -I- */
void
MySQL_Connection::commit()
{
	checkClosed();
	mysql_commit(mysql);
}
/* }}} */


/* {{{ MySQL_Connection::createStatement() -I- */
sql::Statement * MySQL_Connection::createStatement()
{
	checkClosed();
	return new MySQL_Statement(this);
}
/* }}} */


/* {{{ MySQL_Connection::getAutoCommit() -I- */
bool
MySQL_Connection::getAutoCommit()
{
	return autocommit;
}
/* }}} */


/* {{{ MySQL_Connection::getCatalog() -I- */
std::string *
MySQL_Connection::getCatalog()
{
	checkClosed();
	std::auto_ptr<sql::Statement> stmt(createStatement());
	std::auto_ptr<ResultSet> rset(stmt->executeQuery("SELECT SCHEMA()"));
	rset->next();
	return rset->isNull(1)? NULL:new std::string(rset->getString(1));
}
/* }}} */


/* {{{ MySQL_Connection::getClientInfo() -I- */
const std::string&
MySQL_Connection::getClientInfo(const std::string& name)
{
	static const std::string clientInfo("cppconn");
	return clientInfo;
}
/* }}} */


/* {{{ MySQL_Connection::getMetaData() -I- */
DatabaseMetaData *
MySQL_Connection::getMetaData()
{
	checkClosed();
	return new MySQL_ConnectionMetaData(this);
}
/* }}} */


/* {{{ MySQL_Connection::getMySQLHandle() -I- */
MYSQL *
MySQL_Connection::getMySQLHandle()
{
	checkClosed();
	return mysql;
}
/* }}} */


/* {{{ MySQL_Connection::getTransactionIsolation() -I- */
enum_transaction_isolation
MySQL_Connection::getTransactionIsolation()
{
	return txIsolationLevel;
}
/* }}} */


/* {{{ MySQL_Connection::getWarnings() -I- */
void
MySQL_Connection::getWarnings()
{
	checkClosed();
	std::auto_ptr<sql::Statement> stmt(createStatement());
	std::auto_ptr<ResultSet> rset(stmt->executeQuery("SHOW WARNINGS"));
	while (rset->next()) {
		warnings.push_back(std::string(rset->getString(3)));
	}
}
/* }}} */


/* {{{ MySQL_Connection::isClosed() -I- */
bool
MySQL_Connection::isClosed()
{
	return !is_valid;;
}
/* }}} */


/* {{{ MySQL_Connection::nativeSQL() -I- */
std::string *
MySQL_Connection::nativeSQL(const std::string& sql)
{
	checkClosed();
	return new std::string(sql.c_str());
}
/* }}} */


/* {{{ MySQL_Connection::prepareStatement() -I- */
sql::PreparedStatement *
MySQL_Connection::prepareStatement(const std::string& sql)
{
	checkClosed();
	MYSQL_STMT *stmt = mysql_stmt_init(mysql);

	if (!stmt) {
		throw new MySQL_DbcException(mysql_errno(mysql), mysql_error(mysql));
	}

	if (mysql_stmt_prepare(stmt, sql.c_str(), static_cast<int>(sql.length()))) {
		MySQL_DbcException *e = new MySQL_DbcException(mysql_stmt_errno(stmt), mysql_stmt_error(stmt));
		mysql_stmt_close(stmt);
		throw e;
	}

	return new MySQL_Prepared_Statement(stmt, this);
}
/* }}} */


/* {{{ MySQL_Connection::releaseSavepoint() -I- */
void
MySQL_Connection::releaseSavepoint(Savepoint * savepoint)
{
	checkClosed();
	if (getAutoCommit()) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__ , "The connection is in autoCommit mode");
	}
	std::string sql("RELEASE SAVEPOINT ");
	sql.append(savepoint->getSavepointName());

	std::auto_ptr<sql::Statement> stmt(createStatement());
	stmt->execute(sql);
}
/* }}} */


/* {{{ MySQL_Connection::rollback() -I- */
void
MySQL_Connection::rollback()
{
	checkClosed();
	mysql_rollback(mysql);
}
/* }}} */


/* {{{ MySQL_Connection::rollback() -I- */
void
MySQL_Connection::rollback(Savepoint * savepoint)
{
	checkClosed();
	if (getAutoCommit()) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__ , "The connection is in autoCommit mode");
	}
	std::string sql("ROLLBACK TO SAVEPOINT ");
	sql.append(savepoint->getSavepointName());

	std::auto_ptr<sql::Statement> stmt(createStatement());
	stmt->execute(sql);
}
/* }}} */


/* {{{ MySQL_Connection::setCatalog() -I- */
void
MySQL_Connection::setCatalog(const std::string& catalog)
{
	checkClosed();
	std::string sql("USE ");
	sql.append(catalog);

	std::auto_ptr<sql::Statement> stmt(createStatement());
	stmt->execute(sql);
}
/* }}} */


/* {{{ MySQL_Connection::setSavepoint() -I- */
Savepoint *
MySQL_Connection::setSavepoint()
{
	checkClosed();
	throw new sql::DbcMethodNotImplemented("Please use MySQL_Connection::setSavepoint(const std::string& name)");
}
/* }}} */


/* {{{ MySQL_Connection::setSavepoint() -I- */
Savepoint *
MySQL_Connection::setSavepoint(const std::string& name)
{
	checkClosed();
	if (getAutoCommit()) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__ , "The connection is in autoCommit mode");
	}
	if (!name.length()) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__ , "Savepoint name cannot be empty string");
	}
	std::string sql("SAVEPOINT ");
	sql.append(name);

	std::auto_ptr<sql::Statement> stmt(createStatement());
	stmt->execute(sql);

	return new MySQL_Savepoint(name);
}
/* }}} */


/* {{{ MySQL_Connection::setAutoCommit() -I- */
void
MySQL_Connection::setAutoCommit(bool autoCommit)
{
	checkClosed();
	mysql_autocommit(mysql, autoCommit); 
	autocommit = autoCommit;
}
/* }}} */


/* {{{ MySQL_Connection::setTransactionIsolation() -I- */
void
MySQL_Connection::setTransactionIsolation(enum_transaction_isolation level)
{
	checkClosed();
	const char * q;
	switch (level) {
		case TRANSACTION_SERIALIZABLE:
			q = "SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE";
			break;
		case TRANSACTION_REPEATABLE_READ:
			q =  "SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ";
			break;
		case TRANSACTION_READ_COMMITTED:
			q = "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED";
			break;
		case TRANSACTION_READ_UNCOMMITTED:
			q = "SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED";
			break;
		default:
			throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__ , "MySQL_Connection::setTransactionIsolation()");
	}		
	txIsolationLevel = level;
	mysql_query(mysql, q);
}
/* }}} */


/* {{{ MySQL_Connection::getSessionVariable() -I- */
std::string
MySQL_Connection::getSessionVariable(const char * varname)
{
	checkClosed();
	std::auto_ptr<sql::Statement> stmt(createStatement());
	std::string q = std::string("SHOW SESSION VARIABLES LIKE '").append(varname).append("'");
	
	std::auto_ptr<ResultSet> rset(stmt->executeQuery(q));

	if (rset->next()) {
		return rset->getString(2);
	}
	return NULL;
}
/* }}} */

}; /* namespace mysql */
}; /* namespace sql */
/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */

