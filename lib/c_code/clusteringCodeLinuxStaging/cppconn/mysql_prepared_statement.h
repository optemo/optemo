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

#ifndef _MYSQL_PREPARED_STATEMENT_H_
#define _MYSQL_PREPARED_STATEMENT_H_

#include "dbciface/prepared_statement.h"

#include "mysql_private_iface.h"

namespace sql
{
namespace mysql
{
class MySQL_Connection;

class MySQL_Prepared_Statement : public sql::PreparedStatement
{
protected:
	MySQL_Connection *connection;
	MYSQL_STMT *stmt;
	MYSQL_BIND *param_bind;
	int param_count;

	int resultSetConcurrency;
	int resultSetType;

	std::list<std::string> warnings;

	bool isClosed;

	virtual void do_query();
	virtual void checkClosed();
	virtual void closeIntern();

	virtual void bindResult();

	int num_fields;
	my_bool *is_null;
	my_bool *err;
	unsigned long *len;
	MYSQL_BIND *result_bind;

public:

	MySQL_Prepared_Statement(MYSQL_STMT *s, MySQL_Connection *conn);
	virtual ~MySQL_Prepared_Statement();

	sql::Connection *getConnection();

	void cancel();

	void clearParameters();
	
	void clearWarnings();

	void close();

	bool execute();
	bool execute(const std::string& sql);

	sql::ResultSet *executeQuery();
	sql::ResultSet *executeQuery(const std::string& sql);

	int executeUpdate();
	int executeUpdate(const std::string& sql);

	bool getMoreResults();

	int getQueryTimeout();

	sql::ResultSet *getResultSet();

	int getUpdateCount();

	void getWarnings();/* should return differen type */

	void setBoolean(int parameterIndex, bool value) { setInt(parameterIndex, value); }

	void setBigInt(int parameterIndex, const std::string& value);

	void setDateTime(int parameterIndex, const std::string& value);
	
	void setDouble(int parameterIndex, double value);

	void setInt(int parameterIndex, int value);

	void setLong(int parameterIndex, long long value);

	void setString(int parameterIndex, const std::string& value);

private:
	/* Prevent use of these */
	MySQL_Prepared_Statement(const MySQL_Prepared_Statement &);
	void operator=(MySQL_Prepared_Statement &);
};

}; /* namespace mysql */
}; /* namespace sql */
#endif // _MYSQL_PREPARED_STATEMENT_H_


/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
