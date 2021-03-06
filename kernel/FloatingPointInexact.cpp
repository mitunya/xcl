// FloatingPointInexact.cpp
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

#include "lisp.hpp"
#include "FloatingPointInexact.hpp"

bool FloatingPointInexact::typep(Value type) const
{
  if (symbolp(type))
    return (type == S_floating_point_inexact || type == S_arithmetic_error
            || type == S_error || type == S_serious_condition || type == S_condition
            || type == S_standard_object || type == S_atom || type == T);
  else
    return (type == C_floating_point_inexact || type == C_arithmetic_error
            || type == C_error || type == C_serious_condition || type == C_condition
            || type == C_standard_object || type == T);
}
