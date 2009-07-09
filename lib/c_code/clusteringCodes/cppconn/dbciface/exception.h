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

#ifndef _DBC_EXCEPTION_H_
#define _DBC_EXCEPTION_H_


#include <stdexcept>

namespace sql
{

struct DbcException : public std::runtime_error
{
  DbcException(const char *, int , const char *t) : std::runtime_error(t) { /* if (line) printf("DbcException[%s::%d] %s\n", func, line, t); */}
  virtual ~DbcException() throw () {}
};

struct DbcMethodNotImplemented : public DbcException
{
  DbcMethodNotImplemented(const char *t) : DbcException("", 0, t) {}
  virtual ~DbcMethodNotImplemented() throw () {}
};

struct DbcInvalidArgument : public DbcException
{
  DbcInvalidArgument(const char *func, int line, const char *t) : DbcException(func, line, t) { /* printf("InvalidArgument[%s::%d] %s\n", func, line, t); */}
  virtual ~DbcInvalidArgument() throw () {}
};

}; /* namespace sql */

#endif // _DBC_EXCEPTION_H_
