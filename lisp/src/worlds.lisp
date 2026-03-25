(in-package #:truerul-runtime)

(defparameter *truerul-output-classes*
  '("истина"
    "ложь"
    "неопределённо"
    "возможно"
    "возможно-в-режиме-X"
    "несовместимо-с-онтологией"
    "требует-новой-гипотезы"
    "диагноз"
    "конструкция"
    "кандидат"))

(defun %world-normalize-name (name)
  (%atom-name name))

(defun %plist-copy (plist)
  (append plist nil))

(defun %world-mode-value (world key fallback)
  (%value->text (or (getf world key) fallback)))

(defun %runtime-entity-list (rt)
  (let ((items nil))
    (maphash (lambda (_k entity)
               (declare (ignore _k))
               (push (%plist-copy entity) items))
             (runtime-entities rt))
    (sort items #'string< :key (lambda (entry) (%value->text (getf entry :id))))))

(defun %runtime-relation-list (rt)
  (sort (mapcar #'%plist-copy (runtime-relations rt))
        #'string<
        :key (lambda (rel)
               (format nil "~A|~A|~A"
                       (%value->text (getf rel :subject))
                       (%value->text (getf rel :predicate))
                       (%value->text (getf rel :object))))))

(defun %runtime-state-list (rt)
  (sort (mapcar #'%plist-copy (runtime-states rt))
        #'string<
        :key (lambda (st)
               (format nil "~A|~A"
                       (%value->text (getf st :target))
                       (%value->text (getf st :state))))))

(defun %make-world-object (rt name &key source)
  (list :name (%world-normalize-name name)
        :entities (%runtime-entity-list rt)
        :relations (%runtime-relation-list rt)
        :states (%runtime-state-list rt)
        :logic-mode (%atom-name (runtime-logic-mode rt))
        :ontology-mode (%atom-name (runtime-ontology-mode rt))
        :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
        :source (%value->text (or source "runtime"))
        :created-at (%timestamp-string)))

(defun %store-world (rt world)
  (let ((name (%world-normalize-name (getf world :name))))
    (setf (getf world :name) name)
    (setf (gethash name (runtime-worlds rt)) world)
    world))

(defun %world-fetch (rt name)
  (and name
       (gethash (%world-normalize-name name) (runtime-worlds rt))))

(defun %world-entries (rt)
  (let ((items nil))
    (maphash (lambda (name world)
               (push (cons name world) items))
             (runtime-worlds rt))
    (sort items #'string< :key #'car)))

(defun %active-world-name (rt)
  (%world-normalize-name (or (runtime-active-world rt) "основной")))

(defun %ensure-active-world (rt)
  (or (%world-fetch rt (%active-world-name rt))
      (%store-world rt (%make-world-object rt (%active-world-name rt) :source "ensure-active"))))

(defun %sync-active-world-from-runtime (rt &key (source "runtime-sync"))
  (%store-world rt (%make-world-object rt (%active-world-name rt) :source source)))

(defun %world-entities-index (world)
  (let ((idx (make-hash-table :test 'equal)))
    (dolist (entity (or (getf world :entities) '()))
      (setf (gethash (%value->text (getf entity :id)) idx) entity))
    idx))

(defun %world-relations-keyset (world)
  (let ((idx (make-hash-table :test 'equal)))
    (dolist (rel (or (getf world :relations) '()))
      (setf (gethash (format nil "~A|~A|~A"
                             (%value->text (getf rel :subject))
                             (%value->text (getf rel :predicate))
                             (%value->text (getf rel :object)))
                     idx)
            rel))
    idx))

(defun %world-states-keyset (world)
  (let ((idx (make-hash-table :test 'equal)))
    (dolist (st (or (getf world :states) '()))
      (setf (gethash (format nil "~A|~A"
                             (%value->text (getf st :target))
                             (%value->text (getf st :state)))
                     idx)
            st))
    idx))

(defun %world-target-state-index (world)
  (let ((idx (make-hash-table :test 'equal)))
    (dolist (st (or (getf world :states) '()))
      (let ((target (%value->text (getf st :target)))
            (state (%value->text (getf st :state))))
        (push state (gethash target idx))))
    idx))

(defun %hash-keys (table)
  (let ((keys nil))
    (maphash (lambda (k _v)
               (declare (ignore _v))
               (push k keys))
             table)
    (sort keys #'string<)))

(defun %world-mode-compatible-p (rt world-a world-b)
  (let ((runtime-onto (%atom-name (runtime-ontology-mode rt)))
        (a-onto (%world-mode-value world-a :ontology-mode "mixed"))
        (b-onto (%world-mode-value world-b :ontology-mode "mixed")))
    (or (string= runtime-onto "mixed")
        (string= a-onto "mixed")
        (string= b-onto "mixed")
        (and (string= runtime-onto a-onto)
             (string= runtime-onto b-onto)))))

(defun %world-compare (world-a world-b)
  (let* ((ea (%world-entities-index world-a))
         (eb (%world-entities-index world-b))
         (ra (%world-relations-keyset world-a))
         (rb (%world-relations-keyset world-b))
         (sa (%world-states-keyset world-a))
         (sb (%world-states-keyset world-b))
         (ta (%world-target-state-index world-a))
         (tb (%world-target-state-index world-b))
         (entity-only-a nil)
         (entity-only-b nil)
         (entity-shared nil)
         (entity-conflicts nil)
         (relation-only-a nil)
         (relation-only-b nil)
         (relation-shared nil)
         (state-only-a nil)
         (state-only-b nil)
         (state-shared nil)
         (state-conflicts nil))

    (dolist (id (%hash-keys ea))
      (let ((a-val (gethash id ea))
            (b-val (gethash id eb)))
        (cond
          ((null b-val) (push id entity-only-a))
          ((equal a-val b-val) (push id entity-shared))
          (t (push (format nil "~A: A=~A / B=~A"
                           id
                           (%value->text (getf a-val :kind))
                           (%value->text (getf b-val :kind)))
                   entity-conflicts)))))

    (dolist (id (%hash-keys eb))
      (unless (gethash id ea)
        (push id entity-only-b)))

    (dolist (key (%hash-keys ra))
      (if (gethash key rb)
          (push key relation-shared)
          (push key relation-only-a)))

    (dolist (key (%hash-keys rb))
      (unless (gethash key ra)
        (push key relation-only-b)))

    (dolist (key (%hash-keys sa))
      (if (gethash key sb)
          (push key state-shared)
          (push key state-only-a)))

    (dolist (key (%hash-keys sb))
      (unless (gethash key sa)
        (push key state-only-b)))

    (dolist (target (%hash-keys ta))
      (let ((a-states (sort (copy-list (gethash target ta)) #'string<))
            (b-states (sort (copy-list (gethash target tb)) #'string<)))
        (when (and b-states (not (equal a-states b-states)))
          (push (format nil "~A: A=~{~A~^,~} / B=~{~A~^,~}" target a-states b-states)
                state-conflicts))))

    (list :entity-only-a (nreverse entity-only-a)
          :entity-only-b (nreverse entity-only-b)
          :entity-shared (nreverse entity-shared)
          :entity-conflicts (nreverse entity-conflicts)
          :relation-only-a (nreverse relation-only-a)
          :relation-only-b (nreverse relation-only-b)
          :relation-shared (nreverse relation-shared)
          :state-only-a (nreverse state-only-a)
          :state-only-b (nreverse state-only-b)
          :state-shared (nreverse state-shared)
          :state-conflicts (nreverse state-conflicts))))

(defun %world-merge (rt world-a world-b result-name)
  (let* ((merged-entities (make-hash-table :test 'equal))
         (entity-conflicts nil)
         (merged-relations (make-hash-table :test 'equal))
         (merged-states (make-hash-table :test 'equal))
         (state-conflicts nil)
         (logic-mode (%atom-name (runtime-logic-mode rt))))
    (dolist (entity (or (getf world-a :entities) '()))
      (setf (gethash (%value->text (getf entity :id)) merged-entities) (%plist-copy entity)))
    (dolist (entity (or (getf world-b :entities) '()))
      (let* ((id (%value->text (getf entity :id)))
             (current (gethash id merged-entities)))
        (cond
          ((null current)
           (setf (gethash id merged-entities) (%plist-copy entity)))
          ((equal current entity) nil)
          (t
           (push (format nil "entity ~A: A=~A / B=~A"
                         id
                         (%value->text (getf current :kind))
                         (%value->text (getf entity :kind)))
                 entity-conflicts)
           (when (member logic-mode '("paraconsistent" "many-valued" "fuzzy" "dynamic-epistemic") :test #'string=)
             (setf (gethash (format nil "~A#alt" id) merged-entities) (%plist-copy entity)))))))

    (dolist (rel (append (or (getf world-a :relations) '())
                         (or (getf world-b :relations) '())))
      (setf (gethash (format nil "~A|~A|~A"
                             (%value->text (getf rel :subject))
                             (%value->text (getf rel :predicate))
                             (%value->text (getf rel :object)))
                     merged-relations)
            (%plist-copy rel)))

    (dolist (st (append (or (getf world-a :states) '())
                        (or (getf world-b :states) '())))
      (let* ((target (%value->text (getf st :target)))
             (state (%value->text (getf st :state)))
             (target-key (format nil "~A::target" target))
             (present (gethash target-key merged-states)))
        (cond
          ((null present)
           (setf (gethash target-key merged-states) state)
           (setf (gethash (format nil "~A|~A" target state) merged-states) (%plist-copy st)))
          ((string= present state)
           (setf (gethash (format nil "~A|~A" target state) merged-states) (%plist-copy st)))
          (t
           (push (format nil "state ~A: A/B=~A vs ~A" target present state) state-conflicts)
           (when (member logic-mode '("paraconsistent" "many-valued" "fuzzy" "dynamic-epistemic") :test #'string=)
             (setf (gethash (format nil "~A|~A" target state) merged-states) (%plist-copy st)))))))

    (let ((world
            (list :name (%world-normalize-name result-name)
                  :entities (mapcar (lambda (k) (gethash k merged-entities))
                                    (remove-if (lambda (k) (search "#alt" k)) (%hash-keys merged-entities)))
                  :relations (mapcar (lambda (k) (gethash k merged-relations)) (%hash-keys merged-relations))
                  :states (mapcar (lambda (k) (gethash k merged-states))
                                 (remove-if (lambda (k) (search "::target" k)) (%hash-keys merged-states)))
                  :logic-mode (%atom-name (runtime-logic-mode rt))
                  :ontology-mode (%atom-name (runtime-ontology-mode rt))
                  :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
                  :source (format nil "merge:~A+~A"
                                  (%value->text (getf world-a :name))
                                  (%value->text (getf world-b :name)))
                  :created-at (%timestamp-string))))
      (list :world (%store-world rt world)
            :entity-conflicts (nreverse entity-conflicts)
            :state-conflicts (nreverse state-conflicts)))))

(defun %world-subtract (rt world-a world-b result-name)
  (declare (ignore rt))
  (let* ((eb (%world-entities-index world-b))
         (rb (%world-relations-keyset world-b))
         (sb (%world-states-keyset world-b))
         (entities (remove-if (lambda (entity)
                                (gethash (%value->text (getf entity :id)) eb))
                              (mapcar #'%plist-copy (or (getf world-a :entities) '()))))
         (relations (remove-if (lambda (rel)
                                 (gethash (format nil "~A|~A|~A"
                                                  (%value->text (getf rel :subject))
                                                  (%value->text (getf rel :predicate))
                                                  (%value->text (getf rel :object)))
                                          rb))
                               (mapcar #'%plist-copy (or (getf world-a :relations) '()))))
         (states (remove-if (lambda (st)
                              (gethash (format nil "~A|~A"
                                               (%value->text (getf st :target))
                                               (%value->text (getf st :state)))
                                       sb))
                            (mapcar #'%plist-copy (or (getf world-a :states) '()))))
         (world (list :name (%world-normalize-name result-name)
                      :entities entities
                      :relations relations
                      :states states
                      :logic-mode (%world-mode-value world-a :logic-mode "classical")
                      :ontology-mode (%world-mode-value world-a :ontology-mode "mixed")
                      :evaluation-mode (%world-mode-value world-a :evaluation-mode "semi-strict")
                      :source (format nil "subtract:~A-~A"
                                      (%value->text (getf world-a :name))
                                      (%value->text (getf world-b :name)))
                      :created-at (%timestamp-string))))
    (list :world world
          :removed-entities (- (length (or (getf world-a :entities) '())) (length entities))
          :removed-relations (- (length (or (getf world-a :relations) '())) (length relations))
          :removed-states (- (length (or (getf world-a :states) '())) (length states)))))

(defun %classification-voice-hint (rt)
  (let ((voice (%normalize-voice-name (runtime-active-voice rt))))
    (cond
      ((string= voice "предел") "диагноз")
      ((string= voice "сборка") "конструкция")
      (t "кандидат"))))

(defun %classify-world-compare (rt world-a world-b report)
  (cond
    ((not (%world-mode-compatible-p rt world-a world-b))
     (values "несовместимо-с-онтологией" "онтологический режим миров не совпадает с текущим контуром"))
    ((and (null (getf report :entity-only-a))
          (null (getf report :entity-only-b))
          (null (getf report :relation-only-a))
          (null (getf report :relation-only-b))
          (null (getf report :state-only-a))
          (null (getf report :state-only-b))
          (null (getf report :entity-conflicts))
          (null (getf report :state-conflicts)))
     (values "истина" "миры эквивалентны по сущностям, связям и состояниям"))
    ((or (getf report :entity-conflicts) (getf report :state-conflicts))
     (values "диагноз" "найдены конфликтующие слои мира"))
    (t
     (values (%classification-voice-hint rt) "обнаружены различия без прямого конфликта"))))

(defun %classify-world-merge (rt world-a world-b merge-report)
  (declare (ignore world-a world-b))
  (let* ((logic-mode (%atom-name (runtime-logic-mode rt)))
         (conflicts (append (getf merge-report :entity-conflicts)
                            (getf merge-report :state-conflicts))))
    (cond
      ((null conflicts)
       (values "конструкция" "получен объединённый мир без конфликтов"))
      ((member logic-mode '("paraconsistent" "many-valued" "fuzzy" "dynamic-epistemic") :test #'string=)
       (values (format nil "возможно-в-режиме-~A" logic-mode)
               "слияние содержит конфликты, но допустимо в текущем режиме логики"))
      (t
       (values "требует-новой-гипотезы"
               "слияние выявило конфликты и требует новой гипотезы разрешения")))))

(defun %classify-world-subtract (rt subtract-report)
  (let ((left-count (+ (length (getf (getf subtract-report :world) :entities))
                       (length (getf (getf subtract-report :world) :relations))
                       (length (getf (getf subtract-report :world) :states)))))
    (cond
      ((= left-count 0)
       (values "ложь" "после вычитания мир пуст"))
      ((and (= (getf subtract-report :removed-entities) 0)
            (= (getf subtract-report :removed-relations) 0)
            (= (getf subtract-report :removed-states) 0))
       (values "неопределённо" "вычитание не изменило исходный мир"))
      ((string= (%normalize-voice-name (runtime-active-voice rt)) "сборка")
       (values "конструкция" "вычитание дало рабочий остаток для дальнейшей сборки"))
      (t
       (values "кандидат" "получен остаточный мир после вычитания")))))

(defun %world-summary-lines (world)
  (list
   (format nil "мир: ~A" (%value->text (getf world :name)))
   (format nil "entities: ~D" (length (or (getf world :entities) '())))
   (format nil "relations: ~D" (length (or (getf world :relations) '())))
   (format nil "states: ~D" (length (or (getf world :states) '())))
   (format nil "logic-mode: ~A" (%world-mode-value world :logic-mode "classical"))
   (format nil "ontology-mode: ~A" (%world-mode-value world :ontology-mode "mixed"))
   (format nil "evaluation-mode: ~A" (%world-mode-value world :evaluation-mode "semi-strict"))
   (format nil "source: ~A" (%world-mode-value world :source "unknown"))
   (format nil "created-at: ~A" (%world-mode-value world :created-at "-"))))

(defun %world-list-view (rt)
  (let ((lines (list (format nil "активный мир: ~A" (%active-world-name rt))
                     (make-string 72 :initial-element #\-))))
    (dolist (pair (%world-entries rt))
      (let ((world (cdr pair)))
        (push (format nil "~A | e=~D r=~D s=~D | logic=~A onto=~A"
                      (car pair)
                      (length (or (getf world :entities) '()))
                      (length (or (getf world :relations) '()))
                      (length (or (getf world :states) '()))
                      (%world-mode-value world :logic-mode "classical")
                      (%world-mode-value world :ontology-mode "mixed"))
              lines)))
    (list :title "миры" :lines (nreverse lines))))

(defun %classified-output-catalog-view ()
  (list :title "классы вывода"
        :lines (append
                (list "базовый словарь классифицированного вывода"
                      (make-string 72 :initial-element #\-))
                (mapcar (lambda (x) (format nil "- ~A" x)) *truerul-output-classes*)
                (list ""
                      "связь с голосами:"
                      "- сборка -> конструкция / кандидат"
                      "- предел -> диагноз / несовместимо-с-онтологией"
                      "- синтез -> возможно / возможно-в-режиме-X"))))

(defun %world-show-view (world)
  (list :title (format nil "мир ~A" (%value->text (getf world :name)))
        :lines (%world-summary-lines world)))

(defun %load-world-into-runtime (rt world)
  (clrhash (runtime-entities rt))
  (dolist (entity (or (getf world :entities) '()))
    (setf (gethash (%value->text (getf entity :id)) (runtime-entities rt))
          (%plist-copy entity)))
  (setf (runtime-relations rt) (mapcar #'%plist-copy (or (getf world :relations) '())))
  (setf (runtime-states rt) (mapcar #'%plist-copy (or (getf world :states) '())))
  (setf (runtime-active-world rt) (%value->text (getf world :name)))
  (let ((logic (%world-mode-value world :logic-mode "classical"))
        (onto (%world-mode-value world :ontology-mode "mixed"))
        (evalm (%world-mode-value world :evaluation-mode "semi-strict")))
    (setf (runtime-logic-mode rt) (intern (string-upcase logic) :keyword))
    (setf (runtime-ontology-mode rt) (intern (string-upcase onto) :keyword))
    (setf (runtime-evaluation-mode rt) (intern (string-upcase evalm) :keyword)))
  (%sync-active-world-from-runtime rt :source "world-activate")
  world)

(defun %world-compare-report-lines (world-a world-b report)
  (let ((lines
          (list (format nil "A: ~A" (%value->text (getf world-a :name)))
                (format nil "B: ~A" (%value->text (getf world-b :name)))
                (make-string 72 :initial-element #\-)
                (format nil "entity shared: ~D" (length (getf report :entity-shared)))
                (format nil "entity only A: ~D" (length (getf report :entity-only-a)))
                (format nil "entity only B: ~D" (length (getf report :entity-only-b)))
                (format nil "entity conflicts: ~D" (length (getf report :entity-conflicts)))
                (format nil "relation shared: ~D" (length (getf report :relation-shared)))
                (format nil "relation only A: ~D" (length (getf report :relation-only-a)))
                (format nil "relation only B: ~D" (length (getf report :relation-only-b)))
                (format nil "state shared: ~D" (length (getf report :state-shared)))
                (format nil "state only A: ~D" (length (getf report :state-only-a)))
                (format nil "state only B: ~D" (length (getf report :state-only-b)))
                (format nil "state conflicts: ~D" (length (getf report :state-conflicts))))))
    (when (getf report :entity-conflicts)
      (setf lines
            (append lines
                    (list "" "entity conflicts:")
                    (mapcar (lambda (x) (format nil "  - ~A" x))
                            (getf report :entity-conflicts)))))
    (when (getf report :state-conflicts)
      (setf lines
            (append lines
                    (list "" "state conflicts:")
                    (mapcar (lambda (x) (format nil "  - ~A" x))
                            (getf report :state-conflicts)))))
    lines))

(defun %world-merge-report-lines (world-a world-b merge-report)
  (let* ((world (getf merge-report :world))
         (lines (list (format nil "merge A: ~A" (%value->text (getf world-a :name)))
                      (format nil "merge B: ~A" (%value->text (getf world-b :name)))
                      (format nil "result: ~A" (%value->text (getf world :name)))
                      (make-string 72 :initial-element #\-)
                      (format nil "entities: ~D" (length (or (getf world :entities) '())))
                      (format nil "relations: ~D" (length (or (getf world :relations) '())))
                      (format nil "states: ~D" (length (or (getf world :states) '())))
                      (format nil "entity conflicts: ~D" (length (getf merge-report :entity-conflicts)))
                      (format nil "state conflicts: ~D" (length (getf merge-report :state-conflicts))))))
    (when (getf merge-report :entity-conflicts)
      (setf lines
            (append lines
                    (list "" "entity conflicts:")
                    (mapcar (lambda (x) (format nil "  - ~A" x))
                            (getf merge-report :entity-conflicts)))))
    (when (getf merge-report :state-conflicts)
      (setf lines
            (append lines
                    (list "" "state conflicts:")
                    (mapcar (lambda (x) (format nil "  - ~A" x))
                            (getf merge-report :state-conflicts)))))
    lines))

(defun %world-subtract-report-lines (world-a world-b subtract-report)
  (let ((world (getf subtract-report :world)))
    (list
     (format nil "subtract A: ~A" (%value->text (getf world-a :name)))
     (format nil "subtract B: ~A" (%value->text (getf world-b :name)))
     (format nil "result: ~A" (%value->text (getf world :name)))
     (make-string 72 :initial-element #\-)
     (format nil "removed entities: ~D" (getf subtract-report :removed-entities))
     (format nil "removed relations: ~D" (getf subtract-report :removed-relations))
     (format nil "removed states: ~D" (getf subtract-report :removed-states))
     ""
     (format nil "left entities: ~D" (length (or (getf world :entities) '())))
     (format nil "left relations: ~D" (length (or (getf world :relations) '())))
     (format nil "left states: ~D" (length (or (getf world :states) '()))))))
