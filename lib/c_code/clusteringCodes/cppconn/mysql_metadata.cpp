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
#include "mysql_metadata.h"
#include "mysql_constructed_resultset.h"
#include "mysql_statement.h"
#include "mysql_prepared_statement.h"
#include "dbciface/datatype.h"

#if defined(_WIN32) || defined(_WIN64)
#define snprintf _snprintf
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

struct TypeInfoDef {
	const char *typeName;
	int dataType;
	int precision;
	const char *literalPrefix;
	const char *literalSuffix;
	const char *createParams;
	short nullable;
	bool caseSensitive;
	short searchable;
	bool isUnsigned;
	bool fixedPrecScale;
	bool autoIncrement;
	const char *localTypeName;
	int minScale;
	int maxScale;
	int sqlDataType;
	int sqlDateTimeSub;
	int numPrecRadix;
};

TypeInfoDef mysqlc_types[] = {

	// ------------- MySQL-Type: BIT. SDBC-Type: Bit -------------
	{
		"BIT",								// Typename
		DataType::BIT,						// sdbc-type
		1,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"BIT",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ------------ MySQL-Type: BOOL. SDBC-Type: Bit -------------
	{
		"BOOL",								// Typename
		DataType::BIT,						// sdbc-type
		1,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"BOOL",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// --------- MySQL-Type: TINYINT SDBC-Type: TINYINT ----------
	{
		"TINYINT",							// Typename
		DataType::TINYINT,					// sdbc-type
		3,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M)] [UNSIGNED] [ZEROFILL]",		// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		true,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"TINYINT",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: BIGINT SDBC-Type: BIGINT ----------
	{
		"BIGINT",							// Typename
		DataType::BIGINT,					// sdbc-type
		19,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M)] [UNSIGNED] [ZEROFILL]",		// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		true,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"BIGINT",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: LONG VARBINARY SDBC-Type: LONGVARBINARY ----------
	{
		"LONG VARBINARY",					// Typename
		DataType::LONGVARBINARY,			// sdbc-type
		16777215,							// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		true,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"LONG VARBINARY",					// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: MEDIUMBLOB SDBC-Type: LONGVARBINARY ----------
	{
		"MEDIUMBLOB",						// Typename
		DataType::LONGVARBINARY,			// sdbc-type
		16777215,							// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		true,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"MEDIUMBLOB",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: LONGBLOB SDBC-Type: LONGVARBINARY ----------
	{
		"LONGBLOB",							// Typename
		DataType::LONGVARBINARY,			// sdbc-type
		0xFFFFFFFF,							// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		true,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"LONGBLOB",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: BLOB SDBC-Type: LONGVARBINARY ----------
	{
		"BLOB",								// Typename
		DataType::LONGVARBINARY,			// sdbc-type
		0xFFFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		true,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"BLOB",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: TINYBLOB SDBC-Type: LONGVARBINARY ----------
	{
		"TINYBLOB",							// Typename
		DataType::LONGVARBINARY,			// sdbc-type
		0xFFFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		true,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"TINYBLOB",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: VARBINARY SDBC-Type: VARBINARY ----------
	{
		"VARBINARY",						// Typename
		DataType::VARBINARY,				// sdbc-type
		0xFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"(M)",								// Create params
		DatabaseMetaData::typeNullable,		// nullable
		true,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"VARBINARY",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: BINARY SDBC-Type: BINARY ----------
	{
		"BINARY",							// Typename
		DataType::BINARY,					// sdbc-type
		0xFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"(M)",								// Create params
		DatabaseMetaData::typeNullable,		// nullable
		true,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"VARBINARY",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: LONG VARCHAR SDBC-Type: LONG VARCHAR ----------
	{
		"LONG VARCHAR",						// Typename
		DataType::LONGVARCHAR,				// sdbc-type
		0xFFFFFF,							// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"LONG VARCHAR",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: MEDIUMTEXT SDBC-Type: LONG VARCHAR ----------
	{
		"MEDIUMTEXT",						// Typename
		DataType::LONGVARCHAR,				// sdbc-type
		0xFFFFFF,							// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"MEDIUMTEXT",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: MEDIUMTEXT SDBC-Type: LONG VARCHAR ----------
	{
		"MEDIUMTEXT",						// Typename
		DataType::LONGVARCHAR,				// sdbc-type
		0xFFFFFF,							// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"MEDIUMTEXT",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: LONGTEXT SDBC-Type: LONG VARCHAR ----------
	{
		"LONGTEXT",							// Typename
		DataType::LONGVARCHAR,				// sdbc-type
		0xFFFFFF,							// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"LONGTEXT",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: TEXT SDBC-Type: LONG VARCHAR ----------
	{
		"TEXT",								// Typename
		DataType::LONGVARCHAR,				// sdbc-type
		0xFFFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"TEXT",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: TINYTEXT SDBC-Type: LONG VARCHAR ----------
	{
		"TINYTEXT",							// Typename
		DataType::LONGVARCHAR,				// sdbc-type
		0xFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"TINYTEXT",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: CHAR SDBC-Type: CHAR ----------
	{
		"CHAR",								// Typename
		DataType::CHAR,						// sdbc-type
		0xFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"(M)",								// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"NUMERIC",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: DECIMAL SDBC-Type: DECIMAL ----------
	{
		"DECIMAL",							// Typename
		DataType::NUMERIC,					// sdbc-type
		17,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M[,D])] [ZEROFILL]",				// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"DECIMAL",							// local type name
		-308,								// minimum scale
		308,								// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: NUMERIC SDBC-Type: NUMERIC ----------
	{
		"NUMERIC",							// Typename
		DataType::NUMERIC,					// sdbc-type
		17,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M[,D])] [ZEROFILL]",				// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"NUMERIC",							// local type name
		-308,								// minimum scale
		308,								// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: INTEGER SDBC-Type: INTEGER ----------
	{
		"INTEGER",							// Typename
		DataType::NUMERIC,					// sdbc-type
		10,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M)] [UNSIGNED] [ZEROFILL]",		// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		true,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"INTEGER",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: INT SDBC-Type: INTEGER ----------
	{
		"INT",								// Typename
		DataType::INTEGER,					// sdbc-type
		10,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M)] [UNSIGNED] [ZEROFILL]",		// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		true,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"INT",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: MEDIUMINT SDBC-Type: INTEGER ----------
	{
		"MEDIUMINT",						// Typename
		DataType::INTEGER,					// sdbc-type
		7,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M)] [UNSIGNED] [ZEROFILL]",		// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		true,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"MEDIUMINT",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: SMALLINT SDBC-Type: INTEGER ----------
	{
		"SMALLINT",							// Typename
		DataType::INTEGER,					// sdbc-type
		5,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M)] [UNSIGNED] [ZEROFILL]",		// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		true,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"SMALLINT",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: FLOAT SDBC-Type: REAL ----------
	{
		"FLOAT",							// Typename
		DataType::REAL,						// sdbc-type
		10,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M,D)] [ZEROFILL]",				// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"FLOAT",							// local type name
		-38,								// minimum scale
		38,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: DOUBLE SDBC-Type: DOUBLE ----------
	{
		"DOUBLE",							// Typename
		DataType::DOUBLE,					// sdbc-type
		17,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M,D)] [ZEROFILL]",				// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"DOUBLE",							// local type name
		-308,								// minimum scale
		308,								// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: DOUBLE PRECISION SDBC-Type: DOUBLE ----------
	{
		"DOUBLE PRECISION",					// Typename
		DataType::DOUBLE,					// sdbc-type
		17,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M,D)] [ZEROFILL]",				// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"DOUBLE PRECISION",					// local type name
		-308,								// minimum scale
		308,								// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: REAL SDBC-Type: DOUBLE ----------
	{
		"REAL",								// Typename
		DataType::DOUBLE,					// sdbc-type
		17,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"[(M,D)] [ZEROFILL]",				// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		true,								// auto_increment
		"REAL",								// local type name
		-308,								// minimum scale
		308,								// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: VARCHAR SDBC-Type: VARCHAR ----------
	{
		"VARCHAR",							// Typename
		DataType::VARCHAR,					// sdbc-type
		255,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"(M)",								// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"VARCHAR",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: ENUM SDBC-Type: VARCHAR ----------
	{
		"ENUM",								// Typename
		DataType::VARCHAR,					// sdbc-type
		0xFFFF,								// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"ENUM",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: SET SDBC-Type: VARCHAR ----------
	{
		"SET",								// Typename
		DataType::VARCHAR,					// sdbc-type
		64,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"SET",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: DATE SDBC-Type: DATE ----------
	{
		"DATE",								// Typename
		DataType::DATE,						// sdbc-type
		0,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"DATE",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: TIME SDBC-Type: TIME ----------
	{
		"TIME",								// Typename
		DataType::TIME,						// sdbc-type
		0,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"TIME",								// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: DATETIME SDBC-Type: TIMESTAMP ----------
	{
		"DATETIME",							// Typename
		DataType::TIMESTAMP,				// sdbc-type
		0,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"DATETIME",							// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: TIMESTAMP SDBC-Type: TIMESTAMP ----------
	{
		"TIMESTAMP",						// Typename
		DataType::TIMESTAMP,				// sdbc-type
		0,									// Precision
		"",									// Literal prefix
		"",									// Literal suffix
		"",									// Create params
		DatabaseMetaData::typeNullable,		// nullable
		false,								// case sensitive
		DatabaseMetaData::typeSearchable,	// searchable
		false,								// unsignable
		false,								// fixed_prec_scale
		false,								// auto_increment
		"TIMESTAMP",						// local type name
		0,									// minimum scale
		0,									// maximum scale
		0,									// sql data type (unsued)
		0,									// sql datetime sub (unsued)
		10									// num prec radix
	},

	// ----------- MySQL-Type: TIMESTAMP SDBC-Type: TIMESTAMP ----------
	{
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	}
};


/* {{{ my_i_to_a() -I- */
static inline char * my_i_to_a(char * buf, size_t buf_size, int a)
{
	snprintf(buf, buf_size, "%d", a);
	return buf;
}
/* }}} */



/* {{{ MySQL_ConnectionMetaData::MySQL_ConnectionMetaData() -I- */
MySQL_ConnectionMetaData::MySQL_ConnectionMetaData(MySQL_Connection *conn)
: connection(conn) 
{
	server_version = mysql_get_server_version(connection->getMySQLHandle());
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::~MySQL_ConnectionMetaData() -I- */
MySQL_ConnectionMetaData::~MySQL_ConnectionMetaData()
{

}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSchemata() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getSchemata(const std::string& catalogName) const
{
	std::auto_ptr<sql::Statement> stmt(connection->createStatement());
	return stmt->executeQuery("SELECT * FROM information_schema.schemata");
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSchemaObjects() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getSchemaObjects(const std::string& catalogName, 
								const std::string& schemaName,
								const std::string& objectType) const
{
	// for now catalog name is ignored

	std::string query;

	std::string tables_where_clause;
	std::string views_where_clause;
	std::string routines_where_clause;
	std::string triggers_where_clause;

	static const std::string tables_select_items("'table' AS 'OBJECT_TYPE', TABLE_CATALOG as 'CATALOG', TABLE_SCHEMA as 'SCHEMA', TABLE_NAME as 'NAME'");
	static const std::string views_select_items("'view' AS 'OBJECT_TYPE', TABLE_CATALOG as 'CATALOG', TABLE_SCHEMA as 'SCHEMA', TABLE_NAME as 'NAME'");
	static const std::string routines_select_items("ROUTINE_TYPE AS 'OBJECT_TYPE', ROUTINE_CATALOG as 'CATALOG', ROUTINE_SCHEMA as 'SCHEMA', ROUTINE_NAME as 'NAME'");
	static const std::string triggers_select_items("'trigger' AS 'OBJECT_TYPE', TRIGGER_CATALOG as 'CATALOG', TRIGGER_SCHEMA as 'SCHEMA', TRIGGER_NAME as 'NAME'");

	static const std::string table_ddl_column("Create Table");
	static const std::string view_ddl_column("Create View");
	static const std::string procedure_ddl_column("Create Procedure");
	static const std::string function_ddl_column("Create Function");
	static const std::string trigger_ddl_column("SQL Original sql::Statement");

	if(schemaName.length() > 0) {
		tables_where_clause.append(" WHERE table_type<>'VIEW' AND table_schema = '").append(schemaName).append("' ");
		views_where_clause.append(" WHERE table_schema = '").append(schemaName).append("' ");
		routines_where_clause.append(" WHERE routine_schema = '").append(schemaName).append("' ");
		triggers_where_clause.append(" WHERE trigger_schema = '").append(schemaName).append("' ");
	}

	if(objectType.length() == 0) {
		query
			.append("SELECT ").append(tables_select_items)
			.append(" FROM information_schema.tables ").append(tables_where_clause)
			.append("UNION SELECT ").append(views_select_items)
			.append(" FROM information_schema.views ").append(views_where_clause)
			.append("UNION SELECT ").append(routines_select_items)
			.append(" FROM information_schema.routines ").append(routines_where_clause)
			.append("UNION SELECT ").append(triggers_select_items)
			.append(" FROM information_schema.triggers ").append(triggers_where_clause)
			;
	} else {
		if(objectType.compare("table") == 0) {
			query.append("SELECT ")
				.append(tables_select_items)
				.append(" FROM information_schema.tables")
				.append(tables_where_clause);
		} else if(objectType.compare("view") == 0) {
			query.append("SELECT ")
				.append(views_select_items)
				.append(" FROM information_schema.views")
				.append(views_where_clause);
		} else if(objectType.compare("routine") == 0) {
			query.append("SELECT ")
				.append(routines_select_items)
				.append(" FROM information_schema.routines")
				.append(routines_where_clause);
		} else if(objectType.compare("trigger") == 0) {
			query.append("SELECT ")
				.append(triggers_select_items)
				.append(" FROM information_schema.triggers")
				.append(triggers_where_clause);
		} else {
			throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQLMetadata::getSchemaObjects: invalid 'objectType'");
		}
	}
	// XXX:

	std::auto_ptr<sql::ResultSet> native_rs(std::auto_ptr<sql::Statement>(new MySQL_Statement(connection))->executeQuery(query));

	int objtype_field_index = native_rs->findColumn("OBJECT_TYPE");
	int catalog_field_index = native_rs->findColumn("CATALOG");
	int schema_field_index = native_rs->findColumn("SCHEMA");
	int name_field_index = native_rs->findColumn("NAME");

	std::list<std::string> rs_data;

	std::map<std::string, std::string> trigger_ddl_map;

	// if we fetch triggers, then build DDL for them
	if((objectType.compare("trigger") == 0) || objectType.empty()) {
		std::string trigger_ddl_query("SELECT ");
		trigger_ddl_query
			.append(triggers_select_items)
			.append(", EVENT_MANIPULATION, EVENT_OBJECT_SCHEMA, EVENT_OBJECT_TABLE, ACTION_ORDER, "
							"	ACTION_CONDITION, ACTION_STATEMENT, ACTION_ORIENTATION, ACTION_TIMING, DEFINER"
							"	FROM information_schema.triggers ")
			.append(triggers_where_clause);

		std::auto_ptr<sql::ResultSet> trigger_ddl_rs(std::auto_ptr<sql::Statement>(
			new MySQL_Statement(connection))->executeQuery(trigger_ddl_query));

		// trigger specific fields: exclusion from the rule - 'show create trigger' is not supported by verions below 5.1.21
		// reproducing ddl based on metadata
		int event_manipulation_index	= trigger_ddl_rs->findColumn("EVENT_MANIPULATION");
		int event_object_schema_index	= trigger_ddl_rs->findColumn("EVENT_OBJECT_SCHEMA");
		int event_object_table_index	= trigger_ddl_rs->findColumn("EVENT_OBJECT_TABLE");
		int action_statement_index		= trigger_ddl_rs->findColumn("ACTION_STATEMENT");
		int action_timing_index 		= trigger_ddl_rs->findColumn("ACTION_TIMING");
		int definer_index				= trigger_ddl_rs->findColumn("DEFINER");

		while (trigger_ddl_rs->next()) {
			std::string trigger_ddl;

			trigger_ddl
				.append("CREATE\nDEFINER=").append(trigger_ddl_rs->getString(definer_index)).append("\nTRIGGER ").append("`")
				.append(trigger_ddl_rs->getString("schema")).append("`.`").append(trigger_ddl_rs->getString("name")).append("`")
				.append("\n").append(trigger_ddl_rs->getString(action_timing_index))
				.append(" ").append(trigger_ddl_rs->getString(event_manipulation_index))
				.append(" ON `").append(trigger_ddl_rs->getString(event_object_schema_index))
				.append("`.`").append(trigger_ddl_rs->getString(event_object_table_index)).append("`")
				.append("\nFOR EACH ROW\n").append(trigger_ddl_rs->getString(action_statement_index)).append("\n");

			std::string key;

			key.append("`").append(trigger_ddl_rs->getString("schema")).append("`.`").append(trigger_ddl_rs->getString("name")).append("`");

			trigger_ddl_map[key] = trigger_ddl;
		}
	}

	while (native_rs->next()) {
		std::string obj_type(native_rs->getString(objtype_field_index));
		std::string schema(native_rs->getString(schema_field_index));
		std::string name(native_rs->getString(name_field_index));

		if ((obj_type.compare("PROCEDURE") == 0) || (obj_type.compare("FUNCTION") == 0)) {
			rs_data.push_back("routine");
		} else {
			rs_data.push_back(obj_type);
		}
		rs_data.push_back(native_rs->getString(catalog_field_index));
		rs_data.push_back(schema);
		rs_data.push_back(name);

		std::string ddl_query;
		std::string ddl_column;

		if (obj_type.compare("table") == 0) {
			ddl_column = table_ddl_column;
			ddl_query.append("SHOW CREATE TABLE `").append(schema).append("`.`").append(name).append("`");
		} else if(obj_type.compare("view") == 0) {
			ddl_column = view_ddl_column;
			ddl_query.append("SHOW CREATE VIEW `").append(schema).append("`.`").append(name).append("`");
		} else if(obj_type.compare("PROCEDURE") == 0) {
			ddl_column = procedure_ddl_column;
			ddl_query.append("SHOW CREATE PROCEDURE `").append(schema).append("`.`").append(name).append("`");
		} else if(obj_type.compare("FUNCTION") == 0) {
			ddl_column = function_ddl_column;
			ddl_query.append("SHOW CREATE FUNCTION `").append(schema).append("`.`").append(name).append("`");
		} else if(obj_type.compare("trigger") == 0) {
		/*
			ddl_column = trigger_ddl_column;
			ddl_query.append("SHOW CREATE TRIGGER `").append(schema).append("`.`").append(name).append("`");
		*/	
		} else {
			throw new sql::DbcInvalidArgument(CPPCONN_FUNC, __LINE__, "MySQLMetadata::getSchemaObjects: invalid OBJECT_TYPE returned from query");
		}

		// due to bugs in server code some queries can fail. 
		// here we want to gather as much info as possible
		try	{
			std::string ddl;

			if (obj_type.compare("trigger") == 0) {
				std::string key;
				key.append("`").append(schema).append("`.`").append(name).append("`");

				std::map<std::string, std::string>::const_iterator it = trigger_ddl_map.find(key);
				if (it != trigger_ddl_map.end()) {
					ddl.append(it->second);
				}
			} else {
				std::auto_ptr<sql::ResultSet> sql_rs(std::auto_ptr<sql::Statement>(new MySQL_Statement(connection))->executeQuery(ddl_query));

				sql_rs->next();

				// this is a hack for views listed as tables
				int colIdx = sql_rs->findColumn(ddl_column);
				if ((colIdx == -1) && (obj_type.compare("table") == 0)) {
					colIdx = sql_rs->findColumn(view_ddl_column);
				}

				ddl = sql_rs->getString(colIdx);
			}
			rs_data.push_back(ddl);
		} catch (DbcException *e) {
			rs_data.push_back("");
			delete e;
		}
	}

	std::list<std::string> rs_field_data;
	rs_field_data.push_back("OBJECT_TYPE");
	rs_field_data.push_back("CATALOG");
	rs_field_data.push_back("SCHEMA");
	rs_field_data.push_back("NAME");
	rs_field_data.push_back("DDL");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}	
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSchemaObjectTypes() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getSchemaObjectTypes() const
{
	std::list<std::string> rs_data;
	rs_data.push_back("table");
	rs_data.push_back("view");
	rs_data.push_back("routine");
	rs_data.push_back("trigger");

	std::list<std::string> rs_field_data;
	rs_field_data.push_back("OBJECT_TYPE");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::allProceduresAreCallable() -I- */
bool
MySQL_ConnectionMetaData::allProceduresAreCallable() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::allTablesAreSelectable() -I- */
bool
MySQL_ConnectionMetaData::allTablesAreSelectable() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::dataDefinitionCausesTransactionCommit() -I- */
bool
MySQL_ConnectionMetaData::dataDefinitionCausesTransactionCommit() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::dataDefinitionIgnoredInTransactions() -I- */
bool
MySQL_ConnectionMetaData::dataDefinitionIgnoredInTransactions() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::deletesAreDetected() -I- */
bool
MySQL_ConnectionMetaData::deletesAreDetected(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::doesMaxRowSizeIncludeBlobs() -I- */
bool
MySQL_ConnectionMetaData::doesMaxRowSizeIncludeBlobs() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getAttributes() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getAttributes(std::string& catalog, std::string& schemaPattern,
										std::string& typeNamePattern, std::string& attributeNamePattern) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	rs_field_data.push_back("TABLE_CATALOG");
	rs_field_data.push_back("TYPE_SCHEMA");
	rs_field_data.push_back("TYPE_NAME");
	rs_field_data.push_back("ATTR_NAME");
	rs_field_data.push_back("ATTR_TYPE_NAME");
	rs_field_data.push_back("ATTR_SIZE");
	rs_field_data.push_back("DECIMAL_DIGITS");
	rs_field_data.push_back("NUM_PREC_RADIX");
	rs_field_data.push_back("NULLABLE");
	rs_field_data.push_back("REMARKS");
	rs_field_data.push_back("ATTR_DEF");
	rs_field_data.push_back("SQL_DATA_TYPE");
	rs_field_data.push_back("SQL_DATETIME_SUB");
	rs_field_data.push_back("CHAR_OCTET_LENGTH");
	rs_field_data.push_back("ORDINAL_POSITION");
	rs_field_data.push_back("IS_NULLABLE");
	rs_field_data.push_back("SCOPE_CATALOG");
	rs_field_data.push_back("SCOPE_SCHEMA");
	rs_field_data.push_back("SOURCE_DATA_TYPE");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getBestRowIdentifier() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getBestRowIdentifier(std::string& catalog, std::string& schema,
												std::string& table, int scope, bool nullable) const
{
	char buf[12];
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;
	std::auto_ptr<sql::ResultSet> rs(getPrimaryKeys(catalog, schema, table));
	buf[sizeof(buf) - 1] = '\0';

	while (rs->next()) {
		std::string columnNamePattern(rs->getString(4));

		std::auto_ptr<sql::ResultSet> rsCols(getColumns(catalog, schema, table, columnNamePattern));
		if (rsCols->next()) {
			rs_data.push_back(my_i_to_a(buf, sizeof(buf) - 1, DatabaseMetaData::bestRowSession)); // scope
			rs_data.push_back(rs->getString(4));	// column_name 
			rs_data.push_back(rsCols->getString(5)); // data type
			rs_data.push_back(rsCols->getString(6)); // type name
			rs_data.push_back(rsCols->getString(7)); // column size
			rs_data.push_back(rsCols->getString(8)); // buffer length
			rs_data.push_back(rsCols->getString(9)); // decimal digits
			rs_data.push_back(my_i_to_a(buf, sizeof(buf) - 1, DatabaseMetaData::bestRowNotPseudo));// pseudo column
		}
	}

	rs_field_data.push_back("SCOPE");
	rs_field_data.push_back("COLUMN_NAME");
	rs_field_data.push_back("DATA_TYPE");
	rs_field_data.push_back("TYPE_NAME");
	rs_field_data.push_back("COLUMN_SIZE");
	rs_field_data.push_back("BUFFER_LENGTH");
	rs_field_data.push_back("DECIMAL_DIGITS");
	rs_field_data.push_back("PSEUDO_COLUMN");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getCatalogs() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getCatalogs() const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	std::auto_ptr<sql::Statement> stmt(connection->createStatement());
	std::auto_ptr<sql::ResultSet> rs(
		stmt->executeQuery(server_version > 49999? "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA ORDER BY SCHEMA_NAME":
												   "SHOW DATABASES"));

	while (rs->next()) {
		rs_data.push_back(rs->getString(1));
	}

	rs_field_data.push_back("TABLE_CATALOG");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getCatalogSeparator() -I- */
const std::string& MySQL_ConnectionMetaData::getCatalogSeparator() const
{
	static const std::string separator(".");
	return separator;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getCatalogTerm() -I- */
const std::string& MySQL_ConnectionMetaData::getCatalogTerm() const
{
	static const std::string term("database");
	return term;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getColumns() -U- */
sql::ResultSet *
MySQL_ConnectionMetaData::getColumns(std::string& catalog, std::string& schemaPattern,
										std::string& tableNamePattern, std::string& columnNamePattern) const
{
	throw new sql::DbcMethodNotImplemented("MySQL_ConnectionMetaData::getColumns");
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getConnection() -I- */
Connection *
MySQL_ConnectionMetaData::getConnection() const
{
	return this->connection;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDatabaseMajorVersion() -I- */
int MySQL_ConnectionMetaData::getDatabaseMajorVersion() const
{
	return server_version / 10000;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDatabaseMinorVersion() -I- */
int MySQL_ConnectionMetaData::getDatabaseMinorVersion() const
{
	return server_version % 10000;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDatabaseProductName() -I- */
const std::string& MySQL_ConnectionMetaData::getDatabaseProductName() const
{
	static const std::string product_name("MySQL");
	return product_name;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDatabaseProductVersion() -I- */
const std::string& MySQL_ConnectionMetaData::getDatabaseProductVersion() const
{
	static const std::string product_version("5.1");
	return product_version;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDefaultTransactionIsolation() -I- */
int MySQL_ConnectionMetaData::getDefaultTransactionIsolation() const
{
	if (server_version >= 32336) {
		return TRANSACTION_READ_COMMITTED;
	}
	return TRANSACTION_NONE;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDriverMajorVersion() -I- */
int MySQL_ConnectionMetaData::getDriverMajorVersion() const
{
	return 5;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDriverMinorVersion() -I- */
int MySQL_ConnectionMetaData::getDriverMinorVersion() const
{
	return 1;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDriverName() -I- */
const std::string& MySQL_ConnectionMetaData::getDriverName() const
{
	static const std::string product_version("MySQL CPP Connector");
	return product_version;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getDriverVersion() -I- */
std::string MySQL_ConnectionMetaData::getDriverVersion() const
{
	static const std::string version("5.1.0-alpha");
	return version;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getExtraNameCharacters() -I- */
const std::string& MySQL_ConnectionMetaData::getExtraNameCharacters() const
{
	static const std::string extra("#@");
	return extra;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getIdentifierQuoteString() -I- */
const std::string& MySQL_ConnectionMetaData::getIdentifierQuoteString() const
{
	static const std::string empty(" "), tick("`"), quote("\"");
	
	if (server_version >= 32306) {
		/* Ask the server for sql_mode and decide for a tick or a quote */
		std::string sql_mode(connection->getSessionVariable("SQL_MODE"));

		if (sql_mode.find("ANSI_QUOTES") != std::string::npos) {
			return quote;
		} else {
			return tick;
		}
	}
	return empty;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getImportedKeys() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getImportedKeys(std::string& catalog, std::string& schema, std::string& table) const
{
	throw new sql::DbcMethodNotImplemented("MySQL_ConnectionMetaData::getImportedKeys");
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getIndexInfo() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getIndexInfo(std::string& catalog, std::string& schema,
										std::string& table, bool unique, bool approximate) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;
	static char buf[5];
	static bool buf_init = false;

	if (!buf_init) {
		snprintf(buf, sizeof(buf), "%d", DatabaseMetaData::tableIndexOther);
	}

	if (server_version > 59999) {
		static const std::string query("SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, NON_UNIQUE, " \
						"INDEX_NAME, SEQ_IN_INDEX, COLUMN_NAME, CARDINALITY " \
						"FROM INFORMATION_SCHEMA.STATISTICS WHERE " \
						"TABLE_SCHEMA LIKE ? AND TABLE_NAME LIKE ? " \
						"ORDER BY NON_UNIQUE, INDEX_NAME, SEQ_IN_INDEX");

		std::auto_ptr<sql::PreparedStatement> stmt(connection->prepareStatement(query));

		stmt->setString(1, schema);
		stmt->setString(2, table);

		std::auto_ptr<sql::ResultSet> rs(stmt->executeQuery());


		while (rs->next()) {
			rs_data.push_back(rs->getString(1));	// Catalog
			rs_data.push_back(rs->getString(2));	// Schema 
			rs_data.push_back(rs->getString(3));	// Tablename
			rs_data.push_back(rs->getString(4));	// non unique
			rs_data.push_back("");					// index qualifier
			rs_data.push_back(rs->getString(5));	// index name
			rs_data.push_back(buf);					// index_type
			rs_data.push_back(rs->getString(6));	// ordinal position
			rs_data.push_back(rs->getString(7));	// column name
			rs_data.push_back("ASC");				// asc or desc
			rs_data.push_back(rs->getString(8));	// cardinality
			rs_data.push_back("0");					// pages
			rs_data.push_back("0");					// filter
		}
	} else {
		std::string query("SHOW KEYS FROM `");
		query.append("`.`").append(table).append("`");

		std::auto_ptr<sql::PreparedStatement> stmt(connection->prepareStatement(query));

		std::auto_ptr<sql::ResultSet> rs(stmt->executeQuery());

		while (rs->next()) {
			rs_data.push_back("");				// Catalog
			rs_data.push_back(schema);			// Schema
			rs_data.push_back(rs->getString(1));// Table_name
			rs_data.push_back(rs->getString(2));// non unique
			rs_data.push_back("");				// index qualifier
			rs_data.push_back(rs->getString(3));// index name
			rs_data.push_back(buf);
			rs_data.push_back(rs->getString(4));// ordinal position
			rs_data.push_back(rs->getString(5));// column name 
			rs_data.push_back("ASC");			// asc or desc
			rs_data.push_back(rs->getString(6));// cardinality 
			rs_data.push_back("0");				// pages
			rs_data.push_back("");				// filter
		}
	}

	rs_field_data.push_back("TABLE_CATALOG");
	rs_field_data.push_back("TABLE_SCHEMA");
	rs_field_data.push_back("TABLE_NAME");
	rs_field_data.push_back("NON_UNIQUE");
	rs_field_data.push_back("INDEX_QUALIFIER");
	rs_field_data.push_back("INDEX_NAME");
	rs_field_data.push_back("TYPE");
	rs_field_data.push_back("ORDINAL_POSITION");
	rs_field_data.push_back("COLUMN_NAME");
	rs_field_data.push_back("ASC_OR_DESC");
	rs_field_data.push_back("CARDINALITY");
	rs_field_data.push_back("PAGES");
	rs_field_data.push_back("FILTER_CONDITION");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getCDBCMajorVersion() -I- */
int MySQL_ConnectionMetaData::getCDBCMajorVersion() const
{
	return 3;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getCDBCMinorVersion() -I- */
int MySQL_ConnectionMetaData::getCDBCMinorVersion() const
{
	return 0;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxBinaryLiteralLength() -I- */
int MySQL_ConnectionMetaData::getMaxBinaryLiteralLength() const
{
	return 16777208L;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxCatalogNameLength() -I- */
int MySQL_ConnectionMetaData::getMaxCatalogNameLength() const
{
	return 32;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxCharLiteralLength() -I- */
int MySQL_ConnectionMetaData::getMaxCharLiteralLength() const
{
	return 16777208;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxColumnNameLength() -I- */
int MySQL_ConnectionMetaData::getMaxColumnNameLength() const
{
	return 64;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxColumnsInGroupBy() -I- */
int MySQL_ConnectionMetaData::getMaxColumnsInGroupBy() const
{
	return 64;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxColumnsInIndex() -I- */
int MySQL_ConnectionMetaData::getMaxColumnsInIndex() const
{
	return 16;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxColumnsInOrderBy() -I- */
int MySQL_ConnectionMetaData::getMaxColumnsInOrderBy() const
{
	return 64;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxColumnsInSelect() -I- */
int MySQL_ConnectionMetaData::getMaxColumnsInSelect() const
{
	return 256;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxColumnsInTable() -I- */
int MySQL_ConnectionMetaData::getMaxColumnsInTable() const
{
	return 512;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxConnections() -I- */
int MySQL_ConnectionMetaData::getMaxConnections() const
{
	return 0;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxCursorNameLength() -I- */
int MySQL_ConnectionMetaData::getMaxCursorNameLength() const
{
	return 64;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxIndexLength() -I- */
int MySQL_ConnectionMetaData::getMaxIndexLength() const
{
	return 256;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxProcedureNameLength() -I- */
int MySQL_ConnectionMetaData::getMaxProcedureNameLength() const
{
	return 0;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxRowSize() -I- */
int MySQL_ConnectionMetaData::getMaxRowSize() const
{
	return 2147483647L - 8; // Max buffer size - HEADER
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxSchemaNameLength() -I- */
int MySQL_ConnectionMetaData::getMaxSchemaNameLength() const
{
	return 0;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxStatementLength() -I- */
int MySQL_ConnectionMetaData::getMaxStatementLength() const
{
	/* ToDo */
	return 0;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxStatements() -I- */
int MySQL_ConnectionMetaData::getMaxStatements() const
{
	return 0;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxTableNameLength() -I- */
int MySQL_ConnectionMetaData::getMaxTableNameLength() const
{
	return 64;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxTablesInSelect() -I- */
int MySQL_ConnectionMetaData::getMaxTablesInSelect() const
{
	return 256;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getMaxUserNameLength() -I- */
int MySQL_ConnectionMetaData::getMaxUserNameLength() const
{
	return 16;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getNumericFunctions() -I- */
std::string MySQL_ConnectionMetaData::getNumericFunctions() const
{
	static const std::string funcs("ABS,ACOS,ASIN,ATAN,ATAN2,BIT_COUNT,CEILING,COS,"
							"COT,DEGREES,EXP,FLOOR,LOG,LOG10,MAX,MIN,MOD,PI,POW,"
							"POWER,RADIANS,RAND,ROUND,SIN,SQRT,TAN,TRUNCATE");
	return funcs;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getPrimaryKeys() -Is- */
sql::ResultSet *
MySQL_ConnectionMetaData::getPrimaryKeys(std::string& catalog, std::string& schema, std::string& table) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	if (server_version > 49999) {
		static const std::string query("SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, " \
						"SEQ_IN_INDEX, INDEX_NAME FROM INFORMATION_SCHEMA.STATISTICS " \
						"WHERE TABLE_SCHEMA LIKE ? AND TABLE_NAME LIKE ? AND " \
						"INDEX_NAME='PRIMARY' ORDER BY TABLE_SCHEMA, TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX");

		std::auto_ptr<sql::PreparedStatement> stmt(connection->prepareStatement(query));

		stmt->setString(1, schema);
		stmt->setString(2, table);

		std::auto_ptr<sql::ResultSet> rs(stmt->executeQuery());

		while (rs->next()) {
			rs_data.push_back("");					// catalog
			rs_data.push_back(rs->getString(1));	// schema
			rs_data.push_back(rs->getString(2));	// table
			rs_data.push_back(rs->getString(3));	// column
			rs_data.push_back(rs->getString(4));	// sequence number
			rs_data.push_back(rs->getString(5));	// index name
		}
	} else {
		std::string query("SHOW KEYS FROM `");
		query.append(schema).append("`.`").append(table).append("`");
		
		std::auto_ptr<sql::PreparedStatement> stmt(connection->prepareStatement(query));
		std::auto_ptr<sql::ResultSet> rs(stmt->executeQuery());

		while (rs->next()) {
			if (!rs->getString(3).compare("PRIMARY")) {
				rs_data.push_back("");					// catalog
				rs_data.push_back(schema);				// schema
				rs_data.push_back(rs->getString(1));	// table
				rs_data.push_back(rs->getString(5));	// column
				rs_data.push_back(rs->getString(4));	// sequence number
				rs_data.push_back("PRIMARY");			// index name
			}
		}
	}
	rs_field_data.push_back("TABLE_CATALOG");
	rs_field_data.push_back("TABLE_SCHEMA");
	rs_field_data.push_back("TABLE_NAME");
	rs_field_data.push_back("COLUMN");
	rs_field_data.push_back("SEQUENCE");
	rs_field_data.push_back("INDEX_NAME");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);

}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getProcedures() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getProcedures(std::string& catalog, std::string& schemaPattern, std::string& procedureNamePattern) const
{

	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	if (server_version > 49999) {
		static const std::string query(
						"SELECT ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_COMMENT " \
						"FROM INFORMATION_SCHEMA.ROUTINES WHERE " \
						"ROUTINE_SCHEMA LIKE ? AND ROUTINE_NAME LIKE ? " \
						"ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME");

		std::auto_ptr<sql::PreparedStatement> stmt(connection->prepareStatement(query));

		stmt->setString(1, schemaPattern);
		stmt->setString(2, procedureNamePattern.size() ? procedureNamePattern : "%");

		std::auto_ptr<sql::ResultSet> rs(stmt->executeQuery());
		while (rs->next()) {
			rs_data.push_back(rs->getString(1));	// category
			rs_data.push_back(rs->getString(2));	// schema
			rs_data.push_back(rs->getString(3));	// name
			rs_data.push_back("");					// unsused
			rs_data.push_back("");					// unsused
			rs_data.push_back("");					// unsused
			rs_data.push_back(rs->getString(4));	// remarks
			rs_data.push_back("0");					// type
		}
	}

	rs_field_data.push_back("PROCEDURE_CAT");
	rs_field_data.push_back("PROCEDURE_SCHEMA");
	rs_field_data.push_back("PROCEDURE_NAME");
	rs_field_data.push_back("reserved1");
	rs_field_data.push_back("reserved2");
	rs_field_data.push_back("reserved3");
	rs_field_data.push_back("REMARKS");
	rs_field_data.push_back("PROCEDURE_TYPE");
	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getProcedureTerm() -I- */
const std::string& MySQL_ConnectionMetaData::getProcedureTerm() const
{
	static const std::string term("procedure");
	return term;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getResultSetHoldability() -I- */
int MySQL_ConnectionMetaData::getResultSetHoldability() const
{
	return sql::ResultSet::HOLD_CURSORS_OVER_COMMIT;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSchemas() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getSchemas() const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;
	
	rs_field_data.push_back("TABLE_SCHEMA");
	rs_field_data.push_back("TABLE_CATALOG");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSchemaTerm() -I- */
const std::string&
MySQL_ConnectionMetaData::getSchemaTerm() const
{
	static const std::string term("");
	return term;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSearchStringEscape() -I- */
const std::string&
MySQL_ConnectionMetaData::getSearchStringEscape() const
{
	static const std::string escape("\\");	
	return escape;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSQLKeywords() -I- */
const std::string&
MySQL_ConnectionMetaData::getSQLKeywords() const
{
	static const std::string keywords(
				"ACCESSIBLE, ADD, ALL,"\
				"ALTER, ANALYZE, AND, AS, ASC, ASENSITIVE, BEFORE,"\
				"BETWEEN, BIGINT, BINARY, BLOB, BOTH, BY, CALL,"\
				"CASCADE, CASE, CHANGE, CHAR, CHARACTER, CHECK,"\
				"COLLATE, COLUMN, CONDITION, CONNECTION, CONSTRAINT,"\
				"CONTINUE, CONVERT, CREATE, CROSS, CURRENT_DATE,"\
				"CURRENT_TIME, CURRENT_TIMESTAMP, CURRENT_USER, CURSOR,"\
				"DATABASE, DATABASES, DAY_HOUR, DAY_MICROSECOND,"\
				"DAY_MINUTE, DAY_SECOND, DEC, DECIMAL, DECLARE,"\
				"DEFAULT, DELAYED, DELETE, DESC, DESCRIBE,"\
				"DETERMINISTIC, DISTINCT, DISTINCTROW, DIV, DOUBLE,"\
				"DROP, DUAL, EACH, ELSE, ELSEIF, ENCLOSED,"\
				"ESCAPED, EXISTS, EXIT, EXPLAIN, FALSE, FETCH,"\
				"FLOAT, FLOAT4, FLOAT8, FOR, FORCE, FOREIGN, FROM,"\
				"FULLTEXT, GRANT, GROUP, HAVING, HIGH_PRIORITY,"\
				"HOUR_MICROSECOND, HOUR_MINUTE, HOUR_SECOND, IF,"\
				"IGNORE, IN, INDEX, INFILE, INNER, INOUT,"\
				"INSENSITIVE, INSERT, INT, INT1, INT2, INT3, INT4,"\
				"INT8, INTEGER, INTERVAL, INTO, IS, ITERATE, JOIN,"\
				"KEY, KEYS, KILL, LEADING, LEAVE, LEFT, LIKE,"\
				"LOCALTIMESTAMP, LOCK, LONG, LONGBLOB, LONGTEXT,"\
				"LOOP, LOW_PRIORITY, MATCH, MEDIUMBLOB, MEDIUMINT,"\
				"MEDIUMTEXT, MIDDLEINT, MINUTE_MICROSECOND,"\
				"MINUTE_SECOND, MOD, MODIFIES, NATURAL, NOT,"\
				"NO_WRITE_TO_BINLOG, NULL, NUMERIC, ON, OPTIMIZE,"\
				"OPTION, OPTIONALLY, OR, ORDER, OUT, OUTER,"\
				"OUTFILE, PRECISION, PRIMARY, PROCEDURE, PURGE,"\
				"RANGE, READ, READS, READ_ONLY, READ_WRITE, REAL,"\
				"REFERENCES, REGEXP, RELEASE, RENAME, REPEAT,"\
				"REPLACE, REQUIRE, RESTRICT, RETURN, REVOKE, RIGHT,"\
				"RLIKE, SCHEMA, SCHEMAS, SECOND_MICROSECOND, SELECT,"\
				"SENSITIVE, SEPARATOR, SET, SHOW, SMALLINT, SPATIAL,"\
				"SPECIFIC, SQL, SQLEXCEPTION, SQLSTATE, SQLWARNING,"\
				"SQL_BIG_RESULT, SQL_CALC_FOUND_ROWS, SQL_SMALL_RESULT,"\
				"SSL, STARTING, STRAIGHT_JOIN, TABLE, TERMINATED,"\
				"THEN, TINYBLOB, TINYINT, TINYTEXT, TO, TRAILING,"\
				"TRIGGER, TRUE, UNDO, UNION, UNIQUE, UNLOCK,"\
				"UNSIGNED, UPDATE, USAGE, USE, USING, UTC_DATE,"\
				"UTC_TIME, UTC_TIMESTAMP, VALUES, VARBINARY, VARCHAR,"\
				"VARCHARACTER, VARYING, WHEN, WHERE, WHILE, WITH,"\
				"WRITE, X509, XOR, YEAR_MONTH, ZEROFILL");

	return keywords;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSQLStateType() -I- */
int MySQL_ConnectionMetaData::getSQLStateType() const
{
	return sqlStateSQL99;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getStringFunctions() -I- */
const std::string& MySQL_ConnectionMetaData::getStringFunctions() const
{
	static const std::string funcs(
		"ASCII,BIN,BIT_LENGTH,CHAR,CHARACTER_LENGTH,CHAR_LENGTH,CONCAT,"
		"CONCAT_WS,CONV,ELT,EXPORT_SET,FIELD,FIND_IN_SET,HEX,INSERT,"
		"INSTR,LCASE,LEFT,LENGTH,LOAD_FILE,LOCATE,LOCATE,LOWER,LPAD,"
		"LTRIM,MAKE_SET,MATCH,MID,OCT,OCTET_LENGTH,ORD,POSITION,"
		"QUOTE,REPEAT,REPLACE,REVERSE,RIGHT,RPAD,RTRIM,SOUNDEX,"
		"SPACE,STRCMP,SUBSTRING,SUBSTRING,SUBSTRING,SUBSTRING,"
		"SUBSTRING_INDEX,TRIM,UCASE,UPPER");
	return funcs;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSuperTables() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getSuperTables(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;
	
	rs_field_data.push_back("TYPE_CATALOG");
	rs_field_data.push_back("TYPE_SCHEMA");
	rs_field_data.push_back("TYPE_NAME");
	rs_field_data.push_back("SUPERTABLE_NAME");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSuperTypes() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getSuperTypes(std::string& catalog, std::string& schemaPattern, std::string& typeNamePattern) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;
	
	rs_field_data.push_back("TYPE_CATALOG");
	rs_field_data.push_back("TYPE_SCHEMA");
	rs_field_data.push_back("TYPE_NAME");
	rs_field_data.push_back("SUPERTYPE_CATALOG");
	rs_field_data.push_back("SUPERTYPE_SCHEMA");
	rs_field_data.push_back("SUPERTYPE_NAME");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getSystemFunctions() -I- */
const std::string& MySQL_ConnectionMetaData::getSystemFunctions() const
{
	static const std::string funcs(
			"DATABASE,USER,SYSTEM_USER,"
			"SESSION_USER,PASSWORD,ENCRYPT,LAST_INSERT_ID,VERSION");
	return funcs;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getTablePrivileges() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getTablePrivileges(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	std::auto_ptr<sql::Statement> stmt(connection->createStatement());
	std::auto_ptr<sql::ResultSet> rs(stmt->executeQuery("SHOW GRANTS"));

	std::list< std::string > aPrivileges;
	std::list< std::string > aSchemas;
	std::list< std::string > aTables;

	std::string strAllPrivs("ALTER,DELETE,DROP,INDEX,INSERT,LOCK TABLES,SELECT,UPDATE");

	while (rs->next() ) {
		std::string cQuote(getIdentifierQuoteString());
		std::string aGrant = rs->getString(1);
		aGrant = aGrant.replace(0, 6, "");

		size_t pos = aGrant.find("ALL PRIVILEGES");

		if (pos != std::string::npos) {
			aGrant = aGrant.replace(pos, sizeof("ALL PRIVILEGES") - 1, strAllPrivs);
		}

		pos = aGrant.find("ON");
		aPrivileges.push_back(aGrant.substr(0, pos - 1)); /* -1 for trim */

		aGrant = aGrant.substr(pos + 3); /* remove "ON " */
		pos = 1;
		do {
			pos = aGrant.find(cQuote, pos);
		} while (aGrant[pos - 1] == '\\');
		/* first char is the quotestring, the last too "`xyz`." Dot is at 5, copy from 1, 5 - 1 - 1 = xyz */

		aSchemas.push_back(aGrant.substr(1, pos - 2)); /* From pos 1, without the quoting */
		int idx = pos + 2;
		pos = idx;
		do {
			pos = aGrant.find(cQuote, pos);
		} while (aGrant[pos - 1] == '\\');

		/*
		  `aaa`.`xyz`  - jump over the dot and the quote
		  . = 5
		  ` = 6
		  x = 7 = idx
		  ` = 10
		  ` - x = 10 - 7 = 3 -> xyz
		*/
		aTables.push_back(aGrant.substr(idx, idx - pos)); 
	}
	std::list< std::string > tableTypes;
	tableTypes.push_back(std::string("TABLE"));

	std::auto_ptr<sql::ResultSet> tables(getTables(catalog, schemaPattern, tableNamePattern, tableTypes));
	std::string schema, table;
	while (tables->next()) {
		schema = tables->getString(2);
		table = tables->getString(3);
		std::list<std::string>::iterator it_priv, it_schemas, it_tables;
		it_priv = aPrivileges.begin();
		it_schemas = aSchemas.begin();
		it_tables = aTables.begin();
		
		for (; it_priv != aPrivileges.end(); ++it_priv, ++it_schemas, ++it_tables) {
			if (it_priv->compare("USAGE") && matchTable(*it_schemas, *it_tables, schema, table)) {
				size_t pos, idx;
				pos = 0;
				do {
					idx = it_priv->find(",", pos);
					std::string privToken = it_priv->substr(pos, idx - pos);
					pos = idx + 1; /* skip ',' */

					if (privToken.find_first_of('/') == std::string::npos) {
						rs_data.push_back(NULL);			// Catalog
						rs_data.push_back(schema);			// Schema
						rs_data.push_back(table);			// Tablename
						rs_data.push_back(NULL);			// Grantor
						rs_data.push_back(getUserName());	// Grantee
						rs_data.push_back(privToken);		// privilege
						rs_data.push_back(NULL);			// is_grantable
					}
				} while (idx != std::string::npos);
				break;
			}
		}
	}

	rs_field_data.push_back("TABLE_CATALOG");
	rs_field_data.push_back("TABLE_SCHEMA");
	rs_field_data.push_back("TABLE_NAME");
	rs_field_data.push_back("GRANTOR");
	rs_field_data.push_back("GRANTEE");
	rs_field_data.push_back("PRIVILEGE");
	rs_field_data.push_back("IS_GRANTABLE");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getTables() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getTables(std::string& catalog, std::string& schemaPattern,
									std::string& tableNamePattern, std::list<std::string> &types) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;
	rs_field_data.push_back("TABLE_CATALOG");
	rs_field_data.push_back("TABLE_SCHEMA");
	rs_field_data.push_back("TABLE_NAME");
	rs_field_data.push_back("TABLE_TYPE");
	rs_field_data.push_back("TABLE_COMMENT");

	if (server_version > 49999) {
		static const std::string query("SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, " \
							"IF(STRCMP(TABLE_TYPE,'BASE TABLE'), TABLE_TYPE, 'TABLE'), " \
							"TABLE_COMMENT FROM INFORMATION_SCHEMA.TABLES WHERE " \
							"TABLE_SCHEMA  LIKE ? AND TABLE_NAME LIKE ? " \
							"ORDER BY TABLE_TYPE, TABLE_SCHEMA, TABLE_NAME");
		std::string pattern1, pattern2;

		std::auto_ptr<sql::PreparedStatement> stmt(connection->prepareStatement(query));
		pattern1.append("'");
		pattern1.append(schemaPattern);
		pattern1.append("'");

		pattern2.append("'");
		pattern2.append(tableNamePattern);
		pattern2.append("'");
		
		stmt->setString(1, pattern1);
		stmt->setString(2, pattern2);

		stmt->executeQuery();

		std::auto_ptr<sql::ResultSet> rs(stmt->executeQuery());

		while (rs->next()) {
			std::list<std::string>::iterator it;
			for (it = types.begin(); it != types.end(); ++it) {
				if (*it == rs->getString(4)) {
					rs_data.push_back(rs->getString(1));
					rs_data.push_back(rs->getString(2));
					rs_data.push_back(rs->getString(3));
					rs_data.push_back(rs->getString(4));
					rs_data.push_back(rs->getString(5));
					break;
				}
			}
		}
	} else {
		std::string query1("SHOW DATABASES LIKE '");
		query1.append(schemaPattern).append("'");

		std::auto_ptr<sql::Statement> stmt1(connection->createStatement());
		std::auto_ptr<sql::ResultSet> rs1(stmt1->executeQuery(query1));
		while (rs1->next()) {
			std::auto_ptr<sql::Statement> stmt2(connection->createStatement());

			std::string query2("SHOW TABLES FROM `");
			query2.append(rs1->getString(1)).append("` LIKE '").append(tableNamePattern).append("'");

			std::auto_ptr<sql::ResultSet> rs2(stmt2->executeQuery(query2));

			while (rs2->next()) {
				std::list<std::string>::iterator it;
				for (it = types.begin(); it != types.end(); ++it) {
					if (it->compare("TABLE")) {
						rs_data.push_back("");
						rs_data.push_back(rs1->getString(1));
						rs_data.push_back(rs2->getString(1));
						rs_data.push_back("TABLE");
						rs_data.push_back("");
						break;
					}
				}
			}
		}
	}
	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getTableTypes() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getTableTypes() const
{
	static const char * const table_types[] = {"TABLE", "VIEW", "LOCAL TEMPORARY"};
	static unsigned int requiredVersion[] = {32200, 50000, 32200};

	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	rs_field_data.push_back("TABLE_TYPE");

	for (int i = 0; i < 3; ++i) {
		if (server_version >= requiredVersion[i]) {
			rs_data.push_back(table_types[i]);
		}
	}
	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getTimeDateFunctions() -I- */
const std::string&
MySQL_ConnectionMetaData::getTimeDateFunctions() const
{
	static const std::string funcs(
		"DAYOFWEEK,WEEKDAY,DAYOFMONTH,DAYOFYEAR,MONTH,DAYNAME,"
		"MONTHNAME,QUARTER,WEEK,YEAR,HOUR,MINUTE,SECOND,PERIOD_ADD,"
		"PERIOD_DIFF,TO_DAYS,FROM_DAYS,DATE_FORMAT,TIME_FORMAT,"
		"CURDATE,CURRENT_DATE,CURTIME,CURRENT_TIME,NOW,SYSDATE,"
		"CURRENT_TIMESTAMP,UNIX_TIMESTAMP,FROM_UNIXTIME,"
		"SEC_TO_TIME,TIME_TO_SEC");
	return funcs;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getTypeInfo() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getTypeInfo() const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;
	int i = 0;
	char buf[16];
	buf[sizeof(buf) - 1] = '\0';

	rs_field_data.push_back("TYPE_NAME");
	rs_field_data.push_back("DATA_TYPE");
	rs_field_data.push_back("PRECISION");
	rs_field_data.push_back("LITERAL_PREFIX");
	rs_field_data.push_back("LITERAL_SUFFIX");
	rs_field_data.push_back("CREATE_PARAMS");
	rs_field_data.push_back("NULLABLE");
	rs_field_data.push_back("CASE_SENSITIVE");
	rs_field_data.push_back("SEARCHABLE");
	rs_field_data.push_back("UNSIGNED_ATTRIBUTE");
	rs_field_data.push_back("FIXED_PREC_SCALE");
	rs_field_data.push_back("AUTO_INCREMENT");
	rs_field_data.push_back("LOCAL_TYPE_NAME");
	rs_field_data.push_back("MINIMUM_SCALE");
	rs_field_data.push_back("MAXIMUM_SCALE");
	rs_field_data.push_back("SQL_DATA_TYPE");
	rs_field_data.push_back("SQL_DATETIME_SUB");
	rs_field_data.push_back("NUM_PREC_RADIX");

	while (mysqlc_types[i].typeName) {
		rs_data.push_back(mysqlc_types[i].typeName);
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].dataType));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].precision));
		rs_data.push_back("");
		rs_data.push_back("");
		rs_data.push_back(mysqlc_types[i].createParams);
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].nullable));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].caseSensitive));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].searchable));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].isUnsigned));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].fixedPrecScale));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].autoIncrement));
		rs_data.push_back(mysqlc_types[i].localTypeName);
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].minScale));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) mysqlc_types[i].maxScale));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) 0));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) 0));
		rs_data.push_back(my_i_to_a(buf, sizeof(buf)-1, (long) 10));
		i++;
	}

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getUDTs() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getUDTs(std::string& catalog, std::string& schemaPattern,
									std::string& typeNamePattern, std::list<int> &types) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	rs_field_data.push_back("TYPE_CATALOG");
	rs_field_data.push_back("TYPE_SCHEMA");
	rs_field_data.push_back("TYPE_NAME");
	rs_field_data.push_back("CLASS_NAME");
	rs_field_data.push_back("DATA_TYPE");
	rs_field_data.push_back("REMARKS");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getUserName() -I- */
std::string
MySQL_ConnectionMetaData::getUserName() const
{
	std::auto_ptr<sql::Statement> stmt(connection->createStatement());
	std::auto_ptr<sql::ResultSet> rset(stmt->executeQuery("SELECT USER()"));
	if (rset->next()) {
		return std::string(rset->getString(1));
	}
	return NULL;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::getVersionColumns() -I- */
sql::ResultSet *
MySQL_ConnectionMetaData::getVersionColumns(std::string& catalog, std::string& schema, std::string& table) const
{
	std::list<std::string> rs_data;
	std::list<std::string> rs_field_data;

	rs_field_data.push_back("SCOPE");
	rs_field_data.push_back("COLUMN_NAME");
	rs_field_data.push_back("DATA_TYPE");
	rs_field_data.push_back("TYPE_NAME");
	rs_field_data.push_back("COLUMN_SIZE");
	rs_field_data.push_back("BUFFER_LENGTH");
	rs_field_data.push_back("DECIMAL_DIGITS");
	rs_field_data.push_back("PSEUDO_COLUMN");

	return new MySQL_ConstructedResultSet(rs_field_data, rs_data);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::insertsAreDetected() -I- */
bool
MySQL_ConnectionMetaData::insertsAreDetected(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::isCatalogAtStart() -I- */
bool
MySQL_ConnectionMetaData::isCatalogAtStart() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::isReadOnly() -I- */
bool
MySQL_ConnectionMetaData::isReadOnly() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::nullPlusNonNullIsNull() -I- */
bool
MySQL_ConnectionMetaData::nullPlusNonNullIsNull() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::nullsAreSortedAtEnd() -I- */
bool
MySQL_ConnectionMetaData::nullsAreSortedAtEnd() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::nullsAreSortedAtStart() -I- */
bool
MySQL_ConnectionMetaData::nullsAreSortedAtStart() const
{
	return server_version > 40001 && server_version < 40011;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::nullsAreSortedHigh() -I- */
bool
MySQL_ConnectionMetaData::nullsAreSortedHigh() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::nullsAreSortedLow() -I- */
bool
MySQL_ConnectionMetaData::nullsAreSortedLow() const
{
	return !nullsAreSortedHigh();
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::othersDeletesAreVisible() -I- */
bool
MySQL_ConnectionMetaData::othersDeletesAreVisible(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::othersInsertsAreVisible() -I- */
bool
MySQL_ConnectionMetaData::othersInsertsAreVisible(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::othersUpdatesAreVisible() -I- */
bool
MySQL_ConnectionMetaData::othersUpdatesAreVisible(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::ownDeletesAreVisible() -I- */
bool
MySQL_ConnectionMetaData::ownDeletesAreVisible(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::ownInsertsAreVisible() -I- */
bool
MySQL_ConnectionMetaData::ownInsertsAreVisible(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::ownUpdatesAreVisible() -I- */
bool
MySQL_ConnectionMetaData::ownUpdatesAreVisible(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::storesLowerCaseIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::storesLowerCaseIdentifiers() const
{
	std::string val = connection->getSessionVariable("lower_case_table_names");
	return (val == std::string("1") || val == std::string("2"));
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::storesLowerCaseQuotedIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::storesLowerCaseQuotedIdentifiers() const
{
	std::string val = connection->getSessionVariable("lower_case_table_names");
	return (val == std::string("1") || val == std::string("2"));
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::storesMixedCaseIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::storesMixedCaseIdentifiers() const
{
	std::string val = connection->getSessionVariable("lower_case_table_names");
	return !(val == std::string("1") || val == std::string("2"));
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::storesMixedCaseQuotedIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::storesMixedCaseQuotedIdentifiers() const
{
	std::string val = connection->getSessionVariable("lower_case_table_names");
	return !(val == std::string("1") || val == std::string("2"));
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::storesUpperCaseIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::storesUpperCaseIdentifiers() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::storesUpperCaseQuotedIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::storesUpperCaseQuotedIdentifiers() const
{
	return true; // not actually true, but required by JDBC spec!?
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsAlterTableWithAddColumn() -I- */
bool
MySQL_ConnectionMetaData::supportsAlterTableWithAddColumn() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsAlterTableWithDropColumn() -I- */
bool
MySQL_ConnectionMetaData::supportsAlterTableWithDropColumn() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsANSI92EntryLevelSQL-I-  */
bool
MySQL_ConnectionMetaData::supportsANSI92EntryLevelSQL() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsANSI92FullSQL() -I- */
bool
MySQL_ConnectionMetaData::supportsANSI92FullSQL() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsANSI92IntermediateSQL() -I- */
bool
MySQL_ConnectionMetaData::supportsANSI92IntermediateSQL() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsBatchUpdates() -I- */
bool
MySQL_ConnectionMetaData::supportsBatchUpdates() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsCatalogsInDataManipulation() -I- */
bool
MySQL_ConnectionMetaData::supportsCatalogsInDataManipulation() const
{
	return server_version >= 32200;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsCatalogsInIndexDefinitions() -I- */
bool
MySQL_ConnectionMetaData::supportsCatalogsInIndexDefinitions() const
{
	return server_version >= 32200;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsCatalogsInPrivilegeDefinitions() -I- */
bool
MySQL_ConnectionMetaData::supportsCatalogsInPrivilegeDefinitions() const
{
	return server_version > 32200;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsCatalogsInProcedureCalls() -I- */
bool
MySQL_ConnectionMetaData::supportsCatalogsInProcedureCalls() const
{
	return server_version >= 32200;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsCatalogsInTableDefinitions() -I- */
bool
MySQL_ConnectionMetaData::supportsCatalogsInTableDefinitions() const
{
	return server_version >= 32200;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsColumnAliasing() -I- */
bool
MySQL_ConnectionMetaData::supportsColumnAliasing() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsConvert() -I- */
bool
MySQL_ConnectionMetaData::supportsConvert() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsCoreSQLGrammar() -I- */
bool
MySQL_ConnectionMetaData::supportsCoreSQLGrammar() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsCorrelatedSubqueries() -I- */
bool
MySQL_ConnectionMetaData::supportsCorrelatedSubqueries() const
{
	return server_version >= 40100;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsDataDefinitionAndDataManipulationTransactions() -I- */
bool
MySQL_ConnectionMetaData::supportsDataDefinitionAndDataManipulationTransactions() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsDataManipulationTransactionsOnly() -I- */
bool
MySQL_ConnectionMetaData::supportsDataManipulationTransactionsOnly() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsDifferentTableCorrelationNames() -I- */
bool
MySQL_ConnectionMetaData::supportsDifferentTableCorrelationNames() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsExpressionsInOrderBy() -I- */
bool
MySQL_ConnectionMetaData::supportsExpressionsInOrderBy() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsExtendedSQLGrammar() -I- */
bool
MySQL_ConnectionMetaData::supportsExtendedSQLGrammar() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsFullOuterJoins() -I- */
bool
MySQL_ConnectionMetaData::supportsFullOuterJoins() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsGetGeneratedKeys() -I- */
bool
MySQL_ConnectionMetaData::supportsGetGeneratedKeys() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsGroupBy() -I- */
bool
MySQL_ConnectionMetaData::supportsGroupBy() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsGroupByBeyondSelect() -I- */
bool
MySQL_ConnectionMetaData::supportsGroupByBeyondSelect() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsGroupByUnrelated() -I- */
bool
MySQL_ConnectionMetaData::supportsGroupByUnrelated() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsLikeEscapeClause() -I- */
bool
MySQL_ConnectionMetaData::supportsLikeEscapeClause() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsLimitedOuterJoins() -I- */
bool
MySQL_ConnectionMetaData::supportsLimitedOuterJoins() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsMinimumSQLGrammar() -I- */
bool
MySQL_ConnectionMetaData::supportsMinimumSQLGrammar() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsMixedCaseIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::supportsMixedCaseIdentifiers() const
{
	std::string val = connection->getSessionVariable("lower_case_table_names");
	return !(val == std::string("1") || val == std::string("2"));
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsMixedCaseQuotedIdentifiers() -I- */
bool
MySQL_ConnectionMetaData::supportsMixedCaseQuotedIdentifiers() const
{
	std::string val = connection->getSessionVariable("lower_case_table_names");
	return !(val == std::string("1") || val == std::string("2"));
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsMultipleOpenResults() -I- */
bool
MySQL_ConnectionMetaData::supportsMultipleOpenResults() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsMultipleResultSets() -I- */
bool
MySQL_ConnectionMetaData::supportsMultipleResultSets() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsMultipleTransactions() -I- */
bool
MySQL_ConnectionMetaData::supportsMultipleTransactions() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsNamedParameters() -I- */
bool
MySQL_ConnectionMetaData::supportsNamedParameters() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsNonNullableColumns() -I- */
bool
MySQL_ConnectionMetaData::supportsNonNullableColumns() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsOpenCursorsAcrossCommit() -I- */
bool
MySQL_ConnectionMetaData::supportsOpenCursorsAcrossCommit() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsOpenCursorsAcrossRollback() -I- */
bool
MySQL_ConnectionMetaData::supportsOpenCursorsAcrossRollback() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsOpenStatementsAcrossCommit() -I- */
bool
MySQL_ConnectionMetaData::supportsOpenStatementsAcrossCommit() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsOpenStatementsAcrossRollback() -I- */
bool
MySQL_ConnectionMetaData::supportsOpenStatementsAcrossRollback() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsOrderByUnrelated() -I- */
bool
MySQL_ConnectionMetaData::supportsOrderByUnrelated() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsOuterJoins() -I- */
bool
MySQL_ConnectionMetaData::supportsOuterJoins() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsPositionedDelete() -I- */
bool
MySQL_ConnectionMetaData::supportsPositionedDelete() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsPositionedUpdate() -I- */
bool
MySQL_ConnectionMetaData::supportsPositionedUpdate() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsResultSetHoldability() -I- */
bool
MySQL_ConnectionMetaData::supportsResultSetHoldability(int holdability) const
{
	return (holdability == sql::ResultSet::HOLD_CURSORS_OVER_COMMIT);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsResultSetType() -I- */
bool
MySQL_ConnectionMetaData::supportsResultSetType(int type) const
{
	return (type == sql::ResultSet::TYPE_SCROLL_INSENSITIVE);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSavepoints() -I- */
bool
MySQL_ConnectionMetaData::supportsSavepoints() const
{
	return (server_version >= 40014 || server_version >= 40101);
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSchemasInDataManipulation() -I- */
bool
MySQL_ConnectionMetaData::supportsSchemasInDataManipulation() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSchemasInIndexDefinitions() -I- */
bool
MySQL_ConnectionMetaData::supportsSchemasInIndexDefinitions() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSchemasInPrivilegeDefinitions() -I- */
bool
MySQL_ConnectionMetaData::supportsSchemasInPrivilegeDefinitions() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSchemasInProcedureCalls() -I- */
bool
MySQL_ConnectionMetaData::supportsSchemasInProcedureCalls() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSchemasInTableDefinitions() -I- */
bool
MySQL_ConnectionMetaData::supportsSchemasInTableDefinitions() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSelectForUpdate() -I- */
bool
MySQL_ConnectionMetaData::supportsSelectForUpdate() const
{
	return server_version >= 40000;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsStatementPooling() -I- */
bool
MySQL_ConnectionMetaData::supportsStatementPooling() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsStoredProcedures() -I- */
bool
MySQL_ConnectionMetaData::supportsStoredProcedures() const
{
	return server_version >= 50000;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSubqueriesInComparisons() -I- */
bool
MySQL_ConnectionMetaData::supportsSubqueriesInComparisons() const
{
	return server_version >= 40100;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSubqueriesInExists() -I- */
bool
MySQL_ConnectionMetaData::supportsSubqueriesInExists() const
{
	return server_version >= 40100;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSubqueriesInIns() -I- */
bool
MySQL_ConnectionMetaData::supportsSubqueriesInIns() const
{
	return server_version >= 40100;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsSubqueriesInQuantifieds() -I- */
bool
MySQL_ConnectionMetaData::supportsSubqueriesInQuantifieds() const
{
	return server_version >= 40100;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsTableCorrelationNames() -I- */
bool
MySQL_ConnectionMetaData::supportsTableCorrelationNames() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsTransactionIsolationLevel() -I- */
bool
MySQL_ConnectionMetaData::supportsTransactionIsolationLevel(int level) const
{
	return server_version >= 32336;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsTransactions() -I- */
bool
MySQL_ConnectionMetaData::supportsTransactions() const
{
	return server_version >= 32315;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsTypeConversion() -I- */
bool
MySQL_ConnectionMetaData::supportsTypeConversion() const
{
	return true;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsUnion() -I- */
bool
MySQL_ConnectionMetaData::supportsUnion() const
{
	return server_version >= 40000;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::supportsUnionAll() -I- */
bool
MySQL_ConnectionMetaData::supportsUnionAll() const
{
	return server_version >= 40000;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::updatesAreDetected() -I- */
bool
MySQL_ConnectionMetaData::updatesAreDetected(int type) const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::usesLocalFilePerTable() -I- */
bool
MySQL_ConnectionMetaData::usesLocalFilePerTable() const
{
	return false;
}
/* }}} */


/* {{{ MySQL_ConnectionMetaData::usesLocalFiles() -I- */
bool
MySQL_ConnectionMetaData::usesLocalFiles() const
{
	return false;
}
/* }}} */

/* {{{ MySQL_ConnectionMetaData::matchTable() -I- */
bool
MySQL_ConnectionMetaData::matchTable(std::string &sPattern, std::string & tPattern, std::string & schema, std::string & table) const
{
	return ((!sPattern.compare(schema) || !sPattern.compare("*")) && (!tPattern.compare(table)  || !tPattern.compare("*")));
}


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
