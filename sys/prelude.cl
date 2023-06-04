;;;; prelude.cl
(in-package #:pycl.sys)

;;; C typedefs
(def-foreign-type Py_ssize_t :nat)
(def-foreign-type Py_hash_t Py_ssize_t)
(def-foreign-type Py_UCS4 :unsigned-int)
(def-foreign-type Py_UCS2 :unsigned-short)
(def-foreign-type Py_UCS1 :unsigned-char)
(def-foreign-type PyCFunction (* :void))
(def-foreign-type PyCapsule_Destructor (* :void))
(def-foreign-type PyThread_type_lock (* :void))
(def-foreign-type PyOS_sighandler_t (* :void))

;;; C enums
(def-foreign-type PyLockStatus :int)
(defconstant +PY_LOCK_FAILURE+ 0)
(defconstant +PY_LOCK_ACQUIRED+ 1)
(defconstant +PY_LOCK_INTR+ 2)

(def-foreign-type PyGILState_STATE :int)
(defconstant +PyGILState_LOCKED+ 0)
(defconstant +PyGILState_UNLOCKED+ 1)

;;; C structs
(def-foreign-type PyObject
    (:struct
     (ob_refcnt Py_ssize_t)
     (ob_type (* :void))))

(def-foreign-type PyVarObject
    (:struct
     (ob_base PyObject)
     (ob_size Py_ssize_t)))

(def-foreign-type PyMethodDef
    (:struct
     (ml_name (* :char))
     (ml_meth PyCFunction)
     (ml_flags :int)
     (ml_doc (* :char))))

(def-foreign-type PyMemberDef
    (:struct
     (name (* :char))
     (type :int)
     (offset Py_ssize_t)
     (flags :int)
     (doc (* :char))))

(def-foreign-type PyGetSetDef
    (:struct
     (name (* :char))
     (get (* :void))
     (set (* :void))
     (doc (* :char))
     (closure (* :void))))

(def-foreign-type PyModuleDef_Base
    (:struct
     (ob_base PyObject)
     (m_init (* :void))
     (m_index Py_ssize_t)
     (m_copy (* PyObject))))

(def-foreign-type PyModuleDef_Slot
    (:struct
     (slot :int)
     (value (* :void))))

(def-foreign-type PyModuleDef
    (:struct
     (m_base PyModuleDef_Base)
     (m_name (* :char))
     (m_doc (* :char))
     (m_size Py_ssize_t)
     (m_methods (* PyMethodDef))
     (m_slots (* PyModuleDef_Slot))
     (m_traverse (* :void))
     (m_clear (* :void))
     (m_free (* :void))))

(def-foreign-type PyStructSequence_Field
    (:struct
     (name (* :char))
     (doc (* :char))))

(def-foreign-type PyStructSequence_Desc
    (:struct
     (name (* :char))
     (doc (* :char))
     (fields (* PyStructSequence_Field))
     (n_in_sequence :int)))

(def-foreign-type PyType_Slot
    (:struct
     (slot :int)
     (pfunc (* :void))))

(def-foreign-type PyType_Spec
    (:struct
     (name (* :char))
     (basicsize :int)
     (itemsize :int)
     (flags :unsigned-int)
     (slots (* PyType_Slot))))

;;; Lisp type definitions
(defclass pyptr (foreign-pointer)
  ()
  (:documentation "A dedicated type for a python foreign pointer e.g. PyObject*, PyModuleDef*"))

(defun make-pyptr (address &optional ctype)
  (declare (type (unsigned-byte #+32bit 32 #+64bit 64) address))
  (make-instance 'pyptr :foreign-type ctype
                        :foreign-address address))

(defmethod print-object ((fp pyptr) stream)
  (if* (= 0 (foreign-pointer-address fp))
     then (format stream "#<~a NULL>" (or (foreign-pointer-type fp) 'pyptr))
     else (let ((*print-base* 16))
            (format stream "#<~a @ #x~a>"
                    (or (foreign-pointer-type fp) 'pyptr)
                    (foreign-pointer-address fp)))))

(defclass pyobject (pyptr)
  ()
  (:documentation "Foreign pointer type for PyObject."))

(defmethod foreign-pointer-type ((fp pyobject)) 'PyObject)

(defvar-nonbindable *pynull*
    (make-instance 'pyobject :foreign-type 'PyObject
                             :foreign-address 0)
  "A singleton that represents a NULL PyObject pointer")

(defun foreign-python-funcall-converter/returning (action address ctype ltype)
  (declare (ignore ltype)
           (type (unsigned-byte #+32bit 32 #+64bit 64) address)
           (optimize (speed 3) (safety 0) (space 0)))
  (case action
    (:convert (if* (eq 'PyObject (second ctype))
                 then (if* (= 0 address)
                         then *pynull*
                         else (make-instance 'pyobject :foreign-type 'PyObject
                                                       :foreign-address address))
                 else (make-pyptr (second ctype) address)))
    (:convert-type 'integer)
    (:identify :return)
    (:allocate nil)
    (:will-allocate nil)))
