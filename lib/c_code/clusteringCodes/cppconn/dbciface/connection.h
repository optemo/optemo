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

#ifndef _CONNECTION_H_
#define _CONNECTION_H_

#if defined(_WIN32)
 #ifdef CPPDBC_EXPORTS
  #define CPPDBC_PUBLIC_FUNC __declspec(dllexport)
 #else
  #define CPPDBC_PUBLIC_FUNC __declspec(dllimport)
 #endif
#else
 #define CPPDBC_PUBLIC_FUNC
#endif



#include <string>
#include <map>

namespace sql
{

class DatabaseMetaData;
class PreparedStatement;
class Statement;

typedef enum transaction_isolation
{
	TRANSACTION_NONE= 0,
	TRANSACTION_READ_COMMITTED,
	TRANSACTION_READ_UNCOMMITTED,
	TRANSACTION_REPEATABLE_READ,
	TRANSACTION_SERIALIZABLE
} enum_transaction_isolation;

class Savepoint
{
	/* Prevent use of these */
	Savepoint(const Savepoint &);
	void operator=(Savepoint &);
public:
	Savepoint() {};
	virtual ~Savepoint() {};
	virtual int getSavepointId() = 0;

	virtual std::string &getSavepointName() = 0;
};


class CPPDBC_PUBLIC_FUNC Connection
{
	/* Prevent use of these */
	Connection(const Connection &);
	void operator=(Connection &);
public:

	Connection() {};

	virtual ~Connection() {};

	virtual void clearWarnings() = 0;

	virtual Statement *createStatement() = 0;

	virtual void commit() = 0;
	
	virtual bool getAutoCommit() = 0;

	virtual std::string * getCatalog() = 0;

	virtual const std::string& getClientInfo(const std::string& name) = 0;

	/* virtual int getHoldability() = 0; */

	/* virtual std::map getTypeMap() = 0; */ 

	virtual DatabaseMetaData *getMetaData() = 0;

	virtual enum_transaction_isolation getTransactionIsolation() = 0;

	virtual void getWarnings() = 0;

	virtual bool isClosed() = 0;

	virtual std::string *nativeSQL(const std::string& sql) = 0;

	virtual PreparedStatement *prepareStatement(const std::string& sql) = 0;

	virtual void releaseSavepoint(Savepoint * savepoint) = 0;

	virtual void rollback() = 0;

	virtual void rollback(Savepoint * savepoint) = 0;

	virtual void setAutoCommit(bool autoCommit) = 0;

	virtual void setCatalog(const std::string& catalog) = 0;

	virtual Savepoint *setSavepoint() = 0;

	virtual Savepoint *setSavepoint(const std::string& name) = 0;

	virtual void setTransactionIsolation(enum_transaction_isolation level) = 0;

	/* virtual void setTypeMap(Map map) = 0; */  
};

}; /* namespace sql */

#endif // _CONNECTION_H_
