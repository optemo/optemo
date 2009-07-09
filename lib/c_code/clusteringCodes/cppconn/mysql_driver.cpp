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

#include "mysql_driver.h"
#include "mysql_connection.h"

extern "C"
{
CPPDBC_PUBLIC_FUNC sql::Driver *get_driver_instance()
{
	static sql::mysql::MySQL_Driver * d = new sql::mysql::MySQL_Driver;
	return d;
}
} /* extern_c */


namespace sql
{
namespace mysql
{

static MySQL_Driver driver;


CPPDBC_PUBLIC_FUNC MySQL_Driver *get_mysql_driver_instance()
{
	return &driver;
}


MySQL_Driver::MySQL_Driver()
{
	mysql_library_init(0, NULL, NULL);
}


MySQL_Driver::~MySQL_Driver()
{
	mysql_library_end();
}


sql::Connection *MySQL_Driver::connect(const std::string& hostName, 
									const std::string& port, 
									const std::string& userName, 
									const std::string& password)
{
	return new MySQL_Connection(hostName, port, userName, password);
}

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
