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

#ifndef _DRIVER_H_
#define _DRIVER_H_

#include <string>

#if defined(_WIN32)
 #ifdef CPPDBC_EXPORTS
  #define CPPDBC_PUBLIC_FUNC __declspec(dllexport)
 #else
  #define CPPDBC_PUBLIC_FUNC __declspec(dllimport)
 #endif
#else
 #define CPPDBC_PUBLIC_FUNC
#endif

namespace sql
{

class Connection;
class db_mgmt_Connection;

class CPPDBC_PUBLIC_FUNC Driver
{
public:
	// Attempts to make a database connection to the given URL.

	virtual Connection *connect(const std::string& hostName, 
									const std::string& port, 
									const std::string& userName, 
									const std::string& password) = 0;
	virtual ~Driver() {}

	virtual int getMajorVersion() = 0;

	virtual int getMinorVersion() = 0;

	virtual std::string getName() = 0;
};

}; /* namespace sql */

#endif // _DRIVER_H_
