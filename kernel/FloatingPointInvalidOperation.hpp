// FloatingPointInvalidOperation.hpp
//
// Copyright (C) 2006-2007 Peter Graves <peter@armedbear.org>
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

#ifndef __FLOATING_POINT_INVALID_OPERATION_HPP
#define __FLOATING_POINT_INVALID_OPERATION_HPP

#include "ArithmeticError.hpp"

class FloatingPointInvalidOperation : public ArithmeticError
{
public:
  FloatingPointInvalidOperation()
    : ArithmeticError() 
  {
  }
  
  virtual Value type_of() const
  {
    return S_floating_point_invalid_operation;
  }

  virtual Value class_of() const
  {
    return C_floating_point_invalid_operation;
  }

  virtual bool typep(Value type) const;
};

#endif // FloatingPointInvalidOperation.hpp
