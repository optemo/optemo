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

#ifndef _PREPARED_STATEMENT_H_
#define _PREPARED_STATEMENT_H_

#include "statement.h"

namespace sql
{

class ResultSet;
class Connection;

class PreparedStatement : public Statement
{
public:
	virtual ~PreparedStatement() {}

	virtual void cancel() = 0;

	virtual void clearParameters() = 0;

	using Statement::execute;
	virtual bool execute() = 0;

	using Statement::executeQuery;
	virtual ResultSet *executeQuery() = 0;

	using Statement::executeUpdate;
	virtual int executeUpdate() = 0;

	virtual void setBoolean(int parameterIndex, bool value) = 0;

	virtual void setDateTime(int parameterIndex, const std::string& value) = 0;

	virtual void setDouble(int parameterIndex, double value) = 0;

	virtual void setInt(int parameterIndex, int value) = 0;

	virtual void setLong(int parameterIndex, long long value) = 0;

	virtual void setBigInt(int parameterIndex, const std::string& value) = 0;

	virtual void setString(int parameterIndex, const std::string& value) = 0;
};


}; /* namespace sql */

#endif // _PREPARED_STATEMENT_H_
