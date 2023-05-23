;;;; prelude.cl
(in-package #:cl-user)

(defpackage #:pycl.sys
  (:use #:cl
        #:excl)
  (:export #:+PY_LOCK_FAILURE+
           #:+PY_LOCK_ACQUIRED+
           #:+PY_LOCK_INTR+
           #:+PyGILState_LOCKED+
           #:+PyGILState_UNLOCKED+
           #:+libpython-foreign-pointers+))

(in-package #:pycl.sys)

(ff:def-foreign-type Py_ssize_t :nat)
(ff:def-foreign-type Py_hash_t Py_ssize_t)
(ff:def-foreign-type Py_UCS4 :unsigned-int)
(ff:def-foreign-type Py_UCS2 :unsigned-short)
(ff:def-foreign-type Py_UCS1 :unsigned-char)
(ff:def-foreign-type PyCFunction (* :void))
(ff:def-foreign-type PyCapsule_Destructor (* :void))
(ff:def-foreign-type PyThread_type_lock (* :void))
(ff:def-foreign-type PyOS_sighandler_t (* :void))

(ff:def-foreign-type PyLockStatus :int)
(defconstant +PY_LOCK_FAILURE+ 0)
(defconstant +PY_LOCK_ACQUIRED+ 1)
(defconstant +PY_LOCK_INTR+ 2)

(ff:def-foreign-type PyGILState_STATE :int)
(defconstant +PyGILState_LOCKED+ 0)
(defconstant +PyGILState_UNLOCKED+ 1)

(ff:def-foreign-type .PyObject.
    ;; a mirror of PyObject C struct (for non-debugging Python builds)
    ;; we will not directly access the slots
    ;; and it will only be used for type annotation
    (:struct
     (ob_refcnt Py_ssize_t)
     (ob_type (* :void))))

(defclass PyObject (ff:foreign-pointer)
  ())

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun convert-python-ff-call/arg (action val ctype ltype)
    "Convert a foreign pointer to the corresponding ALIGNED foreign address."
    (declare (ignore ctype ltype))
    (case action
      (:convert (ff:aligned-to-address (ff:foreign-pointer-address val)))
      (:convert-type 'integer)
      (:identify :arg)
      (:check (check-type val pyobject))))

  (defun convert-python-ff-call/ret (action val ctype ltype)
    "Convert a foriegn address to a foreign pointer."
    (declare (ignore ltype))
    (case action
      (:convert (make-instance (if (eq '.PyObject. (second ctype)) 'PyObject 'ff:foreign-pointer)
                               :foreign-address (ff:address-to-aligned val)))
      (:convert-type 'integer)
      (:identify :return)
      (:allocate nil)
      (:will-allocate nil))))
