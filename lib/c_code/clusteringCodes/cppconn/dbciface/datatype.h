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

#ifndef _DATATYPE_H_
#define _DATATYPE_H_

namespace sql
{

class DataType
{
	DataType();
public:
	static const int BIT = -7;
	static const int TINYINT = -6;
	static const int SMALLINT = 5;
	static const int INTEGER = 4;
	static const int BIGINT = -5;
	static const int FLOAT = 6;
	static const int REAL = 7;
	static const int DOUBLE = 8;
	static const int NUMERIC = 2;
	static const int DECIMAL = 3;
	static const int CHAR = 1;
	static const int VARCHAR = 12;
	static const int LONGVARCHAR = -1;
	static const int DATE = 91;
	static const int TIME = 92;
	static const int TIMESTAMP = 93;
	static const int BINARY = -2;
	static const int VARBINARY = -3;
	static const int LONGVARBINARY = -4;
	static const int SQLNULL = 0;
	static const int OTHER = 1111;
	static const int OBJECT = 2000;
	static const int DISTINCT = 2001;
	static const int STRUCT = 2002;
	static const int ARRAY = 2003;
	static const int BLOB = 2004;
	static const int CLOB = 2005;
	static const int REF = 2006;
	static const int BOOLEAN = 16;
};

}; /* namespace */

#endif
