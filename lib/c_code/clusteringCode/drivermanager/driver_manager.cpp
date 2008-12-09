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


#include <glib.h>
#include <gmodule.h>

#include "dbciface/driver.h"
#include "dbciface/exception.h"
#include "driver_manager.h"

namespace sql
{

DriverManager::DriverManager()
  :gmodule(NULL)
{

}

DriverManager::~DriverManager()
{
	if (gmodule) {
		g_module_close((GModule*) gmodule);
	}
}

DriverManager *DriverManager::getDriverManager()
{
	static DriverManager *dm = new DriverManager;
	return dm;
}

Connection *DriverManager::getConnection(db_mgmt_Connection *connectionProperties)
{
	return NULL;
}


Connection *DriverManager::getConnection(const std::string& libraryName, 
										 const std::string& hostName, 
										 const std::string& port, 
										 const std::string& userName, 
										 const std::string& password, 
										 const std::map<std::string, std::string>& advParams)
{
	// 1. find driver
	const char *library = libraryName.c_str();

	gmodule= g_module_open(library, G_MODULE_BIND_LOCAL);
	if (!gmodule) {
		// error
		throw new DbcException( "", __LINE__, "Database driver: Failed to open library. Check	settings.");
	}

	Driver *(* get_driver_instance)()= NULL;

	g_module_symbol((GModule*) gmodule, "get_driver_instance", (gpointer*)&get_driver_instance);

	if (get_driver_instance == NULL) {
		// error
		throw new DbcException( "", __LINE__, "Database driver: Failed to get library instance. Check settings.");
	}

	// 2. call driver->connect()
	
	return get_driver_instance()->connect(hostName, port, userName, password);
}


Connection *DriverManager::getConnection(const std::string& libraryName)
{
	std::string hostName("localhost"); 
	std::string port("3306");
	std::string userName("root"); 
	std::string password(""); 

	gmodule= g_module_open(libraryName.c_str(), G_MODULE_BIND_LOCAL);
	if (!gmodule) {
		// error
		throw new DbcException( "", __LINE__, "Database driver: Failed to open library. Check	settings.");
	}

	Driver *(* get_driver_instance)()= NULL;

	g_module_symbol((GModule*) gmodule, "get_driver_instance", (gpointer*)&get_driver_instance);

	if (get_driver_instance == NULL) {
		// error
		throw new DbcException( "", __LINE__, "Database driver: Failed to get library instance. Check settings.");
	}

	// 2. call driver->connect()
	
	return get_driver_instance()->connect(hostName, port, userName, password);
}


}; /* namespace sql */
//void DriverManager::setLogWriter(PrintWriter *out);


/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
