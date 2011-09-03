;;; gimme-help.el --- GIMME Interesting Music on My Emacs

;; Author: Konrad Scorciapino <konr@konr.mobi>
;; Keywords: XMMS2, mp3

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary

;; This file contains functions related to the help functionalities,
;; including integration with the wiki.

;;; Code

(defun gimme-help-show-keybindings ()
  (interactive)
  (message "oi")
  (let* ((name "GIMME - Keybindings")
         (map (cdr (current-local-map)))
         (docs (loop for k in map when (and (numberp (car k)) (functionp (cdr k)))
                     collect `(key ,(format "%c" (car k)) function ,(cdr k) docs ,(documentation (cdr k)))
		     into list-that-needs-to-be-reverted
		     finally return (reverse list-that-needs-to-be-reverted)))
	 (header "Here are the currently set Keybindings.\n\n---\n\n"))
    (gimme-on-buffer
     name
     (delete-region (point-min) (point-max))
     (insert header)
     (loop for plist in docs doing
           (let* ((key (propertize (plist-get plist 'key) 'font-lock-face '(:weight bold)))
		  (nodocs (propertize "FIXME: NO DOCS FOUND!" 'font-lock-face '(:foreground "#ff0000")))
		  (docs (car (split-string (or (plist-get plist 'docs) nodocs) "\n")))
		  (docs (format "%s" (plist-get plist 'function)))) 
	     (insert (format "%s\t%s\n" key docs))))
     (font-lock-mode 1)
     (use-local-map (gimme-make-basic-map))
     (switch-to-buffer name)
     )))

(provide 'gimme-help)
;;; gimme-help.el ends here