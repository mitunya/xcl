;;; asm-x86-64.lisp
;;;
;;; Copyright (C) 2007-2009 Peter Graves <peter@armedbear.org>
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License
;;; as published by the Free Software Foundation; either version 2
;;; of the License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

(in-package "ASSEMBLER")

(defun emit-raw (x)
  (declare (optimize speed (safety 0)))
  (declare (type (integer #x-8000000 #xffffffff) x)) ; (OR (SIGNED-BYTE 32) (UNSIGNED-BYTE 32))
  (dotimes (i 4)
    (declare (type (integer 0 4) i)) ; REVIEW this should not be necessary!
    (vector-push-extend (ldb (byte 8 (* i 8)) x) *output*)))

(defun emit-raw-qword (x)
  (dotimes (i 8)
    (declare (type (integer 0 8) i)) ; REVIEW this should not be necessary!
    (vector-push-extend (ldb (byte 8 (* i 8)) x) *output*)
    ))

(define-assembler :add
  (cond ((and (fixnump operand1)
              (typep operand1 '(unsigned-byte 8))
              (eq operand2 :al))
         (emit-bytes #x04 operand1))
        ((and (reg64-p operand1) (not (extended-register-p operand1))
              (reg64-p operand2) (not (extended-register-p operand2)))
         (let* ((mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x48 #x01 modrm-byte)))
        ((and (fixnump operand1)
              (reg64-p operand2))
         (let* ((prefix-byte (if (extended-register-p operand2) #x49 #x48))
                (mod #b11)
                (reg 0)
                (rm (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (cond ((typep operand1 '(signed-byte 8))
                  (emit-bytes prefix-byte #x83 modrm-byte (ldb (byte 8 0) operand1)))
                 ((typep operand1 '(signed-byte 32))
                  (emit-bytes prefix-byte #x81 modrm-byte)
                  (emit-raw-dword operand1))
                 (t
                  (unsupported)))))
        (t
         (unsupported))))

(define-assembler :and
  (cond ((and (reg64-p operand1)
              (reg64-p operand2))
         (let* ((mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x48 #x21 modrm-byte)))
        ((and (typep operand1 '(signed-byte 32))
              (eq operand2 :rax))
         (emit-bytes #x48 #x25)
         (emit-raw operand1))
        ((and (typep operand1 '(unsigned-byte 8))
              (eq operand2 :al))
         (emit-bytes #x24 operand1))
        ((and (typep operand1 '(unsigned-byte 8))
              (reg8-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 4 (register-number operand2))))
           (when (memq operand2 '(:spl :bpl :sil :dil))
             (emit-byte #x40))
           (emit-bytes #x80 modrm-byte (ldb (byte 8 0) operand1))))
        ((and (typep operand1 '(signed-byte 8))
              (reg64-p operand2))
         (let* ((mod #b11)
                (reg 4)
                (rm (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x48 #x83 modrm-byte (ldb (byte 8 0) operand1))))
        ((and (typep operand1 '(signed-byte 8))
              (reg32-p operand2))
         (let* ((mod #b11)
                (reg 4)
                (rm (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x83 modrm-byte (ldb (byte 8 0) operand1))))
        (t
         (unsupported))))

(define-assembler :cmp
  (cond ((and (reg64-p operand1)
              (reg64-p operand2))
         (let* ((mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x48 #x39 modrm-byte)))
        ((and (typep operand1 '(unsigned-byte 8))
              (eq operand2 :al))
         (emit-bytes #x3c operand1))
        ((and (typep operand1 '(unsigned-byte 8))
              (reg8-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 7 (register-number operand2))))
           (when (memq operand2 '(:spl :bpl :sil :dil))
             (emit-byte #x40))
           (emit-bytes #x80 modrm-byte (ldb (byte 8 0) operand1))))
        ((and (typep operand1 '(signed-byte 8))
              (reg32-p operand2))
         (let* ((mod #b11)
                (reg 7)
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x83 modrm-byte (ldb (byte 8 0) operand1))))
        ((and (typep operand1 '(signed-byte 32))
              (eq operand2 :rax))
         (emit-bytes #x48 #x3d)
         (emit-raw operand1))
        ((and (typep operand1 '(signed-byte 32))
              (memq operand2 '(:rcx :rdx :rbx :rsp :rbp :rsi :rdi)))
         (let* ((mod #b11)
                (reg 7)
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x48 #x81 modrm-byte)
           (emit-raw-dword operand1)))
        (t
         (unsupported))))

(define-assembler :int3
  (emit-byte #xcc))

(define-assembler :leave
  (emit-byte #xc9))

(define-assembler :mov
  (cond ((and (reg64-p operand1)
              (reg64-p operand2))
         (let* ((prefix-byte #x48)
                (mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (when (extended-register-p operand1)
             (setq prefix-byte (logior prefix-byte rex.r)))
           (when (extended-register-p operand2)
             (setq prefix-byte (logior prefix-byte rex.b)))
           (emit-bytes prefix-byte #x89 modrm-byte)))
        ((and (reg32-p operand1)
              (reg32-p operand2))
         (let* ((mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x89 modrm-byte)))
        ((consp operand1)
         (cond ((and (length-eql operand1 1)
                     (reg64-p (%car operand1))
                     (reg64-p operand2))
                (let* ((reg1 (%car operand1))
                       (reg2 operand2)
                       (prefix-byte #x48)
                       (modrm-byte (make-modrm-byte #xb00
                                                    (register-number reg2)
                                                    (register-number reg1))))
                  (when (extended-register-p reg1)
                    (setq prefix-byte (logior prefix-byte rex.b)))
                  (when (extended-register-p reg2)
                    (setq prefix-byte (logior prefix-byte rex.r)))
                  (emit-bytes prefix-byte #x8b modrm-byte)))
               ((and (length-eql operand1 2)
                     (integerp (%car operand1))
                     (reg64-p (%cadr operand1))
                     (reg64-p operand2))
                (let ((displacement (first operand1))
                      (reg1 (second operand1))
                      (reg2 operand2)
                      (prefix-byte #x48))
                  (when (extended-register-p reg1)
                    (setq prefix-byte (logior prefix-byte rex.b)))
                  (when (extended-register-p reg2)
                    (setq prefix-byte (logior prefix-byte rex.r)))
                  (cond ((zerop displacement)
                         (let ((modrm-byte (make-modrm-byte #xb00
                                                            (register-number reg2)
                                                            (register-number reg1))))
                           (emit-bytes prefix-byte #x8b modrm-byte)))
                        ((typep displacement '(signed-byte 8))
                         (let* ((displacement-byte (ldb (byte 8 0) displacement))
                                (mod #b01)
                                (reg (register-number reg2))
                                (rm  (register-number reg1))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x8b modrm-byte)
                           ;; REVIEW
                           (when (eq reg1 :rsp)
                             (emit-byte #x24))
                           (emit-byte displacement-byte)))
                        (t
                         (let* ((mod #b10)
                                (reg (register-number reg2))
                                (rm  (register-number reg1))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x8b modrm-byte)
                           (emit-raw displacement))))))
               (t
                (unsupported))))
        ((consp operand2)
         (cond ((and (length-eql operand2 2)
                     (integerp (%car operand2))
                     (eq (%cadr operand2) :rsp)
                     (reg64-p operand1))
                (let ((reg1 operand1)
                      (displacement (%car operand2))
                      (reg2 :rsp)
                      (prefix-byte #x48))
                  (when (extended-register-p reg1)
                    (setq prefix-byte (logior prefix-byte rex.r)))
                  (cond ((zerop displacement)
                         (let* ((mod #xb00)
                                (reg (register-number reg1))
                                (rm  (register-number reg2))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x89 modrm-byte #x24)))
                        ((typep displacement '(signed-byte 8))
                         (let* ((mod #xb01)
                                (reg (register-number reg1))
                                (rm  (register-number reg2))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x89 modrm-byte #x24 (ldb (byte 8 0) displacement))))
                        (t
                         (let* ((mod #b10)
                                (reg (register-number reg1))
                                (rm  (register-number reg2))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x89 modrm-byte #x24)
                           (emit-raw displacement))))))
               ((and (length-eql operand2 2)
                     (integerp (%car operand2))
                     (reg64-p (%cadr operand2))
                     (reg64-p operand1))
                (let ((reg1 operand1)
                      (displacement (%car operand2))
                      (reg2 (%cadr operand2))
                      (prefix-byte #x48))
                  (when (extended-register-p reg1)
                    (setq prefix-byte (logior prefix-byte rex.r)))
                  (when (extended-register-p reg2)
                    (setq prefix-byte (logior prefix-byte rex.b)))
                  (cond ((zerop displacement)
                         (let* ((mod #b00)
                                (reg (register-number reg1))
                                (rm  (register-number reg2))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x89 modrm-byte)))
                        ((typep displacement '(signed-byte 8))
                         (let* ((displacement-byte (ldb (byte 8 0) displacement))
                                (mod #b01)
                                (reg (register-number reg1))
                                (rm  (register-number reg2))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x89 modrm-byte)
                           ;; REVIEW
                           (when (memq reg2 '(:rsp :r12))
                             (emit-byte #x24))
                           (emit-byte displacement-byte)))
                        (t
                         (let* ((mod #b10)
                                (reg (register-number reg1))
                                (rm  (register-number reg2))
                                (modrm-byte (make-modrm-byte mod reg rm)))
                           (emit-bytes prefix-byte #x89 modrm-byte)
                           (emit-raw displacement))))))
               ((and (length-eql operand2 1)
                     (eq (%car operand2) :rsp)
                     (eq operand1 :rax))
                ;; mov %rax,(%rsp)
                (emit-bytes #x48 #x89 #x04 #x24))
               ((and (length-eql operand2 1)
                     (reg64-p operand1)
                     (reg64-p (%car operand2)))
                (let* ((reg1 operand1)
                       (reg2 (%car operand2))
                       (modrm-byte (make-modrm-byte #xb00
                                                    (register-number reg1)
                                                    (register-number reg2)))
                       (prefix-byte #x48))
                  (when (extended-register-p reg1)
                    (setq prefix-byte (logior prefix-byte rex.r)))
                  (when (extended-register-p reg2)
                    (setq prefix-byte (logior prefix-byte rex.b)))
                  (emit-bytes prefix-byte #x89 modrm-byte)))
               ((and (length-eql operand2 1)
                     (reg64-p (%car operand2))
                     (reg8-p operand1))
                (let* ((reg1 operand1)
                       (reg2 (%car operand2))
                       (modrm-byte (make-modrm-byte #xb00
                                                    (register-number reg1)
                                                    (register-number reg2))))
                  (emit-bytes #x88 modrm-byte)))
               (t
                (unsupported))))
        ((and (integerp operand1)
              (typep operand1 '(signed-byte 32))
              (reg64-p operand2))
         (let* ((prefix-byte (if (extended-register-p operand2) #x49 #x48))
                (mod #b11)
                (reg 0)
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes prefix-byte #xc7 modrm-byte)
           (emit-raw-dword operand1)))
        ((and (integerp operand1)
              (typep operand1 '(unsigned-byte 64))
              (reg64-p operand2))
         (let* ((prefix-byte (if (extended-register-p operand2) #x49 #x48)))
           (emit-bytes prefix-byte (+ #xb8 (register-number operand2)))
           (emit-raw-qword operand1)))
        (t
         (unsupported))))

(define-assembler :movb
  (cond ((and (consp operand2)
              (length-eql operand2 2)
              (integerp (first operand2))
              (reg64-p (second operand2))
              (typep operand1 '(unsigned-byte 8)))
         (let ((displacement (first operand2))
               (reg2 (second operand2))
               (prefix-byte #x40))
           (when (extended-register-p reg2)
             (setq prefix-byte (logior prefix-byte rex.b)))
           ;; FIXME
           (if (eq reg2 :r12)
               (emit-bytes prefix-byte #xc6 #x44 #x24 displacement operand1)
               (unsupported))))
        (t
         (unsupported))))

(define-assembler :movq
  (cond ((and (consp operand2)
              (length-eql operand2 2)
              (integerp (first operand2))
              (reg64-p (second operand2))
              (typep operand1 '(signed-byte 32)))
         ;; e.g. movq $-1, 8(%rsp)
         (let* ((displacement (first operand2))
                (reg2 (second operand2))
                (prefix-byte (if (extended-register-p reg2) #x49 #x48)))
           (cond ((zerop displacement)
                  (let* ((mod #b00)
                         (reg 0)
                         (rm (register-number reg2))
                         (modrm-byte (make-modrm-byte mod reg rm)))
                    (emit-bytes prefix-byte #xc7 modrm-byte)
                    ;; REVIEW
                    (when (eq reg2 :rsp)
                      (emit-byte #x24))
                    (emit-raw-dword operand1)))
                 ((typep displacement '(signed-byte 8))
                  (let* ((displacement-byte (ldb (byte 8 0) displacement))
                         (mod #b01)
                         (reg 0)
                         (rm (register-number reg2))
                         (modrm-byte (make-modrm-byte mod reg rm)))
                    (emit-bytes prefix-byte #xc7 modrm-byte)
                    ;; REVIEW
                    (when (eq reg2 :rsp)
                      (emit-byte #x24))
                    (emit-byte displacement-byte)
                    (emit-raw-dword operand1)))
                 (t
                  (unsupported)))))
        ((and (consp operand2)
              (length-eql operand2 1)
              (reg64-p (%car operand2))
              (typep operand1 '(signed-byte 32)))
         ;; e.g. movq $-1, (%rsp)
         (let* ((reg2 (%car operand2))
                (prefix-byte (if (extended-register-p reg2) #x49 #x48))
                (mod #b00)
                (reg 0)
                (rm (register-number reg2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes prefix-byte #xc7 modrm-byte)
           ;; REVIEW
           (when (eq reg2 :rsp)
             (emit-byte #x24))
           (emit-raw-dword operand1)))
        (t
         (unsupported))))

(define-assembler :pop
  (cond ((extended-register-p operand1)
         (emit-byte #x41)
         (emit-byte (ecase operand1
                      (:r8  #x58)
                      (:r9  #x59)
                      (:r10 #x5a)
                      (:r11 #x5b)
                      (:r12 #x5c)
                      (:r13 #x5d)
                      (:r14 #x5e)
                      (:r15 #x5f))))
        ((reg64-p operand1)
         (emit-byte (ecase operand1
                      (:rax #x58)
                      (:rcx #x59)
                      (:rdx #x5a)
                      (:rbx #x5b)
                      (:rsp #x5c)
                      (:rbp #x5d)
                      (:rsi #x5e)
                      (:rdi #x5f))))
        (t
         (unsupported))))

(define-assembler :push
  (cond ((extended-register-p operand1)
         (emit-byte #x41)
         (emit-byte (ecase operand1
                      (:r8  #x50)
                      (:r9  #x51)
                      (:r10 #x52)
                      (:r11 #x53)
                      (:r12 #x54)
                      (:r13 #x55)
                      (:r14 #x56)
                      (:r15 #x57))))
        ((reg64-p operand1)
         (emit-byte (ecase operand1
                      (:rax #x50)
                      (:rcx #x51)
                      (:rdx #x52)
                      (:rbx #x53)
                      (:rsp #x54)
                      (:rbp #x55)
                      (:rsi #x56)
                      (:rdi #x57))))
        ((typep operand1 '(signed-byte 8))
         (emit-bytes #x6a (ldb (byte 8 0) operand1)))
        ((typep operand1 '(signed-byte 32))
         (emit-byte #x68)
         (emit-raw operand1))
        ((and (consp operand1)
              (typep (car operand1) '(signed-byte 8))
              (reg64-p (cadr operand1)))
         (let* ((mod #b01)
                (reg 6)
                (rm (register-number (cadr operand1)))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #xff modrm-byte (ldb (byte 8 0) (car operand1)))))
        ((and (consp operand1)
              (typep (car operand1) '(signed-byte 32))
              (reg64-p (cadr operand1)))
         (let* ((mod #b10)
                (reg 6)
                (rm (register-number (cadr operand1)))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #xff modrm-byte)
           (emit-raw (car operand1))))
        (t
         (unsupported))))

(define-assembler :ret
  (emit-byte #xc3))

(define-assembler :sar
  (when (and (reg64-p operand1)
             (null operand2))
    (setq operand2 operand1
          operand1 1))
  (cond ((and (eql operand1 1)
              (reg64-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 7 (register-number operand2))))
           (emit-bytes #x48 #xd1 modrm-byte)))
        ((and (typep operand1 '(unsigned-byte 8))
              (reg64-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 7 (register-number operand2))))
           (emit-bytes #x48 #xc1 modrm-byte operand1)))
        (t
         (unsupported))))

(define-assembler :shl
  (cond ((and (null operand2)
              (reg32-p operand1))
         (let ((modrm-byte (make-modrm-byte #b11 4 (register-number operand1))))
           (emit-bytes #xd1 modrm-byte)))
        ((and (eql operand1 1)
              (reg32-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 4 (register-number operand2))))
           (emit-bytes #xd1 modrm-byte)))
        ((and (reg64-p operand1)
              (null operand2))
         (let ((modrm-byte (make-modrm-byte #b11 4 (register-number operand1)))
               (prefix-byte #x48))
           (when (extended-register-p operand1)
             (setq prefix-byte (logior prefix-byte rex.b)))
           (emit-bytes prefix-byte #xd1 modrm-byte)))
        ((and (eql operand1 1)
              (reg64-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 4 (register-number operand2)))
               (prefix-byte #x48))
           (when (extended-register-p operand2)
             (setq prefix-byte (logior prefix-byte rex.b)))
           (emit-bytes prefix-byte #xd1 modrm-byte)))
        ((and (typep operand1 '(unsigned-byte 8))
              (reg64-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 4 (register-number operand2)))
               (prefix-byte #x48))
           (when (extended-register-p operand2)
             (setq prefix-byte (logior prefix-byte rex.b)))
           (emit-bytes prefix-byte #xc1 modrm-byte operand1)))
        (t
         (unsupported))))

(define-assembler :shr
  (when (and (null operand2)
             (or (reg32-p operand1)
                 (reg64-p operand1)))
    (setq operand2 operand1
          operand1 1))
  (cond ((eql operand1 1)
         (let ((modrm-byte (make-modrm-byte #b11 5 (register-number operand2))))
           (cond ((reg32-p operand2)
                  (emit-bytes #xd1 modrm-byte))
                 ((reg64-p operand2)
                  (let ((prefix-byte #x48))
                    (when (extended-register-p operand2)
                      (setq prefix-byte (logior prefix-byte rex.b)))
                    (emit-bytes prefix-byte #xd1 modrm-byte)))
                 (t
                  (unsupported)))))
        ((typep operand1 '(unsigned-byte 8)) ;; REVIEW 0-31 or 0-63
         (let ((modrm-byte (make-modrm-byte #b11 5 (register-number operand2))))
           (cond ((reg32-p operand2)
                  (emit-bytes #xc1 modrm-byte operand1))
                 ((reg64-p operand2)
                  (let ((prefix-byte #x48))
                    (when (extended-register-p operand2)
                      (setq prefix-byte (logior prefix-byte rex.b)))
                    (emit-bytes prefix-byte #xc1 modrm-byte operand1))))))
        (t
         (unsupported))))

(define-assembler :sub
  (cond ((and (fixnump operand1)
              (typep operand1 '(unsigned-byte 8))
              (eq operand2 :al))
         (emit-bytes #x2c operand1))
        ((and (fixnump operand1)
              (reg64-p operand2))
         (let ((prefix-byte (if (extended-register-p operand2) #x49 #x48)))
           (cond ((typep operand1 '(signed-byte 8))
                  (let ((modrm-byte (make-modrm-byte #b11 5 (register-number operand2))))
                    (emit-bytes prefix-byte #x83 modrm-byte (ldb (byte 8 0) operand1))))
                 ((typep operand1 '(signed-byte 32))
                  (let ((modrm-byte (make-modrm-byte #b11 5 (register-number operand2))))
                    (emit-bytes prefix-byte #x81 modrm-byte)
                    (emit-raw-dword operand1)))
                 (t
                  (unsupported)))))
        ((and (reg64-p operand1)
              (reg64-p operand2))
         (let* ((mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x48 #x29 modrm-byte)))
        (t
         (unsupported))))

(define-assembler :test
  (cond ((and (reg64-p operand1)
              (reg64-p operand2))
         (let* ((mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x48 #x85 modrm-byte)))
        ((and (reg8-p operand1)
              (reg8-p operand2))
         (let* ((mod #b11)
                (reg (register-number operand1))
                (rm  (register-number operand2))
                (modrm-byte (make-modrm-byte mod reg rm)))
           (emit-bytes #x84 modrm-byte)))
        ((and (typep operand1 '(unsigned-byte 8))
              (eq operand2 :al))
         (emit-bytes #xa8 operand1))
        ((and (typep operand1 '(unsigned-byte 8))
              (reg8-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 0 (register-number operand2))))
           (when (memq operand2 '(:spl :bpl :sil :dil))
             (emit-byte #x40))
           (emit-bytes #xf6 modrm-byte operand1)))
        ((and (typep operand1 '(unsigned-byte 32))
              (reg64-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 0 (register-number operand2))))
           (emit-bytes #x48 #xf7 modrm-byte))
         (emit-raw operand1))
        ((and (typep operand1 '(unsigned-byte 32))
              (reg32-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11 0 (register-number operand2))))
           (emit-bytes #xf7 modrm-byte))
         (emit-raw operand1))
        (t
         (unsupported))))

(define-assembler :xor
  (cond ((and (reg32-p operand1)
              (reg32-p operand2))
         (let ((modrm-byte (make-modrm-byte #b11
                                            (register-number operand1)
                                            (register-number operand2))))
           (emit-bytes #x31 modrm-byte)))
        (t
         (unsupported))))
