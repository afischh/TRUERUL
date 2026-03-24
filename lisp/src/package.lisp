(defpackage #:truerul-runtime
  (:use #:cl)
  (:export
   #:make-runtime
   #:runtime-cycle
   #:runtime-lang
   #:runtime-entities
   #:runtime-relations
   #:runtime-states
   #:runtime-log
   #:runtime-form-log
   #:parse-truerul-form
   #:evaluate-form
   #:run-truerul-repl))

(in-package #:truerul-runtime)

(defun %lookup-entry (collection key)
  (find key collection
        :key (lambda (entry) (%atom-name (second entry)))
        :test #'string=))

(defun %library-figure (name)
  (%lookup-entry *truerul-figures* (%atom-name name)))

(defun %library-category (name)
  (%lookup-entry *truerul-categories* (%atom-name name)))

(defun %library-dichotomy (left right)
  (find-if (lambda (entry)
             (and (string= (%atom-name (second entry)) (%atom-name left))
                  (string= (%atom-name (third entry)) (%atom-name right))))
           *truerul-dichotomies*))

(defun %library-tension (left right)
  (find-if (lambda (entry)
             (and (string= (%atom-name (second entry)) (%atom-name left))
                  (string= (%atom-name (third entry)) (%atom-name right))))
           *truerul-tensions*))

(defun %library-quote-card (name)
  (%lookup-entry *truerul-quote-cards* (%atom-name name)))

(defun %library-help-note (target)
  (find-if (lambda (entry)
             (let ((value (%plist-value (cddr entry) :target)))
               (cond
                 ((listp value)
                  (some (lambda (x) (string= (%atom-name x) (%atom-name target))) value))
                 (t (string= (%atom-name value) (%atom-name target))))))
           *truerul-help-notes*))
