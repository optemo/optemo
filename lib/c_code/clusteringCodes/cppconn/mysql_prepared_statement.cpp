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
#include "mysql_exception.h"
#include "mysql_statement.h"
#include "mysql_prepared_statement.h"
#include "mysql_ps_resultset.h"


#define mysql_stmt_conn(s) (s)->mysql


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

/*
  Plug only relevant parts of Zend and main/streams and statically build them.
  Remove the ZEND MM, and put own implementation, which is just malloc.
*/

/* {{{ get_new_param_bind() -I- */
static MYSQL_BIND *
get_new_param_bind(int param_count)
{
	if (!param_count) {
		return NULL;
	}
	MYSQL_BIND * bind = new MYSQL_BIND[param_count];
	memset(bind, 0, sizeof(MYSQL_BIND)*param_count);

	return bind;
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::MySQL_Prepared_Statement() -I- */
MySQL_Prepared_Statement::MySQL_Prepared_Statement(MYSQL_STMT *s, MySQL_Connection * conn) 
	:connection(conn), stmt(s), param_bind(NULL), isClosed(false)
{
	param_count = mysql_stmt_param_count(s);
	if (param_count) {
		param_bind = get_new_param_bind(param_count);
		for (int i = 0; i < param_count; i++) {
			param_bind[i].is_null_value = 1;
		}
	}
	result_bind = NULL;
	is_null = NULL;
	err = NULL;
	len = NULL;
	num_fields = 0;
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::~MySQL_Prepared_Statement() -I- */
MySQL_Prepared_Statement::~MySQL_Prepared_Statement()
{
	/*
	  This will free param_bind.
	  We should not do it or there will be double free.
	*/
	if (!isClosed) {
		closeIntern();
	}
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::do_query() -I- */
void
MySQL_Prepared_Statement::do_query()
{
	if (param_count && mysql_stmt_bind_param(stmt, param_bind)) {
		throw new MySQL_DbcException(mysql_stmt_errno(stmt), mysql_stmt_error(stmt));	
	}

	if (mysql_stmt_execute(stmt)) {
		throw new MySQL_DbcException(mysql_stmt_errno(stmt), mysql_stmt_error(stmt));	
	}
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::clearParameters() -U- */
void
MySQL_Prepared_Statement::clearParameters()
{
	checkClosed();
	if (param_bind) {
		throw new DbcMethodNotImplemented("MySQL_Prepared_Statement::clearParameters");
	}
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::getConnection() -I- */
Connection *
MySQL_Prepared_Statement::getConnection()
{
	checkClosed();
	return connection;
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::execute() -I- */
bool MySQL_Prepared_Statement::execute()
{
	checkClosed();
	do_query();
	return (mysql_stmt_field_count(stmt) > 0);
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::execute() -U- */
bool MySQL_Prepared_Statement::execute(const std::string& sql)
{
	throw new sql::DbcMethodNotImplemented("MySQL_Prepared_Statement::execute");
}
/* }}} */


typedef std::pair<char *, int> BufferSizePair;
static BufferSizePair
allocate_buffer_for_type(MYSQL_FIELD *field)
{
	switch (field->type) {
		case MYSQL_TYPE_TINY:
			return BufferSizePair(new char[1], 1);
		case MYSQL_TYPE_SHORT:
			return BufferSizePair(new char[2], 2);
		case MYSQL_TYPE_INT24:
		case MYSQL_TYPE_LONG:
		case MYSQL_TYPE_FLOAT:  
			return BufferSizePair(new char[4], 4);
		case MYSQL_TYPE_DOUBLE:
		case MYSQL_TYPE_LONGLONG:
			return BufferSizePair(new char[8], 8);  
		case MYSQL_TYPE_DATE:
		case MYSQL_TYPE_TIME:
		case MYSQL_TYPE_DATETIME:
			return BufferSizePair(new char[sizeof(MYSQL_TIME)], sizeof(MYSQL_TIME));
		case MYSQL_TYPE_STRING:
		case MYSQL_TYPE_TINY_BLOB:
		case MYSQL_TYPE_BLOB:
		case MYSQL_TYPE_MEDIUM_BLOB:
		case MYSQL_TYPE_LONG_BLOB:
		case MYSQL_TYPE_VAR_STRING:
			if (!(field->max_length))
				return BufferSizePair(new char[1], 1);
			return BufferSizePair(new char[field->max_length], field->max_length);

		case MYSQL_TYPE_DECIMAL:
		case MYSQL_TYPE_NEWDECIMAL:
			return BufferSizePair(new char[64], 64);
		case MYSQL_TYPE_TIMESTAMP:
		case MYSQL_TYPE_YEAR:
			return BufferSizePair(new char[10], 10);
		case MYSQL_TYPE_SET:
		case MYSQL_TYPE_BIT:
		case MYSQL_TYPE_ENUM:
		case MYSQL_TYPE_GEOMETRY:
		case MYSQL_TYPE_NULL:
			if (!(field->max_length))
				return BufferSizePair(new char[1], 1);
			return BufferSizePair(new char[field->max_length], field->max_length);
		default:
			throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "allocate_buffer_for_type: invalid result_bind data type");
	}
}


/* {{{ MySQL_Prepared_Statement::bindResult() -I- */
void
MySQL_Prepared_Statement::bindResult()
{
	for (int i = 0; i < num_fields; i++) {
		delete[] (char *) result_bind[i].buffer;
	}
	delete[] result_bind;
	delete[] is_null;
	delete[] err;
	delete[] len;

	result_bind = NULL;
	is_null = NULL;
	err = NULL;
	len = NULL;

	MYSQL_RES * result_meta = mysql_stmt_result_metadata(stmt);
	num_fields = mysql_stmt_field_count(stmt);
	result_bind = new MYSQL_BIND[num_fields];
	memset(result_bind, 0, sizeof(MYSQL_BIND) * num_fields);

	is_null = new my_bool[num_fields];
	memset(is_null, 0, sizeof(my_bool) * num_fields);
	
	err = new my_bool[num_fields];
	memset(err, 0, sizeof(my_bool) * num_fields);

	len = new unsigned long[num_fields];
	memset(len, 0, sizeof(unsigned long) * num_fields);

	my_bool	tmp=1;
	mysql_stmt_attr_set(stmt, STMT_ATTR_UPDATE_MAX_LENGTH, &tmp);
	mysql_stmt_store_result(stmt);

	for (int i = 0; i < num_fields; i++) {
		MYSQL_FIELD *field = mysql_fetch_field(result_meta);

		BufferSizePair p = allocate_buffer_for_type(field);
		result_bind[i].buffer_type	= field->type;
		result_bind[i].buffer		= p.first;
		result_bind[i].buffer_length= p.second;
		result_bind[i].length		= &len[i];
		result_bind[i].is_null		= &is_null[i];
		result_bind[i].error		= &err[i];
		if (field->type == MYSQL_TYPE_BLOB || field->type == MYSQL_TYPE_MEDIUM_BLOB ||
			field->type == MYSQL_TYPE_LONG_BLOB) {

			if (!(result_bind[i].buffer_length = field->max_length))
				++result_bind[i].buffer_length;
			result_bind[i].buffer = new char[result_bind[i].buffer_length];
		}
	}
	mysql_free_result(result_meta);
	result_meta = NULL;
	if (mysql_stmt_bind_result(stmt, result_bind)) {
		throw new sql::DbcException(CPPCONN_FUNC, __LINE__, "Can't bind");
	}

}

/* {{{ MySQL_Prepared_Statement::executeQuery() -I- */
sql::ResultSet *
MySQL_Prepared_Statement::executeQuery()
{
	checkClosed();

	do_query();

	bindResult();

	return new MySQL_Prepared_ResultSet(stmt, this);
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::executeQuery() -U- */
sql::ResultSet *
MySQL_Prepared_Statement::executeQuery(const std::string& sql)
{
	throw new sql::DbcMethodNotImplemented("MySQL_Prepared_Statement::executeQuery"); /* TODO - what to do? Comes from Statement */
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::executeUpdate() -I- */
int
MySQL_Prepared_Statement::executeUpdate()
{
	checkClosed();
	do_query();
	return static_cast<int>(mysql_stmt_affected_rows(stmt));
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::executeUpdate() -U- */
int
MySQL_Prepared_Statement::executeUpdate(const std::string& sql)
{
	throw new sql::DbcMethodNotImplemented("MySQL_Prepared_Statement::executeUpdate"); /* TODO - what to do? Comes from Statement */
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::setDateTime() -I- */
void
MySQL_Prepared_Statement::setDateTime(int parameterIndex, const std::string& value)
{
	checkClosed();
	if (parameterIndex >= param_count || parameterIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_Prepared_Statement::setDateTime: invalid 'parameterIndex'");
	}
	setString(parameterIndex, value);
}
/* }}} */


typedef std::pair<char *, int> BufferSizePair;
static BufferSizePair
allocate_buffer_for_type(enum_field_types t)
{
	switch(t) {
		case MYSQL_TYPE_TINY:
			return BufferSizePair(new char[1], 1);
		case MYSQL_TYPE_SHORT:
			return BufferSizePair(new char[2], 2);
		case MYSQL_TYPE_INT24:
		case MYSQL_TYPE_LONG:
		case MYSQL_TYPE_FLOAT:  
			return BufferSizePair(new char[4], 4);
		case MYSQL_TYPE_DOUBLE:
		case MYSQL_TYPE_LONGLONG:
			return BufferSizePair(new char[8], 8);  
		case MYSQL_TYPE_DATE:
		case MYSQL_TYPE_TIME:
		case MYSQL_TYPE_DATETIME:
			return BufferSizePair(new char[sizeof(MYSQL_TIME)], sizeof(MYSQL_TIME));  
		case MYSQL_TYPE_STRING:
		case MYSQL_TYPE_BLOB:
		case MYSQL_TYPE_VAR_STRING:
			return BufferSizePair(NULL, 0);

		case MYSQL_TYPE_DECIMAL:
		case MYSQL_TYPE_NEWDECIMAL:
			return BufferSizePair(new char[64], 64);
		case MYSQL_TYPE_TIMESTAMP:
		case MYSQL_TYPE_YEAR:
			return BufferSizePair(new char[10], 10);
		case MYSQL_TYPE_SET:
		case MYSQL_TYPE_BIT:
		case MYSQL_TYPE_ENUM:
		case MYSQL_TYPE_GEOMETRY:
		case MYSQL_TYPE_NULL:
			return BufferSizePair(NULL, 0);
		default:
			throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "allocate_buffer_for_type: invalid result_bind data type");
	}
}


/* {{{ MySQL_Prepared_Statement::setDouble() -I- */
void
MySQL_Prepared_Statement::setDouble(int parameterIndex, double value)
{
	checkClosed();

	if (parameterIndex >= param_count || parameterIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_Prepared_Statement::setDouble: invalid 'parameterIndex'");
	}

	enum_field_types t = MYSQL_TYPE_DOUBLE;

	BufferSizePair p = allocate_buffer_for_type(t);

	param_bind[parameterIndex].buffer_type	= t;
	delete[] (char *) param_bind[parameterIndex].buffer;
	param_bind[parameterIndex].buffer		= p.first;
	param_bind[parameterIndex].buffer_length= 0;
	param_bind[parameterIndex].is_null_value= 0;
	if (!param_bind[parameterIndex].length) {
		delete param_bind[parameterIndex].length;
	}
	param_bind[parameterIndex].length		= NULL;

	memcpy(param_bind[parameterIndex].buffer, &value, p.second);
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::setInt() -I- */
void
MySQL_Prepared_Statement::setInt(int parameterIndex, int value)
{
	checkClosed();

	if (parameterIndex >= param_count || parameterIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_Prepared_Statement::setInt: invalid 'parameterIndex'");
	}

	enum_field_types t = MYSQL_TYPE_LONG;

	BufferSizePair p = allocate_buffer_for_type(t);

	param_bind[parameterIndex].buffer_type	= t;
	delete[] (char *) param_bind[parameterIndex].buffer;
	param_bind[parameterIndex].buffer		= p.first;
	param_bind[parameterIndex].buffer_length= 0;
	param_bind[parameterIndex].is_null_value= 0;
	delete param_bind[parameterIndex].length;
	param_bind[parameterIndex].length		= NULL;

	memcpy(param_bind[parameterIndex].buffer, &value, p.second);
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::setLong() -I- */
void
MySQL_Prepared_Statement::setLong(int parameterIndex, long long value)
{
	checkClosed();

	if (parameterIndex >= param_count || parameterIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_Prepared_Statement::setLong: invalid 'parameterIndex'");
	}

	enum_field_types t = MYSQL_TYPE_LONGLONG;

	BufferSizePair p = allocate_buffer_for_type(t);

	param_bind[parameterIndex].buffer_type	= t;
	delete[] (char *) param_bind[parameterIndex].buffer;
	param_bind[parameterIndex].buffer		= p.first;
	param_bind[parameterIndex].buffer_length= 0;
	param_bind[parameterIndex].is_null_value= 0;
	delete param_bind[parameterIndex].length;
	param_bind[parameterIndex].length		= NULL;

	memcpy(param_bind[parameterIndex].buffer, &value, p.second);
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::setBigInt() -I- */
void
MySQL_Prepared_Statement::setBigInt(int parameterIndex, const std::string& value)
{
	checkClosed();
	if (parameterIndex >= param_count || parameterIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_Prepared_Statement::setBigInt: invalid 'parameterIndex'");
	}
	setString(parameterIndex, value);
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::cancel() -U- */
void
MySQL_Prepared_Statement::cancel()
{
	checkClosed();
	throw new DbcMethodNotImplemented("MySQL_Prepared_Statement::cancel");
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::getResultSet() -I- */
sql::ResultSet *
MySQL_Prepared_Statement::getResultSet()
{
	checkClosed();
	if (mysql_more_results(mysql_stmt_conn(stmt))) {
		mysql_next_result(mysql_stmt_conn(stmt));
	}
	bindResult();

	return new MySQL_Prepared_ResultSet(stmt, this);
}
/* }}} */

/* {{{ MySQL_Prepared_Statement::clearWarnings() -I- */
void
MySQL_Prepared_Statement::clearWarnings()
{
	checkClosed();
	warnings.clear();
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::close() -I- */
void
MySQL_Prepared_Statement::close()
{
	checkClosed();
	closeIntern();
}
/* }}} */



/* {{{ MySQL_Prepared_Statement::getMoreResults() -U- */
bool
MySQL_Prepared_Statement::getMoreResults()
{
	checkClosed();
	throw new DbcMethodNotImplemented("MySQL_Prepared_Statement::getMoreResults");
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::getQueryTimeout() -U- */
int
MySQL_Prepared_Statement::getQueryTimeout()
{
	checkClosed();
	throw new DbcMethodNotImplemented("MySQL_Prepared_Statement::getQueryTimeout");
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::getUpdateCount() -U- */
int 
MySQL_Prepared_Statement::getUpdateCount()
{
	checkClosed();
	throw new DbcMethodNotImplemented("MySQL_Prepared_Statement::getUpdateCount");
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::getWarnings() -I- */
void
MySQL_Prepared_Statement::getWarnings()
{
	checkClosed();
	std::auto_ptr<sql::Statement> stmt(connection->createStatement());
	std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery("SHOW WARNINGS"));
	while (rset->next()) {
		this->warnings.push_back(std::string(rset->getString(3)));
	}
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::setString() -I- */
void
MySQL_Prepared_Statement::setString(int parameterIndex, const std::string& value)
{
	checkClosed();

	if (parameterIndex >= param_count || parameterIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_Prepared_Statement::setString: invalid 'parameterIndex'");
	}
	enum_field_types t = MYSQL_TYPE_STRING;

	param_bind[parameterIndex].buffer_type	= t;
	delete[] (char *) param_bind[parameterIndex].buffer;
	param_bind[parameterIndex].buffer		= memcpy(new char[value.length() + 1], value.c_str(), value.length() + 1);
	param_bind[parameterIndex].buffer_length= static_cast<unsigned long>(value.length()) + 1;
	param_bind[parameterIndex].is_null_value= 0;
	// TODO: allocate one buffer for length of all fields, when initing a new stmt
	delete param_bind[parameterIndex].length;
	param_bind[parameterIndex].length = new unsigned long(static_cast<unsigned long>(value.length()));
}
/* }}} */

/* {{{ MySQL_Prepared_Statement::checkClosed() -I- */
void
MySQL_Prepared_Statement::checkClosed()
{
	if (isClosed) {
		throw new MySQL_DbcException(0, "Statement has been closed");
	}
}
/* }}} */


/* {{{ MySQL_Prepared_Statement::closeIntern() -I- */
void
MySQL_Prepared_Statement::closeIntern()
{
	mysql_stmt_close(stmt);
	for (int i = 0; i < param_count; i++) {
		delete (char*) param_bind[i].length;
		delete[] (char*) param_bind[i].buffer;
	}
	delete[] param_bind;


	for (int i = 0; i < num_fields; i++) {
		delete[] (char *) result_bind[i].buffer;
	}
	delete[] result_bind;
	delete[] is_null;
	delete[] err;
	delete[] len;
}
/* }}} */

};/* namespace mysql */
};/* namespace sql */

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
