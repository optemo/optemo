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

#ifndef _RESULTSET_METADATA_H_
#define _RESULTSET_METADATA_H_

#include <string>


namespace sql
{

class ResultSetMetaData 
{
public:
	enum
	{
		columnNoNulls,
		columnNullable,
		columnNullableUnknown
	};

	virtual std::string getCatalogName(int column) const = 0;

	virtual int getColumnCount() const = 0;

	virtual std::string getColumnLabel(int column) const = 0;

	virtual std::string getColumnName(int column) const = 0;

	virtual int getColumnType(int column) const = 0;

	virtual std::string getColumnTypeName(int column) const = 0;

	virtual std::string getSchemaName(int column) const = 0;

	virtual std::string getTableName(int column) const = 0;

	virtual bool isAutoIncrement(int column) const = 0;

	virtual bool isCaseSensitive(int column) const = 0;

	virtual bool isCurrency(int column) const = 0;

	virtual bool isDefinitelyWritable(int column) const = 0;

	virtual int isNullable(int column) const = 0;

	virtual bool isReadOnly(int column) const = 0;

	virtual bool isSearchable(int column) const = 0;

	virtual bool isSigned(int column) const = 0;

	virtual bool isWritable(int column) const = 0;

	virtual ~ResultSetMetaData() {}
};


}; /* namespace sql */

#endif // _RESULTSET_METADATA_H_
