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

#include "mysql_res_wrapper.h"
#include "mysql_constructed_resultset.h"

#if !defined(_WIN32) && !defined(_WIN64)
#include <stdlib.h>
#else
#define atoll(x) _atoi64((x))
#endif	//	_WIN32

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

extern char * cppmysql_utf8_strup(const char *src, size_t srclen);


/* {{{ MySQL_ConstructedResultSet::MySQL_ConstructedResultSet() -I- */
MySQL_ConstructedResultSet::MySQL_ConstructedResultSet(const StringList& fn, const StringList& rset) 
  : rs(rset), started(false), row_position(0), is_closed(false)
{
	current_record = rs.begin();
	num_fields = static_cast<int>(fn.size());

	StringList::const_iterator e = fn.end();

	if (fn.size()) {
		num_rows =  rset.size() / fn.size();
	} else {
		num_rows = 0;
	}

	int idx = 0;
	for (StringList::const_iterator it = fn.begin(); it != e; it++, idx++) {
		char *tmp;
		tmp = cppmysql_utf8_strup(it->c_str(), 0);
		field_name_to_index_map[std::string(tmp)] = idx;
		free(tmp);
	}
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::~MySQL_ConstructedResultSet() -I- */
MySQL_ConstructedResultSet::~MySQL_ConstructedResultSet()
{

}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::seek() -I- */
inline void MySQL_ConstructedResultSet::seek()
{
	my_ulonglong i;
	for (i = row_position, current_record = rs.begin(); i > 0; --i) {
		int j = num_fields;
		while (j--) {
			current_record++;
		}
	}
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::absolute() -I- */
bool
MySQL_ConstructedResultSet::absolute(int row)
{
	checkValid();
	if (row > 0) {
		if (row > (int) num_rows) {
			row_position = num_rows + 1; /* after last row */
		} else {
			row_position = row;
			seek();
			return true;
		}
	} else if (row < 0) {
		if ((-row) > (int) num_rows) {
			row_position = 0; /* before first row */
		} else {
			row_position = num_rows - (-row)  + 1;
			seek();
			return true;
		}
	} else {
		/* According to the JDBC book, absolute(0) means before the result set */
		row_position = 0;
		/* no seek() here, as we are not on data*/
		beforeFirst();
	}
	return (row_position > 0 && row_position < (num_rows + 1));
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::afterLast() -I- */
void
MySQL_ConstructedResultSet::afterLast()
{
	checkValid();
	row_position = num_rows + 1;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::beforeFirst() -I- */
void
MySQL_ConstructedResultSet::beforeFirst()
{
	checkValid();
	row_position = 0;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::checkValid() -I- */
void
MySQL_ConstructedResultSet::checkValid()
{
	if (isClosed()) {
		throw new MySQL_DbcException(0, "Statement has been closed");
	}
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::close() -I- */
void
MySQL_ConstructedResultSet::close()
{
	checkValid();
	is_closed = true;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::findColumn() -I- */
int
MySQL_ConstructedResultSet::findColumn(const std::string& columnLabel)
{
	checkValid();
	char * tmp = cppmysql_utf8_strup(columnLabel.c_str(), 0);
	FieldNameIndexMap::const_iterator iter = field_name_to_index_map.find(tmp);
	free(tmp);

	if (iter == field_name_to_index_map.end()) {
		return -1;
	}
	/* findColumn returns 1-based indexes */
	return iter->second + 1;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::first() -I- */
bool
MySQL_ConstructedResultSet::first()
{
	checkValid();
	if (num_rows) {
		row_position = 1;
		seek();
	}
	return (bool) num_rows;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getBoolean() -I- */
bool
MySQL_ConstructedResultSet::getBoolean(int columnIndex)
{
	checkValid();
	return (bool) getInt(columnIndex);
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getBoolean() -I- */
bool
MySQL_ConstructedResultSet::getBoolean(const std::string& columnLabel)
{
	checkValid();
	return (bool) getInt(columnLabel);
}
/* }}} */


// Get the given column as double
/* {{{ MySQL_ConstructedResultSet::getDouble() -I- */
double
MySQL_ConstructedResultSet::getDouble(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ConstructedResultSet::getDouble: invalid value of 'columnIndex'");
	}

	StringList::iterator f = current_record;

	while (columnIndex--) {
		f++;
	}

	return atof(f->c_str());
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getDouble() -I- */
double
MySQL_ConstructedResultSet::getDouble(const std::string& columnLabel)
{
	checkValid();
	return getDouble(findColumn(columnLabel));
}
/* }}} */


// Get the given column as int
/* {{{ MySQL_ConstructedResultSet::getInt() -I- */
int
MySQL_ConstructedResultSet::getInt(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ConstructedResultSet::getInt: invalid value of 'columnIndex'");
	}

	StringList::iterator f = current_record;

	while (columnIndex--) {
		f++;
	}

	return atoi(f->c_str());
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getInt() -I- */
int
MySQL_ConstructedResultSet::getInt(const std::string& columnLabel)
{
	return getInt(findColumn(columnLabel));
}
/* }}} */


// Get the given column as int
/* {{{ MySQL_ConstructedResultSet::getLong() -I- */
long long
MySQL_ConstructedResultSet::getLong(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ConstructedResultSet::getInt: invalid value of 'columnIndex'");
	}

	StringList::iterator f = current_record;

	while (columnIndex--) {
		f++;
	}

	return atoll(f->c_str());
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getLong() -I- */
long long
MySQL_ConstructedResultSet::getLong(const std::string& columnLabel)
{
	return getLong(findColumn(columnLabel));
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getMetaData() -U- */
const sql::ResultSetMetaData *
MySQL_ConstructedResultSet::getMetaData()
{
	throw new sql::DbcMethodNotImplemented("MySQL_ConstructedResultSet::getMetaData()");
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getStatement() -I- */
const Statement *
MySQL_ConstructedResultSet::getStatement()
{
	checkValid();
	return NULL; /* This is a constructed result set - no statement -> NULL */
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getString() -I- */
std::string
MySQL_ConstructedResultSet::getString(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ConstructedResultSet::getString: invalid value of 'columnIndex'");
	}

	StringList::iterator f = current_record;

	while (columnIndex--) {
		f++;
	}

	return *f;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::getString() -I- */
std::string
MySQL_ConstructedResultSet::getString(const std::string& columnLabel)
{
	return getString(findColumn(columnLabel));
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::isAfterLast() -I- */
bool
MySQL_ConstructedResultSet::isAfterLast()
{
	checkValid();
	return (row_position == num_rows + 1);
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::isBeforeFirst() -I- */
bool
MySQL_ConstructedResultSet::isBeforeFirst()
{
	checkValid();
	return (row_position == 0);
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::isClosed() -I- */
bool
MySQL_ConstructedResultSet::isClosed()
{
	return is_closed;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::isFirst() -I- */
bool
MySQL_ConstructedResultSet::isFirst()
{
	checkValid();
	/* OR current_record == rs.begin() */
	return (row_position == 1);
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::isLast() -I- */
bool
MySQL_ConstructedResultSet::isLast()
{
	checkValid();
	/* OR current_record == rs.end() */
	return (row_position == num_rows);
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::isNull() -I- */
bool
MySQL_ConstructedResultSet::isNull(int columnIndex) 
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ConstructedResultSet::isNull: invalid value of 'columnIndex'");
	}
	return false;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::isNull() -I- */
bool
MySQL_ConstructedResultSet::isNull(const std::string& columnLabel)
{
	return isNull(findColumn(columnLabel));
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::last() -I- */
bool
MySQL_ConstructedResultSet::last()
{
	checkValid();
	if (num_rows) {
		row_position = num_rows;
		seek();
	}
	return num_rows? true:false;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::next() -I- */
bool
MySQL_ConstructedResultSet::next()
{
	bool ret = false;
	checkValid();
	if (row_position == num_rows) {
		row_position++;
		return false;
	}
	if (row_position < num_rows + 1) {
		int i = num_fields;
		while (i--) {
			current_record++;
		}
		row_position++;
		ret = true;
	}
	return ret;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::previous() -I- */
bool
MySQL_ConstructedResultSet::previous() 
{
	checkValid();
	if (row_position == 0) {
		return false;
	} else if (row_position == 1) {
		beforeFirst();
		return false;
	} else if (row_position > 1) {
		row_position--;
		int i = num_fields;
		while (i--) {
			current_record--;
		}
		return true;
	}
	throw new sql::DbcException(CPPCONN_FUNC, __LINE__, "Impossible");
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::relative() -I- */
bool
MySQL_ConstructedResultSet::relative(int rows)
{
	checkValid();
	throw new sql::DbcMethodNotImplemented("MySQL_ConstructedResultSet::rowInserted()");
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::rowsCount() -I- */
size_t
MySQL_ConstructedResultSet::rowsCount()
{
	checkValid();
	return rs.size() / num_fields;
}
/* }}} */


/* {{{ MySQL_ConstructedResultSet::wasNull() -I- */
bool
MySQL_ConstructedResultSet::wasNull()
{
	checkValid();
	return false;
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
