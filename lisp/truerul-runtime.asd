(asdf:defsystem #:truerul-runtime
  :description "Truerul Lisp heart L1"
  :author "Alexey"
  :license "TBD"
  :serial t
  :components ((:file "src/package")
               (:file "src/runtime-state")
               (:file "library/figures")
               (:file "library/categories")
               (:file "library/dichotomies")
               (:file "library/tensions")
               (:file "library/quote-cards")
               (:file "library/help-notes")
               (:file "src/query")
               (:file "src/views")
               (:file "src/evaluator")
               (:file "src/reader")
               (:file "src/repl")))
