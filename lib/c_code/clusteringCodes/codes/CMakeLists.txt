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

cmake_minimum_required(VERSION 2.4)

SET(CMAKE_VERBOSE_MAKEFILE 0)

INCLUDE_DIRECTORIES(${MYSQLCPPCONN_SOURCE_DIR})
LINK_DIRECTORIES(${MYSQLCPPCONN_SOURCE_DIR}/cppconn)

IF(WIN32)
	INCLUDE_DIRECTORIES(${MYSQLCPPCONN_SOURCE_DIR/cppconn})

	IF(CMAKE_BUILD_TYPE STREQUAL "Debug")
		LINK_DIRECTORIES(${MYSQL_DIR}/lib/debug)
	ELSEIF(CMAKE_BUILD_TYPE STREQUAL "")
		LINK_DIRECTORIES(${MYSQL_DIR}/lib/opt)
	ENDIF(CMAKE_BUILD_TYPE STREQUAL "Debug")

	SET(MY_TARGET_LINK_LIBRARIES mysqlcppconn libmysql)
ELSEIF(NOT WIN32)
	SET(MY_TARGET_LINK_LIBRARIES mysqlcppconn-static mysqlclient_r)
ENDIF(WIN32)

ADD_EXECUTABLE(hCluster hClustering.cpp)
TARGET_LINK_LIBRARIES(hCluster ${MY_TARGET_LINK_LIBRARIES})

MESSAGE(STATUS "Configuring examples")
