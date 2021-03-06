// getpid.cpp
//
// Copyright (C) 2009-2010 Peter Graves <gnooth@gmail.com>
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#ifndef WIN32
#include <sys/types.h>
#include <unistd.h>
#endif

#include "lisp.hpp"

Value EXT_getpid()
{
#ifdef WIN32
  DWORD pid = GetCurrentProcessId();
#else
  pid_t pid = getpid();
#endif
  return make_unsigned_integer(pid);
}
