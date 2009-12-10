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

#ifndef _MYSQL_CONSTRUCTED_RESULTSET_H_
#define _MYSQL_CONSTRUCTED_RESULTSET_H_

#include "dbciface/resultset.h"
#include "mysql_res_wrapper.h"

#include "mysql_private_iface.h"

namespace sql
{
namespace mysql
{

class MySQL_ConstructedResultSet : public sql::ResultSet
{
public:
	typedef std::list<std::string> StringList;

	MySQL_ConstructedResultSet(const StringList& fn, const StringList& rset);
	virtual ~MySQL_ConstructedResultSet();

	bool absolute(int row);

	void afterLast();

	void beforeFirst();

	void close();

	int findColumn(const std::string& columnLabel);

	bool first();

	bool getBoolean(int columnIndex);

	bool getBoolean(const std::string& columnLabel);

	// Get the given column as double
	double getDouble(int columnIndex);

	double getDouble(const std::string& columnLabel);

	// Get the given column as int
	int getInt(int columnIndex);

	int getInt(const std::string& columnLabel);

	// Get the given column as int
	long long getLong(int columnIndex);

	long long getLong(const std::string& columnLabel);

	const sql::ResultSetMetaData * getMetaData();

	const sql::Statement * getStatement();

	// Get the given column as string
	std::string getString(int columnIndex);

	std::string getString(const std::string& columnLabel);

	bool isAfterLast();

	bool isBeforeFirst();

	bool isClosed();

	bool isFirst();

	// Retrieves whether the cursor is on the last row of this sql::ResultSet object.
	bool isLast();

	bool isNull(int columnIndex);

	bool isNull(const std::string& columnLabel);

	bool last();

	bool next();

	bool previous();

	bool relative(int rows);

	size_t rowsCount();

	bool wasNull();

protected:
	void checkValid();
	void seek();

private:

	int num_fields;
	StringList rs;
	bool started;

	typedef std::map<std::string, int> FieldNameIndexMap;
	typedef std::pair<std::string, int> FieldNameIndexPair;

	FieldNameIndexMap field_name_to_index_map;
	StringList::iterator current_record;

	my_ulonglong num_rows;
	my_ulonglong row_position; /* 0 = before first row, 1 - first row, 'num_rows + 1' - after last row */

	bool is_closed;
private:
	/* Prevent use of these */
	MySQL_ConstructedResultSet(const MySQL_ConstructedResultSet &);
	void operator=(MySQL_ConstructedResultSet &);
};

}; /* namespace mysql */
}; /* namespace sql */
#endif // _MYSQL_CONSTRUCTED_RESULTSET_H_

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
