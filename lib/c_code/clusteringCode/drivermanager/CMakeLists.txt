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

SET(GLIB_DIR "/usr" CACHE PATH "glib-dir")
INCLUDE_DIRECTORIES(${MYSQLCPPCONN_SOURCE_DIR})
INCLUDE_DIRECTORIES(${MYSQLCPPCONN_SOURCE_DIR}/cppconn)

SET(CMAKE_REQUIRED_INCLUDES ${GLIB_DIR}/lib/glib-2.0/include ${GLIB_DIR}/include/glib-2.0/)
CHECK_INCLUDE_FILES(glib.h HAVE_GLIB_H)

IF(HAVE_GLIB_H)
	INCLUDE_DIRECTORIES(${GLIB_DIR}/lib/glib-2.0/include ${GLIB_DIR}/include/glib-2.0/)
	ADD_LIBRARY(drivermanager SHARED driver_manager.cpp)
	TARGET_LINK_LIBRARIES(drivermanager gmodule-2.0 ${MYSQL_CFLAGS})
	SET(HAVE_DRIVER_MANAGER 1)
ENDIF(HAVE_GLIB_H)

SET(CMAKE_REQUIRED_INCLUDES)

MESSAGE(STATUS "Configuring drivermanager")
