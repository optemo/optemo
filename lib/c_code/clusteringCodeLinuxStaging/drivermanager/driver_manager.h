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

#ifndef _DRIVER_MANAGER_H_
#define _DRIVER_MANAGER_H_

#include <list>
#include <map>

#include "dbciface/connection.h"
#include "dbciface/exception.h"
#include "dbciface/metadata.h"
#include "dbciface/prepared_statement.h"
#include "dbciface/resultset.h"
#include "dbciface/statement.h"


namespace sql
{

class Connection;
class Driver;
class PrintWriter;
class db_mgmt_Connection;
class Driver;

class CPPDBC_PUBLIC_FUNC DriverManager
{
  std::list<Driver *> _drivers;
  void *gmodule;
public:
  static DriverManager *getDriverManager();

  DriverManager();
  ~DriverManager();

  Connection *getConnection(db_mgmt_Connection *connectionProperties);
  
  Connection *getConnection(const std::string& libraryName, 
                            const std::string& hostName, 
                            const std::string& port, 
                            const std::string& userName, 
                            const std::string& password, 
                            const std::map<std::string, std::string>& advParams);

  Connection *getConnection(const std::string& libraryName);
  
  void setLogWriter(PrintWriter *out) {}
  
  // Returns the list of available drivers
  std::list<Driver *> getDrivers();  
};

}; /* namespace sql */

#endif // _DRIVER_MANAGER_H_

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
