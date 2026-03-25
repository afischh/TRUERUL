(in-package #:truerul-runtime)

(defparameter *truerul-artifacts-root* "/srv/truerul/lisp/artifacts/")

(defun %result (kind &rest plist)
  (append (list :kind kind) plist))

(defun %history-meta-head-p (head)
  (member head
          '("история" "history"
            "назад" "back"
            "повторить" "repeat")
          :test #'string=))

(defun %history-last-executable-form (rt)
  (let ((forms (reverse (runtime-command-history rt))))
    (find-if (lambda (f)
               (and (listp f)
                    f
                    (not (%history-meta-head-p (%atom-name (car f))))))
             forms)))

(defun %sanitize-save-name (name)
  (with-output-to-string (out)
    (loop for ch across (%atom-name name) do
      (if (or (alphanumericp ch)
              (char= ch #\-)
              (char= ch #\_))
          (write-char ch out)
          (write-char #\- out)))))

(defun %timestamp-string ()
  (multiple-value-bind (sec min hour day mon year)
      (decode-universal-time (get-universal-time))
    (format nil "~4,'0D~2,'0D~2,'0D-~2,'0D~2,'0D~2,'0D"
            year mon day hour min sec)))

(defun %artifact-path (bucket name)
  (let* ((safe-name (%sanitize-save-name name))
         (dir (format nil "~A~A/" *truerul-artifacts-root* bucket))
         (file (format nil "~A__~A.txt" (%timestamp-string) safe-name)))
    (format nil "~A~A" dir file)))

(defun %save-lines-artifact (bucket name lines)
  (let ((path (%artifact-path bucket name)))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (dolist (line lines)
        (format stream "~A~%" line)))
    path))

(defun %save-form-artifact (bucket name form)
  (%save-lines-artifact bucket name (list (%print-form form))))

(defun %save-view-artifact (bucket name entry)
  (let ((title (or (getf entry :title) "вид"))
        (lines (getf entry :lines)))
    (%save-lines-artifact bucket name (append (list title "") lines))))

(defun %save-block-artifact (name form)
  (%save-form-artifact "blocks" (format nil "block-~A" (%atom-name name)) form))

(defun %block-snapshot (rt)
  (mapcar (lambda (item)
            (list :name (car item)
                  :form (cdr item)
                  :preview (%print-form (cdr item))))
          (%block-entries rt)))

(defun %clean-output-mode-p (rt)
  (eql (runtime-output-mode rt) :clean))

(defun %ok-or-silent (rt message)
  (if (%clean-output-mode-p rt)
      (%result :silent)
      (%result :ok :message message)))

(defun %normalize-string-list (value)
  (cond
    ((null value) nil)
    ((listp value) (remove-if #'null (mapcar #'%value->text value)))
    (t (list (%value->text value)))))

(defun %language-layer-specs ()
  (list
   (list :family "Мир"
         :note "Онтологическое построение фрагмента мира."
         :heads '("сущность" "связь" "состояние"
                  "мир" "миры" "мир-показать" "мир-активировать"
                  "сравнить-миры" "объединить-миры" "вычесть-мир"))
   (list :family "Запрос"
         :note "Проверка и извлечение без изменения мира."
         :heads '("запрос" "связь?" "сущность?" "состояние?"))
   (list :family "Вид"
         :note "Представление и композиция структуры."
         :heads '("вид" "схема"))
   (list :family "Библиотека"
         :note "Накопленная память и концептуальные ресурсы."
         :heads '("категория" "дихотомия" "напряжение" "карточка-цитаты" "помощь" "фигура"))
   (list :family "Мастерская"
         :note "Рабочая среда и операционный цикл."
         :heads '("буфер" "блок" "блоки" "вставить-блок" "выполнить-блок"
                  "история" "назад" "повторить"
                  "сохранить" "сохранить-вид" "сохранить-таблицу" "сохранить-схему"
                  "очистить" "режим" "классы-вывода"))
   (list :family "Голоса/Эвристика"
         :note "Режимы рассуждения, гипотезы и сравнительные проходы."
         :heads '("голоса" "голос" "применить-голос" "гипотеза" "спор" "заметка" "вывод"))))

(defun %layer-lines ()
  (let ((lines (list "стратификация языка Truerul"
                     (make-string 72 :initial-element #\-))))
    (dolist (spec (%language-layer-specs))
      (push (format nil "~A:" (getf spec :family)) lines)
      (push (format nil "  формы: ~{~A~^, ~}" (getf spec :heads)) lines)
      (push (format nil "  роль: ~A" (getf spec :note)) lines)
      (push "" lines))
    (nreverse lines)))

(defun %canonical-flow-lines ()
  (list
   "канонический ритм пользователя"
   (make-string 72 :initial-element #\-)
   "1) открыть библиотечный ресурс (категория/дихотомия/напряжение/помощь)"
   "2) собрать фрагмент мира (сущность/связь/состояние)"
   "3) проверить гипотезы запросом (запрос + связь?/сущность?/состояние?)"
   "4) сделать представление (вид/схема)"
   "5) сохранить результат в мастерской (блок/сохранить-*)"
   "6) при необходимости применить голос/эвристику (голос/применить-голос/гипотеза)"))

(defun %cleanup-lines ()
  (list
   "cleanup / канонизация поверхности команд"
   (make-string 72 :initial-element #\-)
   "оставить каноничными RU-головы как первичные."
   "EN-головы держать как alias-совместимость (entity/relation/query/...)." 
   "режим трактовать как мастерскую мета-команду (язык/вывод/голос), а не как онтологию."
   "фигура оставить в библиотеке (культурная память), не как центральный движок."
   "голоса сделать центральным входом будущей эвристики, без персонализации авторов."
   "в перспективе: пометить фигура/карточка-цитаты как secondary-family в UI."))

(defun %normalize-voice-name (name)
  (let ((raw (%atom-name name)))
    (cond
      ((member raw '("builder" "constructive" "конструктор" "сборщик" "сборка") :test #'string=) "сборка")
      ((member raw '("critic" "critical" "критик" "предел" "ограничитель") :test #'string=) "предел")
      ((member raw '("synth" "synthesis" "медиатор" "синтез") :test #'string=) "синтез")
      (t raw))))

(defun %voice-fetch (rt name)
  (let* ((normalized (%normalize-voice-name name))
         (voice (gethash normalized (runtime-voices rt))))
    (values normalized voice)))

(defun %voice-lines (voice active-name)
  (let* ((name (%atom-name (getf voice :name)))
         (active (string= name (%atom-name active-name)))
         (marker (if active "*" "-")))
    (list
     (format nil "~A голос: ~A" marker name)
     (format nil "  позиция: ~A" (%value->text (getf voice :stance)))
     (format nil "  фокус: ~A" (%value->text (getf voice :focus)))
     (format nil "  тенденции: ~{~A~^, ~}" (%normalize-string-list (getf voice :tendencies)))
     (format nil "  проверки: ~{~A~^, ~}" (%normalize-string-list (getf voice :checks)))
     (format nil "  ключи: ~{~A~^, ~}" (%normalize-string-list (getf voice :keywords))))))

(defun %voices-list-view (rt)
  (let ((lines (list "голоса Truerul"
                     (make-string 72 :initial-element #\-)
                     (format nil "активный голос: ~A" (runtime-active-voice rt))
                     "")))
    (dolist (pair (%voice-entries rt))
      (setf lines (append lines (%voice-lines (cdr pair) (runtime-active-voice rt)) (list ""))))
    (list :title "голоса" :lines lines)))

(defun %voice-single-view (rt voice)
  (list :title (format nil "голос ~A" (%atom-name (getf voice :name)))
        :lines (%voice-lines voice (runtime-active-voice rt))))

(defun %voice-suggestions (voice target-text)
  (let ((name (%atom-name (getf voice :name))))
    (cond
      ((string= name "сборка")
       (list (format nil "построй ядро формы вокруг: ~A" target-text)
             "добавь недостающие сущности и явные связи"
             "собери рабочий блок для повторного запуска"))
      ((string= name "предел")
       (list (format nil "проверь ограничения и противоречия в: ~A" target-text)
             "удали лишние/шумные связи"
             "отметь что не доказано запросом"))
      ((string= name "синтез")
       (list (format nil "сведи контуры в читаемый вид: ~A" target-text)
             "собери схему и соседние состояния"
             "подготовь сохранённый вид/таблицу для сравнения"))
      (t
       (list (format nil "применить голос ~A к: ~A" name target-text)
             "выделить главную структуру"
             "сохранить результат в мастерской")))))

(defun %heuristic-log-append (rt entry)
  (setf (runtime-heuristic-log rt)
        (append (runtime-heuristic-log rt) (list entry))))

(defun evaluate-form (rt form &key (record t))
  (unless (and (listp form) form)
    (return-from evaluate-form
      (%result :error :message "форма должна быть непустым списком")))
  (let ((head (%atom-name (car form))))
    (when record
      (%history-append rt form))
    (cond
      ((member head '("entity" "сущность") :test #'string=)
       (destructuring-bind (_ id &rest rest) form
         (declare (ignore _))
         (let* ((kind (or (%plist-value rest :kind)
                          (%plist-value rest :тип)
                          'thing))
                (entity (list :id (%atom-name id)
                              :kind (%atom-name kind)
                              :attrs rest)))
           (setf (gethash (%atom-name id) (runtime-entities rt)) entity)
           (%sync-active-world-from-runtime rt :source "entity")
           (%push-form-log rt form)
           (%push-log rt (list :type :entity
                               :id (%atom-name id)
                               :kind (%atom-name kind)))
           (%ok-or-silent rt
                          (format nil "сущность зарегистрирована: ~A :: тип ~A"
                                  (%atom-name id)
                                  (%atom-name kind))))))

      ((member head '("relation" "связь") :test #'string=)
       (destructuring-bind (_ subject predicate object &rest rest) form
         (declare (ignore _ rest))
         (let ((rel (list :subject (%atom-name subject)
                          :predicate (%atom-name predicate)
                          :object (%atom-name object))))
           (setf (runtime-relations rt) (append (runtime-relations rt) (list rel)))
           (%sync-active-world-from-runtime rt :source "relation")
           (%push-form-log rt form)
           (%push-log rt (list :type :relation
                               :subject (%atom-name subject)
                               :predicate (%atom-name predicate)
                               :object (%atom-name object)))
           (%ok-or-silent rt
                          (format nil "связь зарегистрирована: ~A --~A--> ~A"
                                  (%atom-name subject)
                                  (%atom-name predicate)
                                  (%atom-name object))))))

      ((member head '("state" "состояние") :test #'string=)
       (destructuring-bind (_ target state &rest rest) form
         (declare (ignore _ rest))
         (let ((st (list :target (%atom-name target)
                         :state (%atom-name state))))
           (setf (runtime-states rt) (append (runtime-states rt) (list st)))
           (%sync-active-world-from-runtime rt :source "state")
           (%push-form-log rt form)
           (%push-log rt (list :type :state
                               :target (%atom-name target)
                               :state (%atom-name state)))
           (%ok-or-silent rt
                          (format nil "состояние зарегистрировано: ~A :: ~A"
                                  (%atom-name target)
                                  (%atom-name state))))))

      ((member head '("world" "мир") :test #'string=)
       (let ((name (second form)))
         (if (null name)
             (%result :error :message "мир ожидает имя: (мир <имя>)")
             (let* ((wname (%world-normalize-name name))
                    (world (%store-world rt (%make-world-object rt wname :source "command:мир"))))
               (%push-log rt (list :type :world-snapshot :name wname))
               (%result :classification
                        :class "конструкция"
                        :reason (format nil "мир зафиксирован как объект: ~A" wname)
                        :voice (runtime-active-voice rt)
                        :logic-mode (%atom-name (runtime-logic-mode rt))
                        :ontology-mode (%atom-name (runtime-ontology-mode rt))
                        :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
                        :report-lines (%world-summary-lines world)
                        :world-name wname)))))

      ((member head '("worlds" "миры") :test #'string=)
       (%result :view :entry (%world-list-view rt)))

      ((member head '("world-show" "мир-показать") :test #'string=)
       (let* ((name (second form))
              (world (%world-fetch rt name)))
         (if world
             (%result :view :entry (%world-show-view world))
             (%result :error :message (format nil "мир не найден: ~A" (%atom-name name))))))

      ((member head '("world-activate" "мир-активировать") :test #'string=)
       (let* ((name (second form))
              (world (%world-fetch rt name)))
         (if (null world)
             (%result :error :message (format nil "мир не найден: ~A" (%atom-name name)))
             (progn
               (%load-world-into-runtime rt world)
               (%push-log rt (list :type :world-activate :name (%value->text (getf world :name))))
               (%result :classification
                        :class "конструкция"
                        :reason (format nil "мир активирован: ~A" (%value->text (getf world :name)))
                        :voice (runtime-active-voice rt)
                        :logic-mode (%atom-name (runtime-logic-mode rt))
                        :ontology-mode (%atom-name (runtime-ontology-mode rt))
                        :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
                        :report-lines (%world-summary-lines world)
                        :world-name (%value->text (getf world :name)))))))

      ((member head '("compare-worlds" "сравнить-миры" "миры-сравнить") :test #'string=)
       (let* ((a-name (second form))
              (b-name (third form))
              (world-a (%world-fetch rt a-name))
              (world-b (%world-fetch rt b-name)))
         (cond
           ((null a-name)
            (%result :error :message "сравнить-миры ожидает A и B: (сравнить-миры A B)"))
           ((null b-name)
            (%result :error :message "сравнить-миры ожидает A и B: (сравнить-миры A B)"))
           ((null world-a)
            (%result :error :message (format nil "мир A не найден: ~A" (%atom-name a-name))))
           ((null world-b)
            (%result :error :message (format nil "мир B не найден: ~A" (%atom-name b-name))))
           (t
            (let* ((report (%world-compare world-a world-b))
                   (lines (%world-compare-report-lines world-a world-b report)))
              (multiple-value-bind (class reason) (%classify-world-compare rt world-a world-b report)
                (%push-log rt (list :type :world-compare
                                    :a (%value->text (getf world-a :name))
                                    :b (%value->text (getf world-b :name))
                                    :class class))
                (%result :classification
                         :class class
                         :reason reason
                         :voice (runtime-active-voice rt)
                         :logic-mode (%atom-name (runtime-logic-mode rt))
                         :ontology-mode (%atom-name (runtime-ontology-mode rt))
                         :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
                         :report-lines lines)))))))

      ((member head '("merge-worlds" "объединить-миры" "миры-объединить") :test #'string=)
       (let* ((a-name (second form))
              (b-name (third form))
              (args (cdddr form))
              (result-name (or (%plist-value args :в)
                               (%plist-value args :в-мир)
                               (%plist-value args :into)
                               (format nil "~A+~A" (%atom-name a-name) (%atom-name b-name))))
              (world-a (%world-fetch rt a-name))
              (world-b (%world-fetch rt b-name)))
         (cond
           ((or (null a-name) (null b-name))
            (%result :error :message "объединить-миры ожидает A и B: (объединить-миры A B :в C)"))
           ((null world-a)
            (%result :error :message (format nil "мир A не найден: ~A" (%atom-name a-name))))
           ((null world-b)
            (%result :error :message (format nil "мир B не найден: ~A" (%atom-name b-name))))
           (t
            (let* ((merge-report (%world-merge rt world-a world-b result-name))
                   (world (getf merge-report :world))
                   (lines (%world-merge-report-lines world-a world-b merge-report)))
              (multiple-value-bind (class reason) (%classify-world-merge rt world-a world-b merge-report)
                (%push-log rt (list :type :world-merge
                                    :a (%value->text (getf world-a :name))
                                    :b (%value->text (getf world-b :name))
                                    :out (%value->text (getf world :name))
                                    :class class))
                (%result :classification
                         :class class
                         :reason reason
                         :voice (runtime-active-voice rt)
                         :logic-mode (%atom-name (runtime-logic-mode rt))
                         :ontology-mode (%atom-name (runtime-ontology-mode rt))
                         :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
                         :report-lines lines
                         :world-name (%value->text (getf world :name)))))))))

      ((member head '("subtract-world" "вычесть-мир" "миры-вычесть") :test #'string=)
       (let* ((a-name (second form))
              (b-name (third form))
              (args (cdddr form))
              (result-name (or (%plist-value args :в)
                               (%plist-value args :в-мир)
                               (%plist-value args :into)
                               (format nil "~A-~A" (%atom-name a-name) (%atom-name b-name))))
              (world-a (%world-fetch rt a-name))
              (world-b (%world-fetch rt b-name)))
         (cond
           ((or (null a-name) (null b-name))
            (%result :error :message "вычесть-мир ожидает A и B: (вычесть-мир A B :в C)"))
           ((null world-a)
            (%result :error :message (format nil "мир A не найден: ~A" (%atom-name a-name))))
           ((null world-b)
            (%result :error :message (format nil "мир B не найден: ~A" (%atom-name b-name))))
           (t
            (let* ((subtract-report (%world-subtract rt world-a world-b result-name))
                   (world (%store-world rt (getf subtract-report :world)))
                   (lines (%world-subtract-report-lines world-a world-b
                                                       (append subtract-report (list :world world)))))
              (multiple-value-bind (class reason)
                  (%classify-world-subtract rt (append subtract-report (list :world world)))
                (%push-log rt (list :type :world-subtract
                                    :a (%value->text (getf world-a :name))
                                    :b (%value->text (getf world-b :name))
                                    :out (%value->text (getf world :name))
                                    :class class))
                (%result :classification
                         :class class
                         :reason reason
                         :voice (runtime-active-voice rt)
                         :logic-mode (%atom-name (runtime-logic-mode rt))
                         :ontology-mode (%atom-name (runtime-ontology-mode rt))
                         :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
                         :report-lines lines
                         :world-name (%value->text (getf world :name)))))))))

      ((member head '("query" "запрос") :test #'string=)
       (let ((pattern (second form)))
         (unless (and (listp pattern) pattern)
           (return-from evaluate-form
             (%result :error :message "запрос ожидает шаблон-список")))
         (%push-log rt (list :type :query :pattern (%print-form pattern)))
         (let ((phead (%atom-name (car pattern))))
           (cond
             ((member phead '("relation?" "связь?") :test #'string=)
              (%result :query
                       :matches (query-relations rt
                                                 (second pattern)
                                                 (third pattern)
                                                 (fourth pattern))))
             ((member phead '("entity?" "сущность?") :test #'string=)
              (%result :query
                       :matches (query-entities rt
                                                (second pattern)
                                                (or (%plist-value (cddr pattern) :kind)
                                                    (%plist-value (cddr pattern) :тип)
                                                    '_))))
             ((member phead '("state?" "состояние?") :test #'string=)
              (%result :query
                       :matches (query-states rt
                                              (second pattern)
                                              (third pattern))))
             (t
              (%result :error
                       :message (format nil "неподдерживаемая голова-запроса: ~A" phead)))))))

      ((member head '("view" "вид") :test #'string=)
       (let ((kind (second form))
             (concept (third form)))
         (unless kind
           (return-from evaluate-form
             (%result :error :message "вид ожидает аргумент, например (вид категории)")))
         (if (member (%atom-name kind) '("scheme" "схема") :test #'string=)
             (if concept
                 (let ((entry (make-concept-scheme-view rt concept)))
                   (setf (runtime-last-view rt) entry)
                   (%result :view :entry entry))
                 (%result :error :message "вид схема ожидает понятие, например (вид схема время)"))
             (let ((entry (make-library-view kind)))
               (if entry
                   (progn
                     (setf (runtime-last-view rt) entry)
                     (%result :view :entry entry))
                   (%result :error
                            :message (format nil "неизвестный вид: ~A" (%atom-name kind))))))))

      ((member head '("scheme" "схема") :test #'string=)
       (let ((concept (second form)))
         (if concept
             (let ((entry (make-concept-scheme-view rt concept)))
               (setf (runtime-last-view rt) entry)
               (%result :view :entry entry))
             (%result :error :message "схема ожидает понятие, например (схема время)"))))

      ((member head '("layers" "слои" "страты" "язык") :test #'string=)
       (%result :view :entry (list :title "страты языка" :lines (%layer-lines))))

      ((member head '("flow" "ритм" "поток") :test #'string=)
       (%result :view :entry (list :title "канонический ритм" :lines (%canonical-flow-lines))))

      ((member head '("canon" "канон" "чистка-языка") :test #'string=)
       (%result :view :entry (list :title "канонизация поверхности" :lines (%cleanup-lines))))

      ((member head '("output-classes" "классы-вывода" "классификация") :test #'string=)
       (%result :view :entry (%classified-output-catalog-view)))

      ((member head '("lib-reindex" "lib-переиндексировать" "lib-индекс") :test #'string=)
       (let ((libs (%lib-index-runtime rt :force t)))
         (%result :view
                  :entry (list :title ".lib индекс"
                               :lines (list (format nil "indexed-at: ~A" (runtime-lib-indexed-at rt))
                                            (format nil "loaded: ~D" (length libs)))))))

      ((member head '("lib-list" "lib-список") :test #'string=)
       (let* ((filters (cdr form))
              (libs (%lib-filter-runtime rt filters :force-index nil)))
         (%result :view :entry (%lib-list-view libs ".lib список"))))

      ((member head '("lib-route" "lib-подобрать" "lib-маршрут") :test #'string=)
       (let* ((filters (cdr form))
              (route (%lib-route-runtime rt filters :force-index nil)))
         (%result :view :entry (%lib-route-view route ".lib маршрут"))))

      ((member head '("assist" "ассист") :test #'string=)
       (let* ((operator-input (second form))
              (args (cddr form))
              (role (or (%plist-value args :role)
                        (%plist-value args :роль)))
              (assist (%assist-runtime rt (%value->text operator-input) :role (%value->text role))))
         (%result :view :entry (%assist-view assist "assist-layer"))))

      ((member head '("operator" "оператор") :test #'string=)
       (let* ((operator-input (second form))
              (filters (cddr form))
              (pipeline (%operator-pipeline-runtime rt (%value->text operator-input) filters))
              (selected (getf pipeline :selected-lib))
              (route-lines (if (getf pipeline :route)
                               (loop for item in (getf pipeline :route)
                                     collect (format nil "score=~D :: ~A"
                                                     (getf item :score)
                                                     (getf (getf item :lib) :id)))
                               (list "route empty"))))
         (%push-log rt (list :type :lib-pipeline
                             :class (getf pipeline :class)
                             :lib (and selected (getf selected :id))
                             :voice (runtime-active-voice rt)))
         (%result :classification
                  :class (getf pipeline :class)
                  :reason (getf pipeline :reason)
                  :lib (and selected (getf selected :id))
                  :voice (runtime-active-voice rt)
                  :logic-mode (%atom-name (runtime-logic-mode rt))
                  :ontology-mode (%atom-name (runtime-ontology-mode rt))
                  :evaluation-mode (%atom-name (runtime-evaluation-mode rt))
                  :normalized-forms (getf (getf pipeline :assist) :normalized-forms)
                  :filters (getf pipeline :filters)
                  :route route-lines
                  :report-lines (list (format nil "operator-input: ~A" (%value->text operator-input))
                                      (format nil "selected-lib: ~A" (or (and selected (getf selected :id)) "-"))))))

      ((member head '("voices" "голоса") :test #'string=)
       (%result :view :entry (%voices-list-view rt)))

      ((member head '("voice" "голос") :test #'string=)
       (let* ((name (second form))
              (args (cddr form)))
         (if (null name)
             (%result :view :entry (%voices-list-view rt))
             (multiple-value-bind (vname voice) (%voice-fetch rt name)
               (if (null voice)
                   (%result :error :message (format nil "голос не найден: ~A" vname))
                   (if (null args)
                       (%result :view :entry (%voice-single-view rt voice))
                       (let* ((updated (append voice nil))
                              (focus (or (%plist-value args :focus) (%plist-value args :фокус)))
                              (stance (or (%plist-value args :stance) (%plist-value args :позиция)))
                              (tendencies (or (%plist-value args :tendencies) (%plist-value args :тенденции)))
                              (checks (or (%plist-value args :checks) (%plist-value args :проверки)))
                              (keywords (or (%plist-value args :keywords) (%plist-value args :ключи))))
                         (when focus (setf (getf updated :focus) (%value->text focus)))
                         (when stance (setf (getf updated :stance) (%value->text stance)))
                         (when tendencies (setf (getf updated :tendencies) (%normalize-string-list tendencies)))
                         (when checks (setf (getf updated :checks) (%normalize-string-list checks)))
                         (when keywords (setf (getf updated :keywords) (%normalize-string-list keywords)))
                         (setf (gethash vname (runtime-voices rt)) updated)
                         (%result :ok :message (format nil "голос обновлён: ~A" vname)))))))))

      ((member head '("apply-voice" "применить-голос") :test #'string=)
       (let* ((arg1 (second form))
              (arg2 (third form))
              (name (if (and arg1 (not (listp arg1))) arg1 (runtime-active-voice rt)))
              (target (if (and arg1 (not (listp arg1))) arg2 arg1)))
         (if (null target)
             (%result :error :message "применить-голос ожидает цель: (применить-голос <голос> <форма|тема>)")
             (multiple-value-bind (vname voice) (%voice-fetch rt name)
               (if (null voice)
                   (%result :error :message (format nil "голос не найден: ~A" vname))
                   (let ((entry (list :title (format nil "применить голос ~A" vname)
                                      :lines (append
                                              (list (format nil "цель: ~A" (%value->text target))
                                                    (format nil "позиция: ~A" (%value->text (getf voice :stance)))
                                                    (format nil "фокус: ~A" (%value->text (getf voice :focus)))
                                                    ""
                                                    "предложенные шаги:")
                                              (loop for item in (%voice-suggestions voice (%value->text target))
                                                    for idx from 1
                                                    collect (format nil "~D) ~A" idx item))))))
                     (%heuristic-log-append rt (list :type :voice-apply :voice vname :target (%value->text target)))
                     (%push-log rt (list :type :voice-apply :voice vname :target (%value->text target)))
                     (%result :view :entry entry)))))))

      ((member head '("hypothesis" "гипотеза") :test #'string=)
       (let* ((name (or (second form) 'hypothesis))
              (body (or (third form) (second form)))
              (entry (list :type :hypothesis
                           :name (%atom-name name)
                           :body (%value->text body)
                           :voice (runtime-active-voice rt))))
         (%heuristic-log-append rt entry)
         (%push-log rt entry)
         (%result :ok :message (format nil "гипотеза сохранена: ~A" (%atom-name name)))))

      ((member head '("dispute" "спор") :test #'string=)
       (let* ((thesis (second form))
              (antithesis (third form)))
         (if (or (null thesis) (null antithesis))
             (%result :error :message "спор ожидает пару: (спор <тезис> <антитезис>)")
             (let ((entry (list :title "спор"
                                :lines (list
                                        (format nil "тезис: ~A" (%value->text thesis))
                                        (format nil "антитезис: ~A" (%value->text antithesis))
                                        (format nil "активный голос: ~A" (runtime-active-voice rt))
                                        ""
                                        "рекомендация: пройти оба тезиса через (применить-голос)."))))
               (%heuristic-log-append rt (list :type :dispute
                                               :thesis (%value->text thesis)
                                               :antithesis (%value->text antithesis)
                                               :voice (runtime-active-voice rt)))
               (%push-log rt (list :type :dispute
                                   :thesis (%value->text thesis)
                                   :antithesis (%value->text antithesis)))
               (%result :view :entry entry)))))

      ((member head '("note" "заметка") :test #'string=)
       (let* ((body (second form))
              (entry (list :type :note :body (%value->text body) :voice (runtime-active-voice rt))))
         (%heuristic-log-append rt entry)
         (%push-log rt entry)
         (%result :ok :message "заметка добавлена в эвристический журнал")))

      ((member head '("inference" "вывод") :test #'string=)
       (let* ((target (or (second form) (and (runtime-last-view rt) (getf (runtime-last-view rt) :title)) "текущий контур"))
              (voice-name (runtime-active-voice rt))
              (voice (gethash voice-name (runtime-voices rt)))
              (entry (list :title "эвристический вывод"
                           :lines (append
                                   (list (format nil "контур: ~A" (%value->text target))
                                         (format nil "голос: ~A" voice-name)
                                         "")
                                   (loop for item in (%voice-suggestions voice (%value->text target))
                                         for idx from 1
                                         collect (format nil "~D) ~A" idx item))))))
         (%heuristic-log-append rt (list :type :inference :target (%value->text target) :voice voice-name))
         (%push-log rt (list :type :inference :target (%value->text target) :voice voice-name))
         (%result :view :entry entry)))

      ((member head '("help" "помощь") :test #'string=)
       (if (second form)
           (let* ((target (second form))
                  (note (%library-help-note target)))
             (if note
                 (%result :library-card :entry note)
                 (%result :error
                          :message (format nil "нет записи помощи для ~A"
                                           (%atom-name target)))))
           (%result :help)))

      ((member head '("figure" "фигура") :test #'string=)
       (let ((entry (%library-figure (second form))))
         (if entry
             (%result :library-card :entry entry)
             (%result :error
                      :message (format nil "неизвестная фигура: ~A"
                                       (%atom-name (second form)))))))

      ((member head '("category" "категория") :test #'string=)
       (let ((entry (%library-category (second form))))
         (if entry
             (%result :library-card :entry entry)
             (%result :error
                      :message (format nil "неизвестная категория: ~A"
                                       (%atom-name (second form)))))))

      ((member head '("dichotomy" "дихотомия") :test #'string=)
       (let ((entry (%library-dichotomy (second form) (third form))))
         (if entry
             (%result :library-card :entry entry)
             (%result :error
                      :message (format nil "неизвестная дихотомия: ~A / ~A"
                                       (%atom-name (second form))
                                       (%atom-name (third form)))))))

      ((member head '("tension" "напряжение") :test #'string=)
       (let ((entry (%library-tension (second form) (third form))))
         (if entry
             (%result :library-card :entry entry)
             (%result :error
                      :message (format nil "неизвестное напряжение: ~A / ~A"
                                       (%atom-name (second form))
                                       (%atom-name (third form)))))))

      ((member head '("quote-card" "карточка-цитаты") :test #'string=)
       (let ((entry (%library-quote-card (second form))))
         (if entry
             (%result :library-card :entry entry)
             (%result :error
                      :message (format nil "неизвестная карточка-цитаты: ~A"
                                       (%atom-name (second form)))))))

      ((member head '("quote" "цитата") :test #'string=)
       (%result :form :form (second form)))

      ((member head '("eval" "вычислить") :test #'string=)
       (let ((inner (second form)))
         (if (listp inner)
             (evaluate-form rt inner :record nil)
             (%result :error :message "вычислить ожидает списковую форму"))))

      ((member head '("log" "журнал") :test #'string=)
       (%result :log :entries (runtime-log rt)))

      ((member head '("history" "история") :test #'string=)
       (%result :history :forms (runtime-command-history rt)))

      ((member head '("back" "назад") :test #'string=)
       (let ((prev (%history-prev rt)))
         (if prev
             (%result :history-nav
                      :message "предыдущая форма выбрана"
                      :form prev)
             (%result :error :message "история пока пуста"))))

      ((member head '("repeat" "повторить") :test #'string=)
       (let ((target (%history-last-executable-form rt)))
         (if target
             (evaluate-form rt target :record t)
             (%result :error :message "нечего повторять: нет предыдущей исполняемой формы"))))

      ((member head '("buffer" "буфер") :test #'string=)
       (%result :buffer :entries (%block-snapshot rt)))

      ((member head '("blocks" "блоки") :test #'string=)
       (%result :buffer :entries (%block-snapshot rt)))

      ((member head '("block" "блок") :test #'string=)
       (let ((name (second form))
             (payload (cddr form)))
         (cond
           ((null name)
            (%result :error :message "блок ожидает имя: (блок <имя> <форма>)"))
           ((null payload)
            (%result :error :message "блок ожидает содержимое: (блок <имя> <форма>)"))
           (t
           (let* ((bname (%atom-name name))
                   (stored (if (= (length payload) 1)
                               (car payload)
                               (cons 'progn payload))))
              (setf (gethash bname (runtime-blocks rt)) stored)
              (handler-case
                  (let ((path (%save-block-artifact bname stored)))
                    (%result :ok :message (format nil "блок сохранён: ~A (artifact ~A)" bname path)))
                (error ()
                  (%result :ok :message (format nil "блок сохранён: ~A" bname)))))))))

      ((member head '("run-block" "выполнить-блок") :test #'string=)
       (let* ((name (second form))
              (bname (and name (%atom-name name)))
              (stored (and bname (gethash bname (runtime-blocks rt)))))
         (cond
           ((null bname)
            (%result :error :message "выполнить-блок ожидает имя: (выполнить-блок <имя>)"))
           ((null stored)
            (%result :error :message (format nil "блок не найден: ~A" bname)))
           ((not (listp stored))
            (%result :error :message (format nil "блок ~A имеет неисполняемую форму" bname)))
           (t
            (evaluate-form rt stored :record t)))))

      ((member head '("insert-block" "вставить-блок") :test #'string=)
       (let* ((name (second form))
              (bname (and name (%atom-name name))))
         (cond
           ((null bname)
            (%result :error :message "вставить-блок ожидает имя: (вставить-блок <имя>)"))
           ((null (gethash bname (runtime-blocks rt)))
            (%result :error :message (format nil "блок не найден: ~A" bname)))
           (t
            (%result :form :form (gethash bname (runtime-blocks rt)))))))

      ((member head '("save" "сохранить") :test #'string=)
       (let ((name (or (second form) 'artifact)))
         (let* ((forms (runtime-command-history rt))
                (lines (if forms
                           (mapcar #'%print-form forms)
                           '("история пока пуста")))
                (path (%save-lines-artifact "notes" name lines)))
           (%result :ok :message (format nil "сохранено: ~A" path)))))

      ((member head '("save-view" "сохранить-вид") :test #'string=)
       (let ((entry (runtime-last-view rt))
             (name (or (second form) 'view)))
         (if entry
             (let ((path (%save-view-artifact "views" name entry)))
               (%result :ok :message (format nil "вид сохранён: ~A" path)))
             (%result :error :message "нет последнего вида для сохранения"))))

      ((member head '("save-table" "сохранить-таблицу") :test #'string=)
       (let ((entry (runtime-last-view rt))
             (name (or (second form) 'table)))
         (if entry
             (let ((path (%save-view-artifact "tables" name entry)))
               (%result :ok :message (format nil "таблица сохранена: ~A" path)))
             (%result :error :message "нет последнего вида для сохранения таблицы"))))

      ((member head '("save-scheme" "сохранить-схему") :test #'string=)
       (let ((entry (runtime-last-view rt))
             (name (or (second form) 'scheme)))
         (if (and entry (search "схема" (or (getf entry :title) "")))
             (let ((path (%save-view-artifact "schemes" name entry)))
               (%result :ok :message (format nil "схема сохранена: ~A" path)))
             (%result :error :message "последняя схема не найдена; сначала выполните (схема <понятие>)"))))

      ((member head '("save-selected" "сохранить-выделенное") :test #'string=)
       (%result :note :message "сохранить-выделенное пока не реализовано (selection support not ready)"))

      ((member head '("step" "шаг") :test #'string=)
       (setf (runtime-cycle rt) (1+ (runtime-cycle rt)))
       (%push-log rt (list :type :step :cycle (runtime-cycle rt)))
       (%ok-or-silent rt
                      (format nil "цикл продвинут до ~D"
                              (runtime-cycle rt))))

      ((member head '("surface" "поверхность" "режим") :test #'string=)
       (let* ((lang (or (%plist-value (cdr form) :lang)
                        (%plist-value (cdr form) :язык)))
              (output (or (%plist-value (cdr form) :output)
                          (%plist-value (cdr form) :вывод)))
              (voice (or (%plist-value (cdr form) :voice)
                         (%plist-value (cdr form) :голос)))
              (logic (or (%plist-value (cdr form) :logic)
                         (%plist-value (cdr form) :логика)))
              (ontology (or (%plist-value (cdr form) :ontology)
                            (%plist-value (cdr form) :онтология)))
              (evaluation (or (%plist-value (cdr form) :evaluation)
                              (%plist-value (cdr form) :оценка)))
              (has-lang (or (%plist-has-key (cdr form) :lang)
                            (%plist-has-key (cdr form) :язык)))
              (has-output (or (%plist-has-key (cdr form) :output)
                              (%plist-has-key (cdr form) :вывод)))
              (has-voice (or (%plist-has-key (cdr form) :voice)
                             (%plist-has-key (cdr form) :голос)))
              (has-logic (or (%plist-has-key (cdr form) :logic)
                             (%plist-has-key (cdr form) :логика)))
              (has-ontology (or (%plist-has-key (cdr form) :ontology)
                                (%plist-has-key (cdr form) :онтология)))
              (has-evaluation (or (%plist-has-key (cdr form) :evaluation)
                                  (%plist-has-key (cdr form) :оценка)))
              (lname (%atom-name lang))
              (oname (%atom-name output))
              (vname (%normalize-voice-name voice))
              (logic-name (%atom-name logic))
              (ontology-name (%atom-name ontology))
              (evaluation-name (%atom-name evaluation))
              (normalized (cond
                            ((string= lname "ru") :ru)
                            ((string= lname "en") :en)
                            (t nil)))
              (normalized-output (cond
                                   ((member oname '("clean" "result" "чисто" "результат") :test #'string=) :clean)
                                   ((member oname '("verbose" "build" "подробно" "сборка") :test #'string=) :verbose)
                                   (t nil)))
              (normalized-voice (and has-voice (gethash vname (runtime-voices rt))))
              (normalized-logic (cond
                                  ((member logic-name '("classical" "классическая") :test #'string=) :classical)
                                  ((member logic-name '("many-valued" "многозначная") :test #'string=) :many-valued)
                                  ((member logic-name '("fuzzy" "нечёткая" "нечеткая") :test #'string=) :fuzzy)
                                  ((member logic-name '("paraconsistent" "параконсистентная") :test #'string=) :paraconsistent)
                                  ((member logic-name '("dynamic-epistemic" "динамико-эпистемическая") :test #'string=) :dynamic-epistemic)
                                  (t nil)))
              (normalized-ontology (cond
                                     ((member ontology-name '("set" "множества") :test #'string=) :set)
                                     ((member ontology-name '("type" "типы") :test #'string=) :type)
                                     ((member ontology-name '("category" "категория") :test #'string=) :category)
                                     ((member ontology-name '("topos" "топос") :test #'string=) :topos)
                                     ((member ontology-name '("mixed" "смешанная") :test #'string=) :mixed)
                                     (t nil)))
              (normalized-evaluation (cond
                                       ((member evaluation-name '("strict" "строгий") :test #'string=) :strict)
                                       ((member evaluation-name '("semi-strict" "полу-строгий" "semi") :test #'string=) :semi-strict)
                                       ((member evaluation-name '("heuristic" "эвристический") :test #'string=) :heuristic)
                                       (t nil))))
         (cond
           ((and has-lang (null normalized))
            (%result :error :message "режим ожидает :язык ru|en"))
           ((and has-output (null normalized-output))
            (%result :error :message "режим ожидает :вывод clean|verbose"))
           ((and has-voice (null normalized-voice))
            (%result :error :message "режим ожидает :голос сборка|предел|синтез"))
           ((and has-logic (null normalized-logic))
            (%result :error :message "режим ожидает :логика classical|many-valued|fuzzy|paraconsistent|dynamic-epistemic"))
           ((and has-ontology (null normalized-ontology))
            (%result :error :message "режим ожидает :онтология set|type|category|topos|mixed"))
           ((and has-evaluation (null normalized-evaluation))
            (%result :error :message "режим ожидает :оценка strict|semi-strict|heuristic"))
           ((or normalized normalized-output has-voice normalized-logic normalized-ontology normalized-evaluation)
            (when normalized
              (setf (runtime-lang rt) normalized))
            (when normalized-output
              (setf (runtime-output-mode rt) normalized-output))
            (when has-voice
              (setf (runtime-active-voice rt) vname))
            (when normalized-logic
              (setf (runtime-logic-mode rt) normalized-logic))
            (when normalized-ontology
              (setf (runtime-ontology-mode rt) normalized-ontology))
            (when normalized-evaluation
              (setf (runtime-evaluation-mode rt) normalized-evaluation))
            (%sync-active-world-from-runtime rt :source "mode")
            (%result :ok
                     :message (format nil "режим обновлён: язык=~A, вывод=~A, голос=~A, логика=~A, онтология=~A, оценка=~A"
                                      (string-upcase (symbol-name (runtime-lang rt)))
                                      (string-upcase (symbol-name (runtime-output-mode rt)))
                                      (runtime-active-voice rt)
                                      (%atom-name (runtime-logic-mode rt))
                                      (%atom-name (runtime-ontology-mode rt))
                                      (%atom-name (runtime-evaluation-mode rt)))))
           (t
            (%result :view
                     :entry (list :title "режим"
                                  :lines (list
                                          (format nil "язык: ~A" (string-upcase (symbol-name (runtime-lang rt))))
                                          (format nil "вывод: ~A" (string-upcase (symbol-name (runtime-output-mode rt))))
                                          (format nil "голос: ~A" (runtime-active-voice rt))
                                          (format nil "логика: ~A" (%atom-name (runtime-logic-mode rt)))
                                          (format nil "онтология: ~A" (%atom-name (runtime-ontology-mode rt)))
                                          (format nil "оценка: ~A" (%atom-name (runtime-evaluation-mode rt)))
                                          (format nil "активный мир: ~A" (%active-world-name rt))
                                          ""
                                          "пример:"
                                          "(режим :язык ru :голос предел :логика paraconsistent :онтология type :оценка heuristic)")))))))

      ((member head '("clear" "очистить") :test #'string=)
       (%result :clear))

      (t
       (%result :error
                :message (format nil "неизвестная голова формы: ~A" head))))))
