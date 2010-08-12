(defvar gimme-filter-header (propertize "GIMME" 'font-lock-face '(:foreground "#ff0000" :weight bold))) ;; FIXME: Find why why it isn't coloring
(defvar gimme-filter-mode-functions
  '(gimme-insert-song gimme-set-title message
                      gimme-filter-set-current-col
                      gimme-update-playtime))

(defun gimme-filter ()
  "Sets up the buffer"
  (interactive)
  (gimme-new-session)
  (get-buffer-create gimme-buffer-name)
  (setq gimme-current-mode 'filter)
  (with-current-buffer gimme-buffer-name
    (unlocking-buffer
     (gimme-filter-mode)
     (clipboard-kill-region 1 (point-max))
     (gimme-set-title (format "%s - %s"
                              gimme-filter-header
                              (gimme-filter-get-breadcrumbs)))
     (save-excursion
       (gimme-send-message "(pcol %s %s)\n" (gimme-tree-current-ref) gimme-session)))
   (switch-to-buffer (get-buffer gimme-buffer-name))))

(defvar gimme-filter-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "!") 'gimme-filter)
    (define-key map (kbd "@") 'gimme-tree)
    (define-key map (kbd "#") 'gimme-playlist)
    (define-key map (kbd "q") (lambda () (interactive) (kill-buffer gimme-buffer-name)))
    (define-key map (kbd "SPC") 'gimme-toggle)
    (define-key map (kbd "j") 'next-line)
    (define-key map (kbd "k") 'previous-line)
    (define-key map (kbd "J") 'gimme-next)
    (define-key map (kbd "K") 'gimme-prev)
    (define-key map (kbd "TAB") 'gimme-toggle-view)
    (define-key map (kbd "=") 'gimme-inc_vol) ;; FIXME: Better names, please!
    (define-key map (kbd "+") 'gimme-inc_vol)
    (define-key map (kbd "-") 'gimme-dec_vol)

    (define-key map (kbd "<") 'gimme-parent-col)
    (define-key map (kbd ">") 'gimme-child-col)
    (define-key map (kbd "a") 'gimme-filter-append-focused)
    (define-key map (kbd "RET") 'gimme-filter-play-focused)
    (define-key map (kbd "A") 'gimme-filter-append-collection)
    (define-key map (kbd "f") 'gimme-filter-same)
    map))

(defun gimme-filter-mode ()
  "FIXME: Write something here"
  (interactive)
  (kill-all-local-variables)
  (use-local-map gimme-filter-map)
  (setq truncate-lines t)
  (setq major-mode 'gimme-filter-mode
        mode-name "gimme-filter"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interactive Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gimme-child-col ()
  "Creates and displays a new collection intersecting the search criteria and the current collection"
  (interactive)
  (let* ((parent (gimme-tree-current-ref))
         (name (if (stringp parent) parent (getf (gimme-tree-current-data) 'name)))
         (name (read-from-minibuffer (format "%s > " name)))
         (message (format "(subcol %s %s)\n" parent (prin1-to-string name))))
    (setq gimme-new-collection-name (format "%s" name))
    (gimme-send-message message)))

(defun gimme-parent-col ()
  "Jumps to the current collection's parent collection."
  (interactive)
  (if (listp gimme-current)
      (setq gimme-current (butlast gimme-current)))
  (gimme-filter))

(defun gimme-filter-append-focused ()
  "Appends to the current playlist the focused song"
  (interactive)
  (gimme-send-message "(add %s)\n" (get-text-property (point) 'id)))

(defun gimme-filter-play-focused ()
  "Appends to the current playlist the focused song and then play it"
  (interactive)
  (gimme-send-message "(addplay %s)\n" (get-text-property (point) 'id)))

(defun gimme-filter-append-collection ()
  "Appends to the current playlist the entire collection"
  (interactive)
  (message "Appending songs to the playlist...")
  (dolist (el (range-to-plists (point-min) (point-max)))
    (gimme-send-message (format "(add %d)\n" (getf el 'id)))))

(defun gimme-filter-same ()
  "Creates a subcollection matching some this song's criteria"
  (interactive)
  (let* ((parent (gimme-tree-current-ref))
         (name (completing-read
                "Filter? "
                (mapcar (lambda (n) (format "%s:%s"
                                       (car n) (prin1-to-string
                                                (decode-coding-string (cdr n) 'utf-8))))
                        (remove-if (lambda (m) (member (car m)
                                                  '(id duration font-lock-face)))
                                   (plist-to-alist (text-properties-at (point)))))))
         (message (format "(subcol %s %s)\n" parent (prin1-to-string name))))
    (gimme-send-message message)))

(defun gimme-filter-get-breadcrumbs ()
  "Returns the current position as, eg, foo > bar > baz"
  (if (listp gimme-current)
      (loop for x = gimme-current then (butlast x)
            collecting (getf (car (gimme-tree-get-node x)) 'name) into names
            while x
            finally return (format "%s%s"
                                   (apply #'concat (mapcar (lambda (n) (format "%s > " n))
                                                           (reverse (cdr names))))
                                   (car names)))
    (format "%s" gimme-current)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Called by the ruby part ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun gimme-filter-set-current-col (ref)
  "Sets the current collection. Can be either a string or a list"
  (setq gimme-current
        (append (if (listp gimme-current) gimme-current nil)
                `(,(gimme-tree-add-child
                    `(name ,gimme-new-collection-name ref ,ref)
                    (when (listp gimme-current) gimme-current)))))
  (gimme-filter))


(provide 'gimme-filter)
