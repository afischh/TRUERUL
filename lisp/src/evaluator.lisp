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
           (%push-form-log rt form)
           (%push-log rt (list :type :state
                               :target (%atom-name target)
                               :state (%atom-name state)))
           (%ok-or-silent rt
                          (format nil "состояние зарегистрировано: ~A :: ~A"
                                  (%atom-name target)
                                  (%atom-name state))))))

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
              (has-lang (or (%plist-has-key (cdr form) :lang)
                            (%plist-has-key (cdr form) :язык)))
              (has-output (or (%plist-has-key (cdr form) :output)
                              (%plist-has-key (cdr form) :вывод)))
              (lname (%atom-name lang))
              (oname (%atom-name output))
              (normalized (cond
                            ((string= lname "ru") :ru)
                            ((string= lname "en") :en)
                            (t nil)))
              (normalized-output (cond
                                   ((member oname '("clean" "result" "чисто" "результат") :test #'string=) :clean)
                                   ((member oname '("verbose" "build" "подробно" "сборка") :test #'string=) :verbose)
                                   (t nil))))
         (cond
           ((and has-lang (null normalized))
            (%result :error :message "режим ожидает :язык ru|en"))
           ((and has-output (null normalized-output))
            (%result :error :message "режим ожидает :вывод clean|verbose"))
           ((or normalized normalized-output)
            (when normalized
              (setf (runtime-lang rt) normalized))
            (when normalized-output
              (setf (runtime-output-mode rt) normalized-output))
            (%result :ok
                     :message (format nil "режим обновлён: язык=~A, вывод=~A"
                                      (string-upcase (symbol-name (runtime-lang rt)))
                                      (string-upcase (symbol-name (runtime-output-mode rt))))))
           (t
            (%result :error :message "режим ожидает :язык ru|en и/или :вывод clean|verbose")))))

      ((member head '("clear" "очистить") :test #'string=)
       (%result :clear))

      (t
       (%result :error
                :message (format nil "неизвестная голова формы: ~A" head))))))
