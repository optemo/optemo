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

#ifndef _MYSQL_RESULTSET_H_
#define _MYSQL_RESULTSET_H_

#include "dbciface/resultset.h"
#include "mysql_res_wrapper.h"

#include "mysql_private_iface.h"

namespace sql
{
namespace mysql
{

class MySQL_Statement;

class MySQL_ResultSet : public sql::ResultSet
{
	MYSQL_ROW row;
	MYSQL_RES_Wrapper *result;
	int num_fields;
	my_ulonglong num_rows;
	my_ulonglong row_position; /* 0 = before first row, 1 - first row, 'num_rows + 1' - after last row */

	typedef std::map<std::string, unsigned int> FieldNameIndexMap;
	typedef std::pair<std::string, unsigned int> FieldNameIndexPair;

	FieldNameIndexMap field_name_to_index_map;
	bool was_null;

	const MySQL_Statement * parent;

protected:
	void checkValid();
	void seek();

public:
	MySQL_ResultSet(MYSQL_RES_Wrapper *res, MySQL_Statement * par);

	virtual ~MySQL_ResultSet();

	bool absolute(int row);

	void afterLast();

	void beforeFirst();

	void close();

	int findColumn(const std::string& columnLabel);

	bool first();

	bool getBoolean(int columnIndex);
	bool getBoolean(const std::string& columnLabel);

	double getDouble(int columnIndex);
	double getDouble(const std::string& columnLabel);

	int getInt(int columnIndex);
	int getInt(const std::string& columnLabel);

	long long getLong(int columnIndex);
	long long getLong(const std::string& columnLabel);

	const sql::ResultSetMetaData * getMetaData();

	const sql::Statement * getStatement();

	std::string getString(int columnIndex);
	std::string getString(const std::string& columnLabel);	

	bool isAfterLast();

	bool isBeforeFirst();

	bool isClosed();

	bool isFirst();

	bool isLast();

	bool isNull(int columnIndex);

	bool isNull(const std::string& columnLabel);

	bool last();

	bool next();

	bool previous();

	bool relative(int rows);

	size_t rowsCount();

	bool wasNull();
};

}; /* namespace mysql */
}; /* namespace sql */
#endif // _MYSQL_RESULTSET_H_

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
