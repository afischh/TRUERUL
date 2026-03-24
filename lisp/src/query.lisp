(in-package #:truerul-runtime)

(defun %binding-add (bindings key value)
  (let ((existing (assoc key bindings :test #'string=)))
    (cond
      ((null existing)
       (append bindings (list (cons key value))))
      ((string= (cdr existing) value)
       bindings)
      (t :fail))))

(defun %match-slot (pattern actual bindings)
  (let ((pname (%atom-name pattern))
        (avalue (%atom-name actual)))
    (cond
      ((string= pname "_") bindings)
      ((%variable-name-p pattern)
       (%binding-add bindings (%normalize-binding-key pattern) avalue))
      ((string= pname avalue) bindings)
      (t :fail))))

(defun query-relations (rt subject predicate object)
  (loop for rel in (runtime-relations rt)
        for bindings = nil
        for b1 = (%match-slot subject (getf rel :subject) bindings)
        unless (eq b1 :fail)
          append
          (let ((b2 (%match-slot predicate (getf rel :predicate) b1)))
            (if (eq b2 :fail)
                nil
                (let ((b3 (%match-slot object (getf rel :object) b2)))
                  (if (eq b3 :fail) nil (list b3)))))))

(defun query-entities (rt id kind)
  (loop for entity being the hash-values of (runtime-entities rt)
        for bindings = nil
        for b1 = (%match-slot id (getf entity :id) bindings)
        unless (eq b1 :fail)
          append
          (let ((b2 (%match-slot kind (getf entity :kind) b1)))
            (if (eq b2 :fail) nil (list b2)))))

(defun query-states (rt target state)
  (loop for st in (runtime-states rt)
        for bindings = nil
        for b1 = (%match-slot target (getf st :target) bindings)
        unless (eq b1 :fail)
          append
          (let ((b2 (%match-slot state (getf st :state) b1)))
            (if (eq b2 :fail) nil (list b2)))))
