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

#ifndef _MYSQL_RESULTSET_METADATA_H_
#define _MYSQL_RESULTSET_METADATA_H_

#include "dbciface/resultset_metadata.h"
#include "mysql_res_wrapper.h"

namespace sql
{
namespace mysql
{

class MySQL_ResultSetMetaData : public sql::ResultSetMetaData
{
	MYSQL_RES_Wrapper * result;
public:
	MySQL_ResultSetMetaData(MYSQL_RES_Wrapper * res) : result(res) {}
	virtual ~MySQL_ResultSetMetaData() { result->deleteReference(); }

	std::string getCatalogName(int columnIndex) const;

	int getColumnCount() const;

	int getColumnDisplaySize(int columnIndex) const;

	std::string getColumnLabel(int columnIndex) const;

	std::string getColumnName(int columnIndex) const;

	int getColumnType(int columnIndex) const;

	std::string getColumnTypeName(int columnIndex) const;

	int getPrecision(int columnIndex) const;

	int getScale(int columnIndex) const;

	std::string getSchemaName(int columnIndex) const;

	std::string getTableName(int columnIndex) const;

	bool isAutoIncrement(int columnIndex) const;

	bool isCaseSensitive(int columnIndex) const;

	bool isCurrency(int columnIndex) const;

	bool isDefinitelyWritable(int columnIndex) const;

	int isNullable(int columnIndex) const;

	bool isReadOnly(int columnIndex) const;

	bool isSearchable(int columnIndex) const;

	bool isSigned(int columnIndex) const;

	bool isWritable(int columnIndex) const;
};

}; /* namespace mysql */
}; /* namespace sql */

#endif // _MYSQL_RESULTSET_METADATA_H_
/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
