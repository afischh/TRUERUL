(in-package #:truerul-runtime)

(defstruct truerul-runtime-state
  (cycle 0 :type integer)
  (lang :ru :type keyword)
  (output-mode :verbose :type keyword)
  (entities (make-hash-table :test 'equal))
  (relations nil)
  (states nil)
  (log nil)
  (form-log nil)
  (command-history nil)
  (history-cursor 0 :type integer)
  (blocks (make-hash-table :test 'equal))
  (last-view nil))

(defun make-runtime ()
  (make-truerul-runtime-state))

(defun runtime-cycle (rt)
  (truerul-runtime-state-cycle rt))

(defun (setf runtime-cycle) (value rt)
  (setf (truerul-runtime-state-cycle rt) value))

(defun runtime-lang (rt)
  (truerul-runtime-state-lang rt))

(defun (setf runtime-lang) (value rt)
  (setf (truerul-runtime-state-lang rt) value))

(defun runtime-output-mode (rt)
  (truerul-runtime-state-output-mode rt))

(defun (setf runtime-output-mode) (value rt)
  (setf (truerul-runtime-state-output-mode rt) value))

(defun runtime-entities (rt)
  (truerul-runtime-state-entities rt))

(defun runtime-relations (rt)
  (truerul-runtime-state-relations rt))

(defun (setf runtime-relations) (value rt)
  (setf (truerul-runtime-state-relations rt) value))

(defun runtime-states (rt)
  (truerul-runtime-state-states rt))

(defun (setf runtime-states) (value rt)
  (setf (truerul-runtime-state-states rt) value))

(defun runtime-log (rt)
  (truerul-runtime-state-log rt))

(defun (setf runtime-log) (value rt)
  (setf (truerul-runtime-state-log rt) value))

(defun runtime-form-log (rt)
  (truerul-runtime-state-form-log rt))

(defun (setf runtime-form-log) (value rt)
  (setf (truerul-runtime-state-form-log rt) value))

(defun runtime-command-history (rt)
  (truerul-runtime-state-command-history rt))

(defun (setf runtime-command-history) (value rt)
  (setf (truerul-runtime-state-command-history rt) value))

(defun runtime-history-cursor (rt)
  (truerul-runtime-state-history-cursor rt))

(defun (setf runtime-history-cursor) (value rt)
  (setf (truerul-runtime-state-history-cursor rt) value))

(defun runtime-blocks (rt)
  (truerul-runtime-state-blocks rt))

(defun runtime-last-view (rt)
  (truerul-runtime-state-last-view rt))

(defun (setf runtime-last-view) (value rt)
  (setf (truerul-runtime-state-last-view rt) value))

(defun %plist-value (plist key &optional default)
  (loop for (k v) on plist by #'cddr
        when (eql k key) do (return v)
        finally (return default)))

(defun %plist-has-key (plist key)
  (loop for (k _) on plist by #'cddr
        when (eql k key) do (return t)
        finally (return nil)))

(defun %push-log (rt entry)
  (setf (runtime-log rt) (append (runtime-log rt) (list entry))))

(defun %push-form-log (rt form)
  (setf (runtime-form-log rt) (append (runtime-form-log rt) (list form))))

(defun %history-append (rt form)
  (let ((history (append (runtime-command-history rt) (list form))))
    (setf (runtime-command-history rt) history)
    (setf (runtime-history-cursor rt) (length history))))

(defun %history-prev (rt)
  (let ((history (runtime-command-history rt)))
    (when history
      (let ((cursor (runtime-history-cursor rt)))
        (when (> cursor 1)
          (setf (runtime-history-cursor rt) (1- cursor)))
        (nth (max 0 (1- (runtime-history-cursor rt))) history)))))

(defun %block-entries (rt)
  (let ((entries nil))
    (maphash (lambda (k v) (push (cons k v) entries)) (runtime-blocks rt))
    (sort entries #'string< :key #'car)))

(defun %atom-name (x)
  (cond
    ((null x) "nil")
    ((stringp x) x)
    ((symbolp x) (string-downcase (symbol-name x)))
    (t (string-downcase (princ-to-string x)))))

(defun %variable-name-p (x)
  (member (%atom-name x) '("x" "y" "z" "_") :test #'string=))

(defun %normalize-binding-key (x)
  (string-upcase (%atom-name x)))

(defun %print-form (form)
  (cond
    ((null form) "nil")
    ((listp form)
     (format nil "(~{~A~^ ~})" (mapcar #'%print-form form)))
    ((stringp form)
     (format nil "\"~A\"" form))
    ((symbolp form)
     (%atom-name form))
    (t (princ-to-string form))))
