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

#include "mysql_resultset.h"
#include "mysql_resultset_metadata.h"
#include "mysql_statement.h"
#include "mysql_res_wrapper.h"

#ifndef _WIN32
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


/* {{{ MySQL_ResultSet::MySQL_ResultSet() -I- */
MySQL_ResultSet::MySQL_ResultSet(MYSQL_RES_Wrapper * res, MySQL_Statement * par) 
	: row(NULL), result(res), row_position(0), was_null(false), parent(par)
{
	num_rows = mysql_num_rows(result->get());

	num_fields = mysql_num_fields(result->get());
	for (int i = 0; i < num_fields; i++) {
		char *tmp = cppmysql_utf8_strup(mysql_fetch_field_direct(result->get(), i)->name, 0);
		field_name_to_index_map[std::string(tmp)] = i;
		free(tmp);
	}
}
/* }}} */


/* {{{ MySQL_ResultSet::~MySQL_ResultSet() -I- */
MySQL_ResultSet::~MySQL_ResultSet()
{
	result->dispose();
	result->deleteReference();
}
/* }}} */


/* {{{ MySQL_ResultSet::absolute() -I- */
bool
MySQL_ResultSet::absolute(int row)
{
	checkValid();
	if (row > 0) {
		if (row > (int) num_rows) {
			row_position = num_rows + 1; /* after last row */
		} else {
			row_position = (my_ulonglong) row; /* the cast is inspected and is valid */
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
		mysql_data_seek(result->get(), 0);
	}
	return (row_position > 0 && row_position < (num_rows + 1));
}
/* }}} */


/* {{{ MySQL_ResultSet::afterLast() -I- */
void
MySQL_ResultSet::afterLast()
{
	checkValid();
	row_position = num_rows + 1;
}
/* }}} */


/* {{{ MySQL_ResultSet::beforeFirst() -I- */
void
MySQL_ResultSet::beforeFirst()
{
	checkValid();
	mysql_data_seek(result->get(), 0);
	row_position = 0;
}
/* }}} */


/* {{{ MySQL_ResultSet::checkValid() -I- */
void
MySQL_ResultSet::checkValid()
{
	if (isClosed()) {
		throw new MySQL_DbcException(0, "Statement has been closed");
	}
}
/* }}} */


/* {{{ MySQL_ResultSet::close() -I- */
void
MySQL_ResultSet::close()
{
	checkValid();
	result->dispose();
}
/* }}} */


/* {{{ MySQL_ResultSet::findColumn() -I- */
int
MySQL_ResultSet::findColumn(const std::string& columnLabel)
{
	checkValid();
	char *tmp = cppmysql_utf8_strup(columnLabel.c_str(), 0);
	FieldNameIndexMap::const_iterator iter = field_name_to_index_map.find(tmp);
	free(tmp);

	if(iter == field_name_to_index_map.end()) {
		return -1;
	}
	/* findColumn returns 1-based indexes */
	return iter->second + 1;
}
/* }}} */


/* {{{ MySQL_ResultSet::first() -I- */
bool
MySQL_ResultSet::first()
{
	checkValid();
	if (num_rows) {
		row_position = 1;
		seek();
	}
	return (bool) num_rows;
}
/* }}} */


/* {{{ MySQL_ResultSet::getBoolean() -I- */
bool
MySQL_ResultSet::getBoolean(int columnIndex)
{
	checkValid();
	return getInt(columnIndex);
}
/* }}} */


/* {{{ MySQL_ResultSet::getBoolean() -I- */
bool
MySQL_ResultSet::getBoolean(const std::string& columnLabel)
{
	checkValid();
	return getInt(columnLabel);
}
/* }}} */


/* {{{ MySQL_ResultSet::getDouble() -I- */
double
MySQL_ResultSet::getDouble(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getDouble: invalid value of 'columnIndex'");
	}

	if (row[columnIndex] == NULL) {
		was_null = true;
		return 0.0;
	}
	was_null = false;
	return atof(row[columnIndex]);
}
/* }}} */


/* {{{ MySQL_ResultSet::getDouble() -I- */
double
MySQL_ResultSet::getDouble(const std::string& columnLabel)
{
	checkValid();
	int col_idx = findColumn(columnLabel);
	if (col_idx == -1) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getDouble: invalid value of 'columnLabel'");
	}
	return getDouble(col_idx);
}
/* }}} */


/* {{{ MySQL_ResultSet::getInt() -I- */
int
MySQL_ResultSet::getInt(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getInt: invalid value of 'columnIndex'");
	}
	if (row[columnIndex] == NULL) {
		was_null = true;
		return 0;
	}
	was_null = false;
	return atoi(row[columnIndex]);
}
/* }}} */


/* {{{ MySQL_ResultSet::getInt() -I- */
int
MySQL_ResultSet::getInt(const std::string& columnLabel)
{
	checkValid();
	int col_idx = findColumn(columnLabel);
	if (col_idx == -1) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getInt: invalid value of 'columnLabel'");
	}
	return getInt(col_idx);
}
/* }}} */


/* {{{ MySQL_ResultSet::getLong() -I- */
long long
MySQL_ResultSet::getLong(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getLong: invalid value of 'columnIndex'");
	}

	if (row[columnIndex] == NULL) {
		was_null = true;
		return 0;
	}
	was_null = false;
	return atoll(row[columnIndex]);
}
/* }}} */


