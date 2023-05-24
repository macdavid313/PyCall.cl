;;;; conversion.cl
(in-package #:pycl.sys)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun convert-python-ff-call/arg (action ptr ctype ltype)
    "Convert a foreign pointer to the corresponding foreign address."
    (declare (ignore ctype ltype)
             (type foreign-pointer ptr)
             (optimize (speed 3) (safety 0) (space 0)))
    (case action
      (:convert (foreign-pointer-address ptr))
      (:convert-type 'integer)
      (:identify :arg)
      (:check t)))

  (defun convert-python-ff-call/ret (action address ctype ltype)
    "Convert a foriegn address to a foreign pointer."
    (declare (ignore ltype)
             (type #+32bit (unsigned-byte 32) #+64bit (unsigned-byte 64) address)
             (optimize (speed 3) (safety 0) (space 0)))
    (case action
      (:convert (make-foreign-pointer :foreign-address address
                                      :foreign-type (if (listp ctype) (second ctype) ctype)))
      (:convert-type 'integer)
      (:identify :return)
      (:allocate nil)
      (:will-allocate nil))))