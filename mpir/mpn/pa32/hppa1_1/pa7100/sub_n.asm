dnl  HP-PA mpn_sub_n -- Subtract two limb vectors of the same length > 0 and
dnl  store difference in a third limb vector.  Optimized for the PA7100, where
dnl  is runs at 4.25 cycles/limb.

dnl  Copyright 1992, 1994, 2000, 2001, 2002, 2003 Free Software Foundation,
dnl  Inc.

dnl  This file is part of the GNU MP Library.

dnl  The GNU MP Library is free software; you can redistribute it and/or modify
dnl  it under the terms of the GNU Lesser General Public License as published
dnl  by the Free Software Foundation; either version 2.1 of the License, or (at
dnl  your option) any later version.

dnl  The GNU MP Library is distributed in the hope that it will be useful, but
dnl  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
dnl  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
dnl  License for more details.

dnl  You should have received a copy of the GNU Lesser General Public License
dnl  along with the GNU MP Library; see the file COPYING.LIB.  If not, write
dnl  to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
dnl  Boston, MA 02110-1301, USA.

include(`../config.m4')

C INPUT PARAMETERS
C res_ptr	r26
C s1_ptr	r25
C s2_ptr	r24
C size		r23

ASM_START()
PROLOGUE(mpn_sub_n)
	ldws,ma		4(0,%r25),%r20
	ldws,ma		4(0,%r24),%r19

	addib,<=	-5,%r23,L(rest)
	 sub		%r20,%r19,%r28	C subtract first limbs ignoring cy

LDEF(loop)
	ldws,ma		4(0,%r25),%r20
	ldws,ma		4(0,%r24),%r19
	stws,ma		%r28,4(0,%r26)
	subb		%r20,%r19,%r28
	ldws,ma		4(0,%r25),%r20
	ldws,ma		4(0,%r24),%r19
	stws,ma		%r28,4(0,%r26)
	subb		%r20,%r19,%r28
	ldws,ma		4(0,%r25),%r20
	ldws,ma		4(0,%r24),%r19
	stws,ma		%r28,4(0,%r26)
	subb		%r20,%r19,%r28
	ldws,ma		4(0,%r25),%r20
	ldws,ma		4(0,%r24),%r19
	stws,ma		%r28,4(0,%r26)
	addib,>		-4,%r23,L(loop)
	subb		%r20,%r19,%r28

LDEF(rest)
	addib,=		4,%r23,L(end)
	nop

LDEF(eloop)
	ldws,ma		4(0,%r25),%r20
	ldws,ma		4(0,%r24),%r19
	stws,ma		%r28,4(0,%r26)
	addib,>		-1,%r23,L(eloop)
	subb		%r20,%r19,%r28

LDEF(end)
	stws		%r28,0(0,%r26)
	addc		%r0,%r0,%r28
	bv		0(%r2)
	 subi		1,%r28,%r28
EPILOGUE()