/* {{{ MySQL_ResultSet::getLong() -I- */
long long
MySQL_ResultSet::getLong(const std::string& columnLabel)
{
	checkValid();
	int col_idx = findColumn(columnLabel);
	if (col_idx == -1) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getLong: invalid value of 'columnLabel'");
	}
	return getLong(col_idx);
}
/* }}} */


/* {{{ MySQL_ResultSet::getMetaData() -I- */
const sql::ResultSetMetaData * 
MySQL_ResultSet::getMetaData()
{
	checkValid();
	return new MySQL_ResultSetMetaData(result->getReference());
}
/* }}} */


/* {{{ MySQL_ResultSet::getStatement() -I- */
const sql::Statement *
MySQL_ResultSet::getStatement()
{
	return parent;
}
/* }}} */


/* {{{ MySQL_ResultSet::getString() -I- */
std::string
MySQL_ResultSet::getString(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if (columnIndex >= num_fields || columnIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getString: invalid value of 'columnIndex'");
	}

	if(row[columnIndex] == NULL) {
		was_null= true;
		return "";
	}
	was_null= false;
	return row[columnIndex];
}
/* }}} */


/* {{{ MySQL_ResultSet::getString() -I- */
std::string
MySQL_ResultSet::getString(const std::string& columnLabel)
{
	checkValid();
	int col_idx = findColumn(columnLabel);
	if (col_idx == -1) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::getString: invalid value of 'columnLabel'");
	}
	return getString(col_idx);
}
/* }}} */


/* {{{ MySQL_ResultSet::isAfterLast() -I- */
bool
MySQL_ResultSet::isAfterLast()
{
	checkValid();
	return (row_position == num_rows + 1);
}
/* }}} */


/* {{{ MySQL_ResultSet::isBeforeFirst() -I- */
bool
MySQL_ResultSet::isBeforeFirst()
{
	checkValid();
	return (row_position == 0);
}
/* }}} */


/* {{{ MySQL_ResultSet::isClosed() -I- */
bool
MySQL_ResultSet::isClosed()
{
	return !result->isValid();
}
/* }}} */


/* {{{ MySQL_ResultSet::isFirst() -I- */
bool
MySQL_ResultSet::isFirst()
{
	checkValid();
	return (row_position == 1);
}
/* }}} */


/* {{{ MySQL_ResultSet::isLast() -I- */
bool
MySQL_ResultSet::isLast()
{
	checkValid();
	return (row_position == num_rows);
}
/* }}} */


/* {{{ MySQL_ResultSet::isNull() -I- */
bool
MySQL_ResultSet::isNull(int columnIndex)
{
	checkValid();
	/* internally zero based */
	columnIndex--;
	if(columnIndex >= num_fields || columnIndex < 0) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::isNull: invalid value of 'columnIndex'");
	}
	return (row[columnIndex] == NULL);
}
/* }}} */


/* {{{ MySQL_ResultSet::isNull() -I- */
bool
MySQL_ResultSet::isNull(const std::string& columnLabel)
{
	checkValid();
	int col_idx = findColumn(columnLabel);
	if (col_idx == -1) {
		throw new DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQL_ResultSet::isNull: invalid value of 'columnLabel'");
	}
	return isNull(col_idx);
}
/* }}} */


/* {{{ MySQL_ResultSet::last() -I- */
bool
MySQL_ResultSet::last()
{
	checkValid();
	if (num_rows) {
		row_position = num_rows;
		seek();
	}
	return (bool) num_rows;
}
/* }}} */


/* {{{ MySQL_ResultSet::next() -I- */
bool
MySQL_ResultSet::next()
{
	bool ret = false;
	checkValid();
	if (row_position == num_rows) {
		row_position++;
		return false;
	}
	if (row_position < num_rows + 1) {
		row = mysql_fetch_row(result->get());
		row_position++;
		ret = (bool) row;
	}
	return ret;
}
/* }}} */


/* {{{ MySQL_ResultSet::previous() -I- */
bool
MySQL_ResultSet::previous()
{
	checkValid();
	if (row_position == 0) {
		return false;
	} else if (row_position == 1) {
		mysql_data_seek(result->get(), 0);
		return false;
	} else if (row_position > 1) {
		row_position--;
		seek();
		return true;
	}
	throw new sql::DbcException(CPPCONN_FUNC, __LINE__, "Impossible");
}
/* }}} */


/* {{{ MySQL_ResultSet::relative() -I- */
bool
MySQL_ResultSet::relative(int rows)
{
	checkValid();
	if (rows != 0) {
		if ((row_position + rows) > num_rows || (row_position + rows) < 1) {
			row_position = rows > 0? num_rows + 1 : 0; /* after last or before first */
		} else {
			row_position += rows;
			seek();
		}
	}

	return (row_position < (num_rows + 1) || row_position > 0);
}
/* }}} */


/* {{{ MySQL_ResultSet::rowsCount() -I- */
size_t
MySQL_ResultSet::rowsCount()
{
	checkValid();
	return (size_t) mysql_num_rows(result->get());
}
/* }}} */


/* {{{ MySQL_ResultSet::wasNull() -I- */
bool
MySQL_ResultSet::wasNull() 
{
	checkValid();
	return was_null; 
}
/* }}} */


/* {{{ MySQL_ResultSet::seek() -I- */
void
MySQL_ResultSet::seek()
{
	mysql_data_seek(result->get(), row_position - 1);
	row = mysql_fetch_row(result->get());
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
