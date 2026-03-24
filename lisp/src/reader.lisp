(in-package #:truerul-runtime)

(defun parse-truerul-form (line)
  (let ((*package* (find-package '#:truerul-runtime)))
    (handler-case
        (values (read-from-string line))
      (error (e)
        (error "reader error: ~A" e)))))
