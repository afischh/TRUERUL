(in-package #:truerul-runtime)

(defparameter *truerul-lib-root* "/srv/truerul/lisp/libs/")
(defparameter *truerul-lib-families* '("logic" "foundations"))
(defparameter *truerul-lib-required-fields*
  '(:id :name :family :domain :strictness :logic-mode :ontology-mode :maturity
    :input-kinds :output-kinds :operators :automata :requires :notes))

(defun %safe-parse-integer (value &optional (default 1))
  (handler-case
      (cond
        ((integerp value) value)
        ((numberp value) (truncate value))
        ((null value) default)
        (t (parse-integer (%value->text value))))
    (error () default)))

(defun %replace-all (source needle replacement)
  (let ((text (or source "")))
    (if (or (null needle) (string= needle ""))
        text
        (with-output-to-string (out)
          (loop with start = 0
                for pos = (search needle text :start2 start)
                do (if pos
                       (progn
                         (write-string text out :start start :end pos)
                         (write-string replacement out)
                         (setf start (+ pos (length needle))))
                       (progn
                         (write-string text out :start start)
                         (return))))))))

(defun %shell-quote (text)
  (with-output-to-string (out)
    (write-char #\' out)
    (loop for ch across (or text "") do
      (if (char= ch #\')
          (write-string "'\\''" out)
          (write-char ch out)))
    (write-char #\' out)))

(defun %split-lines (text)
  (let ((raw (or text "")))
    (loop with start = 0
          for pos = (position #\Newline raw :start start)
          collect (string-trim '(#\Space #\Tab #\Return #\Newline)
                               (subseq raw start (or pos (length raw))))
          while pos
          do (setf start (1+ pos)))))

(defun %clean-lines (lines)
  (remove-if #'(lambda (x) (string= x "")) (or lines '())))

(defun %lib-files ()
  (let ((files nil))
    (dolist (family *truerul-lib-families*)
      (let ((pattern (pathname (format nil "~A~A/*.lib" *truerul-lib-root* family))))
        (setf files (append files (directory pattern)))))
    (sort files #'string< :key #'namestring)))

(defun %lib-has-required-fields-p (lib)
  (every (lambda (key) (not (null (getf lib key)))) *truerul-lib-required-fields*))

(defun %lib-normalize-plist (lib path)
  (let* ((copy (append lib nil))
         (id (%value->text (getf copy :id)))
         (cost (%safe-parse-integer (getf copy :cost) 1)))
    (setf (getf copy :id) id)
    (setf (getf copy :path) (namestring path))
    (setf (getf copy :cost) cost)
    (setf (getf copy :valid-p) (%lib-has-required-fields-p copy))
    copy))

(defun %read-lib-file (path)
  (handler-case
      (with-open-file (stream path :direction :input)
        (let ((form (read stream nil nil)))
          (when form
            (%lib-normalize-plist form path))))
    (error (e)
      (list :id (namestring path)
            :name (format nil "invalid lib: ~A" (file-namestring path))
            :family "invalid"
            :domain "invalid"
            :strictness "heuristic"
            :logic-mode "dynamic-epistemic"
            :ontology-mode "mixed"
            :maturity "experimental"
            :input-kinds '()
            :output-kinds '()
            :operators '()
            :automata '()
            :requires '()
            :notes (list (format nil "read error: ~A" e))
            :path (namestring path)
            :cost 99
            :valid-p nil))))

(defun %lib-index-runtime (rt &key (force nil))
  (when (or force (null (runtime-lib-indexed-at rt)))
    (clrhash (runtime-lib-registry rt))
    (let ((libs nil))
      (dolist (path (%lib-files))
        (let ((lib (%read-lib-file path)))
          (when lib
            (push lib libs)
            (setf (gethash (getf lib :id) (runtime-lib-registry rt)) lib))))
      (setf (runtime-lib-list rt)
            (sort libs #'string< :key (lambda (lib) (%value->text (getf lib :id)))))
      (setf (runtime-lib-indexed-at rt) (%timestamp-string))))
  (runtime-lib-list rt))

(defun %lib-axis-value (lib axis)
  (case axis
    (:domain (%value->text (getf lib :domain)))
    (:strictness (%value->text (getf lib :strictness)))
    (:logic-mode (%value->text (getf lib :logic-mode)))
    (:ontology-mode (%value->text (getf lib :ontology-mode)))
    (:maturity (%value->text (getf lib :maturity)))
    (:input-kind (%normalize-string-list (getf lib :input-kinds)))
    (:output-kind (%normalize-string-list (getf lib :output-kinds)))
    (:cost (%safe-parse-integer (getf lib :cost) 1))
    (otherwise nil)))

(defun %lib-match-axis-p (lib axis value)
  (let* ((want (%value->text value))
         (libv (%lib-axis-value lib axis)))
    (cond
      ((or (null value) (string= want "")) t)
      ((member axis '(:input-kind :output-kind))
       (member want libv :test #'string=))
      ((eql axis :cost)
       (<= (or libv 1) (%safe-parse-integer value 1)))
      (t
       (string= (%value->text libv) want)))))

(defun %lib-matches-filters-p (lib filters)
  (and (%lib-match-axis-p lib :domain (getf filters :domain))
       (%lib-match-axis-p lib :strictness (getf filters :strictness))
       (%lib-match-axis-p lib :logic-mode (getf filters :logic-mode))
       (%lib-match-axis-p lib :ontology-mode (getf filters :ontology-mode))
       (%lib-match-axis-p lib :maturity (getf filters :maturity))
       (%lib-match-axis-p lib :input-kind (getf filters :input-kind))
       (%lib-match-axis-p lib :output-kind (getf filters :output-kind))
       (%lib-match-axis-p lib :cost (getf filters :cost))))

(defun %maturity-score (value)
  (let ((name (%value->text value)))
    (cond
      ((member name '("stable" "production") :test #'string=) 3)
      ((member name '("beta" "growing") :test #'string=) 2)
      (t 1))))

(defun %lib-score (lib filters)
  (+ (if (%lib-match-axis-p lib :domain (getf filters :domain)) 2 0)
     (if (%lib-match-axis-p lib :logic-mode (getf filters :logic-mode)) 2 0)
     (if (%lib-match-axis-p lib :ontology-mode (getf filters :ontology-mode)) 2 0)
     (if (%lib-match-axis-p lib :strictness (getf filters :strictness)) 1 0)
     (if (%lib-match-axis-p lib :input-kind (getf filters :input-kind)) 1 0)
     (if (%lib-match-axis-p lib :output-kind (getf filters :output-kind)) 1 0)
     (%maturity-score (getf lib :maturity))
     (- 5 (%safe-parse-integer (getf lib :cost) 1))))

(defun %lib-filter-runtime (rt filters &key (force-index nil))
  (let ((libs (%lib-index-runtime rt :force force-index)))
    (remove-if-not (lambda (lib) (%lib-matches-filters-p lib filters)) libs)))

(defun %lib-route-runtime (rt filters &key (force-index nil))
  (let ((candidates (%lib-filter-runtime rt filters :force-index force-index)))
    (sort (mapcar (lambda (lib)
                    (list :lib lib :score (%lib-score lib filters)))
                  candidates)
          #'>
          :key (lambda (entry) (getf entry :score)))))

(defun %assist-detect-logic-mode (text)
  (let ((t0 (string-downcase (or text ""))))
    (cond
      ((or (search "противореч" t0) (search "both true" t0) (search "оба истин" t0)) "paraconsistent")
      ((or (search "тип" t0) (search "mltt" t0) (search "judgement" t0)) "many-valued")
      ((or (search "нечет" t0) (search "fuzzy" t0) (search "степен" t0)) "fuzzy")
      ((or (search "унивалент" t0) (search "equivalence" t0) (search "эквивалент" t0)) "classical")
      ((or (search "динамик" t0) (search "эпистем" t0)) "dynamic-epistemic")
      (t "classical"))))

(defun %assist-detect-domain (text)
  (let ((t0 (string-downcase (or text ""))))
    (cond
      ((or (search "тип" t0) (search "mltt" t0) (search "uf" t0) (search "фунда" t0)) "foundations")
      ((or (search "логик" t0) (search "truth" t0) (search "истин" t0)) "logic")
      ((or (search "код" t0) (search "program" t0)) "code")
      (t "logic"))))

(defun %assist-detect-ontology-mode (text)
  (let ((t0 (string-downcase (or text ""))))
    (cond
      ((search "type" t0) "type")
      ((search "тип" t0) "type")
      ((search "категор" t0) "category")
      ((search "topos" t0) "topos")
      (t "mixed"))))

(defun %assist-detect-input-kind (text)
  (let ((t0 (string-downcase (or text ""))))
    (cond
      ((search "противореч" t0) "conflict-report")
      ((or (search "тип" t0) (search "judgement" t0)) "type-judgement")
      ((or (search "запрос" t0) (search "провер" t0) (search "?" t0)) "query")
      ((or (search "если" t0) (search "then" t0) (search "следует" t0)) "rule")
      (t "proposition"))))

(defun %assist-detect-output-kind (text)
  (let ((t0 (string-downcase (or text ""))))
    (cond
      ((search "противореч" t0) "diagnosis")
      ((or (search "диагноз" t0) (search "класс" t0)) "diagnosis")
      ((or (search "гипотез" t0) (search "draft" t0)) "hypothesis")
      (t "truth-class"))))

(defun %assist-normalized-forms (text)
  (let ((t0 (string-downcase (or text ""))))
    (cond
      ((search "связ" t0)
       (list "(запрос (связь? субъект отношение X))"))
      ((search "сущност" t0)
       (list "(запрос (сущность? имя :тип _))"))
      ((search "состоян" t0)
       (list "(запрос (состояние? цель X))"))
      ((or (search "если" t0) (search "следует" t0))
       (list "(связь предпосылка следует-из вывод)"
             "(запрос (связь? предпосылка следует-из X))"))
      (t
       (list "(запрос (связь? субъект отношение X))")))))

(defun %voice-assist-profile (rt)
  (let ((voice (%normalize-voice-name (runtime-active-voice rt))))
    (cond
      ((string= voice "предел") "diagnosis/classification")
      ((string= voice "сборка") "normalization/construction")
      (t "hypothesis-draft"))))

(defun %assist-role-default (rt role)
  (or role (%voice-assist-profile rt) "parse-assist"))

(defun %assist-llm-command ()
  (or (sb-ext:posix-getenv "TRUERUL_ASSIST_CMD")
      ""))

(defun %assist-llm-enabled-p ()
  (> (length (%assist-llm-command)) 0))

(defun %assist-llm-lines (text role)
  (let ((template (%assist-llm-command)))
    (if (string= template "")
        nil
        (let* ((cmd0 (%replace-all template "{{input}}" (%shell-quote (or text ""))))
               (cmd1 (%replace-all cmd0 "{{role}}" (%shell-quote (or role "parse-assist"))))
               (output (with-output-to-string (out)
                         (handler-case
                             (sb-ext:run-program "/bin/sh"
                                                 (list "-lc" cmd1)
                                                 :search t
                                                 :output out
                                                 :error out
                                                 :wait t)
                           (error (e)
                             (format out "assist-cmd-error: ~A" e))))))
          (%clean-lines (%split-lines output))))))

(defun %assist-runtime (rt text &key role)
  (let* ((role0 (%assist-role-default rt role))
         (logic-mode (%assist-detect-logic-mode text))
         (domain (%assist-detect-domain text))
         (ontology-mode (%assist-detect-ontology-mode text))
         (input-kind (%assist-detect-input-kind text))
         (output-kind (%assist-detect-output-kind text))
         (forms (%assist-normalized-forms text))
         (llm-lines (%assist-llm-lines text role0))
         (hypothesis (if llm-lines
                         (first llm-lines)
                         (format nil "черновая гипотеза: использовать ~A/~A" domain logic-mode))))
    (list :role role0
          :provider (if (%assist-llm-enabled-p) "llm-cmd+heuristic" "heuristic")
          :normalized-forms forms
          :filter-hints (list :domain domain
                              :logic-mode logic-mode
                              :ontology-mode ontology-mode
                              :input-kind input-kind
                              :output-kind output-kind)
          :hypothesis hypothesis
          :llm-lines llm-lines)))

(defun %merge-filter-plists (a b)
  (let ((result (append a nil)))
    (loop for (k v) on b by #'cddr do
      (when (and v (not (string= (%value->text v) "")))
        (setf (getf result k) v)))
    result))

(defun %classification-from-text (text logic-mode strictness ontology-mode)
  (let ((t0 (string-downcase (or text ""))))
    (cond
      ((or (search "лож" t0) (search "опроверг" t0)) "ложь")
      ((or (search "истин" t0) (search "доказ" t0)) "истина")
      ((or (search "неопредел" t0) (search "unknown" t0)) "неопределённо")
      ((or (search "гипотез" t0) (search "предполож" t0)) "требует-новой-гипотезы")
      ((and (search "онтолог" t0)
            (not (or (search ontology-mode t0) (string= ontology-mode "mixed"))))
       "несовместимо-с-онтологией")
      ((member logic-mode '("fuzzy" "paraconsistent" "many-valued" "dynamic-epistemic") :test #'string=)
       (format nil "возможно-в-режиме-~A" logic-mode))
      ((string= strictness "strict")
       "неопределённо")
      (t
       "возможно"))))

(defun %operator-pipeline-runtime (rt operator-input filters)
  (let* ((assist (%assist-runtime rt operator-input :role "parse-assist"))
         (merged-filters (%merge-filter-plists
                          (append (getf assist :filter-hints) nil)
                          filters))
         (route (%lib-route-runtime rt merged-filters))
         (selected (and route (getf (first route) :lib))))
    (if (null selected)
        (list :class "требует-новой-гипотезы"
              :reason "подходящая .lib не найдена после фильтрации"
              :assist assist
              :filters merged-filters
              :route route
              :selected-lib nil)
        (let* ((logic-mode (%value->text (getf selected :logic-mode)))
               (strictness (%value->text (getf selected :strictness)))
               (ontology-mode (%value->text (getf selected :ontology-mode)))
               (classification (%classification-from-text operator-input logic-mode strictness ontology-mode)))
          (list :class classification
                :reason (format nil "выбран .lib ~A (logic=~A, strict=~A)"
                                (getf selected :id)
                                logic-mode
                                strictness)
                :assist assist
                :filters merged-filters
                :route route
                :selected-lib selected)))))

(defun %lib-one-line (lib)
  (format nil "~A | domain=~A logic=~A strict=~A onto=~A maturity=~A cost=~A"
          (getf lib :id)
          (getf lib :domain)
          (getf lib :logic-mode)
          (getf lib :strictness)
          (getf lib :ontology-mode)
          (getf lib :maturity)
          (getf lib :cost)))

(defun %lib-list-view (libs title)
  (list :title title
        :lines (if libs
                   (loop for lib in libs collect (%lib-one-line lib))
                   (list "нет библиотек по выбранным фильтрам"))))

(defun %lib-route-view (route title)
  (list :title title
        :lines (if route
                   (loop for entry in route
                         for index from 1
                         collect (format nil "~D) score=~D :: ~A"
                                         index
                                         (getf entry :score)
                                         (%lib-one-line (getf entry :lib))))
                   (list "маршрут пуст: фильтры не дали совпадений"))))

(defun %assist-view (assist title)
  (let ((lines (list (format nil "role: ~A" (getf assist :role))
                     (format nil "provider: ~A" (getf assist :provider))
                     (format nil "hypothesis: ~A" (getf assist :hypothesis))
                     ""
                     "normalized forms:"
                     (format nil "  ~{~A~^~%  ~}" (getf assist :normalized-forms))
                     ""
                     "filter hints:"
                     (format nil "  ~S" (getf assist :filter-hints)))))
    (when (getf assist :llm-lines)
      (setf lines (append lines (list "" "llm lines:") (mapcar (lambda (x) (format nil "  ~A" x))
                                                               (getf assist :llm-lines)))))
    (list :title title :lines lines)))
