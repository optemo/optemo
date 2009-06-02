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


#include <algorithm>
#include "mysql_connection.h"
#include "mysql_exception.h"
#include "mysql_statement.h"
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

/* {{{ MySQL_Statement::MySQL_Statement() -I- */
MySQL_Statement::MySQL_Statement(MySQL_Connection *conn) 
	: connection(conn), isClosed(false)
{

}
/* }}} */


/* {{{ MySQL_Statement::~MySQL_Statement() -I- */
MySQL_Statement::~MySQL_Statement()
{

}
/* }}} */


/* {{{ MySQL_Statement::do_query() -I- */
void
MySQL_Statement::do_query(const char *q, int length)
{
	checkClosed();
	MYSQL *mysql = connection->getMySQLHandle();
	if (mysql_real_query(mysql, q, length) && mysql_errno(mysql)) {
		throw new MySQL_DbcException(mysql_errno(mysql), mysql_error(mysql));
	}
}
/* }}} */


/* {{{ MySQL_Statement::get_resultset() -I- */
MYSQL_RES_Wrapper *
MySQL_Statement::get_resultset()
{
	checkClosed();

	MYSQL *mysql = connection->getMySQLHandle();
	
	MYSQL_RES * result = mysql_store_result(mysql);
	if (result == NULL) {
		throw new MySQL_DbcException(mysql_errno(mysql), mysql_error(mysql));
	}

	return new MYSQL_RES_Wrapper(result);
}
/* }}} */


/* {{{ MySQL_Statement::cancel() -U- */
void
MySQL_Statement::cancel()
{
	checkClosed();
	throw new sql::DbcMethodNotImplemented("MySQL_Statement::cancel");
}
/* }}} */


/* {{{ MySQL_Statement::execute() -I- */
bool
MySQL_Statement::execute(const std::string& sql)
{
	checkClosed();
	do_query(sql.c_str(), static_cast<int>(sql.length()));
	return (mysql_field_count(connection->getMySQLHandle()) > 0);
}
/* }}} */


/* {{{ MySQL_Statement::executeQuery() -I- */
sql::ResultSet *
MySQL_Statement::executeQuery(const std::string& sql)
{
	checkClosed();
	do_query(sql.c_str(), static_cast<int>(sql.length()));
	return new MySQL_ResultSet(get_resultset(), this);
}
/* }}} */


/* {{{ MySQL_Statement::executeUpdate() -I- */
int
MySQL_Statement::executeUpdate(const std::string& sql)
{
	checkClosed();
	do_query(sql.c_str(), static_cast<int>(sql.length()));
	if (mysql_field_count(connection->getMySQLHandle())) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "Statement returning result set");
	}
	return static_cast<int>(mysql_affected_rows(connection->getMySQLHandle()));
}
/* }}} */


/* {{{ MySQL_Statement::getConnection() -I- */
sql::Connection *
MySQL_Statement::getConnection()
{
	checkClosed();
	return connection;
}
/* }}} */


/* {{{ MySQL_Statement::getResultSet() -I- */
sql::ResultSet *
MySQL_Statement::getResultSet()
{
	checkClosed();

	MYSQL *mysql = connection->getMySQLHandle();

	if (mysql_more_results(mysql)) {
		mysql_next_result(mysql);
	}

	MYSQL_RES * result = mysql_store_result(mysql);
	if (!result) {
		return NULL;
	}
	
	return new MySQL_ResultSet(new MYSQL_RES_Wrapper(result), this);
}
/* }}} */


/* {{{ MySQL_Statement::clearWarnings() -I- */
void
MySQL_Statement::clearWarnings()
{
	checkClosed();
	warnings.clear();
}
/* }}} */


/* {{{ MySQL_Statement::close() -i- */
void
MySQL_Statement::close()
{
	checkClosed();
	isClosed = true;
}
/* }}} */


/* {{{ MySQL_Statement::getMoreResults() -U- */
bool
MySQL_Statement::getMoreResults()
{
	checkClosed();
	throw new sql::DbcMethodNotImplemented("MySQL_Statement::getMoreResults");
}
/* }}} */


/* {{{ MySQL_Statement::getUpdateCount() -U- */
int
MySQL_Statement::getUpdateCount()
{
	checkClosed();
	throw new sql::DbcMethodNotImplemented("MySQL_Statement::getUpdateCount");
}
/* }}} */


/* {{{ MySQL_Statement::getWarnings() -I- */
void
MySQL_Statement::getWarnings()
{
	checkClosed();
	std::auto_ptr<sql::Statement> stmt(connection->createStatement());
	std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery("SHOW WARNINGS"));
	while (rset->next()) {
		this->warnings.push_back(std::string(rset->getString(3)));
	}
}
/* }}} */


/* {{{ MySQL_Statement::checkClosed() -I- */
void
MySQL_Statement::checkClosed()
{
	if (isClosed) {
		throw new MySQL_DbcException(0, "Statement has been closed");
	}
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
