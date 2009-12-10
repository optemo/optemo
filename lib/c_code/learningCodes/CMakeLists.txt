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

PROJECT(MYSQLCPPCONN)

cmake_minimum_required(VERSION 2.4)
if(COMMAND cmake_policy)
        cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)

INCLUDE(CheckIncludeFiles)
INCLUDE(CheckFunctionExists)
INCLUDE(CheckTypeSize)

IF(NOT WIN32)
ADD_DEFINITIONS("-Wall -fPIC -Woverloaded-virtual")
ENDIF(NOT WIN32)

INCLUDE(${CMAKE_SOURCE_DIR}/FindMySQL.cmake)

ADD_SUBDIRECTORY(cppconn)
ADD_SUBDIRECTORY(codes)
