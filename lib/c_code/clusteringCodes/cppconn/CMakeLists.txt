#   Copyright (C) 2007-2008 Sun Microsystems
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 2 of the License.
#
#   There are special exceptions to the terms and conditions of the GPL 
#   as it is applied to this software. View the full text of the 
#   exception in file EXCEPTIONS-CONNECTOR-C++ in the directory of this 
#   software distribution.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

ADD_DEFINITIONS("-DCPPDBC_EXPORTS")

INCLUDE_DIRECTORIES(${MYSQLCPPCONN_SOURCE_DIR})
INCLUDE_DIRECTORIES(${MYSQLCPPCONN_SOURCE_DIR}/cppconn)

SET(cppcon_sources
	mysql_connection.cpp
	mysql_constructed_resultset.cpp
	mysql_driver.cpp
	mysql_exception.cpp
	mysql_metadata.cpp
	mysql_prepared_statement.cpp
	mysql_ps_resultset.cpp
	mysql_resultset.cpp
	mysql_resultset_metadata.cpp
	mysql_res_wrapper.cpp
	mysql_statement.cpp)

ADD_LIBRARY(mysqlcppconn SHARED ${cppcon_sources})
ADD_LIBRARY(mysqlcppconn-static STATIC ${cppcon_sources})

IF(WIN32)
	INCLUDE_DIRECTORIES(${MYSQL_DIR}/include)
	IF(CMAKE_BUILD_TYPE STREQUAL "Debug")
		LINK_DIRECTORIES(${MYSQL_DIR}/lib/debug)
	ELSEIF(CMAKE_BUILD_TYPE STREQUAL "")
		LINK_DIRECTORIES(${MYSQL_DIR}/lib/opt)
	ENDIF(CMAKE_BUILD_TYPE STREQUAL "Debug")
	

	SET(MY_TARGET_LINK_LIBRARIES_DYNAMIC libmysql ws2_32)
	SET(MY_TARGET_LINK_LIBRARIES_STATIC mysqlclient ws2_32)
ELSEIF(NOT WIN32)
	SET(MY_TARGET_LINK_LIBRARIES_DYNAMIC ${MYSQL_LIBRARIES} ${MYSQL_LINK_FLAGS})
	SET(MY_TARGET_LINK_LIBRARIES_STATIC ${MYSQL_LIBRARIES} ${MYSQL_LINK_FLAGS})
ENDIF(WIN32)



TARGET_LINK_LIBRARIES(mysqlcppconn ${MY_TARGET_LINK_LIBRARIES_DYNAMIC})
TARGET_LINK_LIBRARIES(mysqlcppconn-static ${MY_TARGET_LINK_LIBRARIES_STATIC})

MESSAGE(STATUS "Configuring cppconn")
