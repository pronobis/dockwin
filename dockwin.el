;;; dockwin.el -- Lightweight Docking Windows for Emacs

;; Copyright (C) 2015 Andrzej Pronobis

;; Author: Andrzej Pronobis <a.pronobis@gmail.com>
;; Package-Requires: ((dash "2.10.0"))
;; Package-Requires: ((s "1.9.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Please see https://github.com/pronobis/dockwin for a documentation.

;;; Code:

(require 'dash)
(require 's)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defgroup dockwin nil
  "Site docking windows for Emacs"
  :group 'convenience
  :prefix "dockwin-")

(defcustom dockwin-bottom-height-min 6
  "Bottom window size when inactive."
  :type 'integer
  :group 'dockwin)
(defcustom dockwin-bottom-height-max 20
  "Bottom window size when active."
  :type 'integer
  :group 'dockwin)
(defcustom dockwin-top-height-min 6
  "Top window size when inactive."
  :type 'integer
  :group 'dockwin)
(defcustom dockwin-top-height-max 20
  "Top window size when active."
  :type 'integer
  :group 'dockwin)
(defcustom dockwin-left-width-min 10
  "Left window size when inactive."
  :type 'integer
  :group 'dockwin)
(defcustom dockwin-left-width-max 30
  "Left window size when active."
  :type 'integer
  :group 'dockwin)
(defcustom dockwin-right-width-min 10
  "Right window size when inactive."
  :type 'integer
  :group 'dockwin)
(defcustom dockwin-right-width-max 30
  "Right window size when active."
  :type 'integer
  :group 'dockwin)

(defcustom dockwin-default-position 'bottom
  "Default docking window position for a buffer.
This must be one of: left, top, right, or bottom.  This value
can be overridden by a property in `dockwin-buffer-settings'."
  :type 'symbol
  :group 'dockwin)

(defcustom dockwin-default-kill nil
  "If not nil, buffers in docking windows will be killed by default.
This value can be overridden by a property in `dockwin-buffer-settings'."
  :type 'boolean
  :group 'dockwin)

(defcustom dockwin-default-activate t
  "If not nil, windows will be activated by default when buffers are displayed.
This value can be overridden by a property in `dockwin-buffer-settings'."
  :type 'boolean
  :group 'dockwin)

(defcustom dockwin-default-catch-switching nil
  "If not nil, `switch-to-buffer' events will be caught as well.
Some buffers are displayed in the current window using
`switch-to-buffer' rather than `display-buffer', e.g. term.  Using
this option will allow for displaying such buffers in the docking
windows as well.  However, this will make it impossible to display
the buffer in a non-docking window, e.g. using \\[switch-to-buffer].
After catching such event, window will always be activated.
This value can be overridden by a property in `dockwin-buffer-settings'."
  :type 'boolean
  :group 'dockwin)

(defcustom dockwin-buffer-settings
  '(;; Bottom window
    (completion-list-mode     :activate f :kill t)
    (compilation-mode         :activate f)
    (help-mode)
    (flycheck-error-list-mode)
    (inferior-python-mode)
    (term-mode                :catch-switching t)
    ("\\*MATLAB\\*"           :catch-switching t)
    ("\\*Backtrace\\*"        :kill t)
    ("\\*Process List\\*")
    ("\\*Messages\\*")
    ;; Right window
    (" *undo-tree*"           :position right)
    )
  "Per-buffer settings.

Determine which buffers should be shown in docking windows and
how they should be displayed.  The value is a list of CONFIG which
should be of the form (PATTERN . PROPERTIES) where PATTERN is
characterizing the buffer and PROPERTIES is a list of KEYWORDS
and VALUES.  PATTERN can be a buffer name matching regexp, or a
symbol specifying the `major-mode' of the buffer.  Note, that for
some buffers, the major mode symbol will not work as the mode is
set after the buffer is displayed (for those, use the regexp
name instead).  The first matching configuration is used.

Available keywords:
  :position - The docking window which should be used for
              the buffer.  Possible values:
              `top', `bottom', `left', `right'
  :activate - If set to 't, the docking window will be activated when
              this buffer is displayed.  If set to 'f, the docking
              window will not be activated by DockWin.  If set to nil,
              default value will be used.  Note, that if some other
              Emacs code activates the window, DockWin will not
              prevent it even if this is set to nil.
  :kill     - If set to 't, always kill the buffer on quit.  If set
              to 'f, do not kill the buffer on quit.  If set to nil,
              use default.
  :catch-switching - If set to 't, `switch-to-buffer' events will
              be caught as well.  If set to 'f, those events will not
              be caught.  If set to nil, default value will be used.
              Some buffers are displayed in the current window
              using `switch-to-buffer' rather than
              `display-buffer', e.g. term.  Using this option will
              allow for displaying such buffers in the docking
              windows as well.  However, this will make it
              impossible to display the buffer in a non-docking
              window, e.g. using \\[switch-to-buffer].  After
              catching such event, window will always be activated."
  :type '(repeat
          (cons :tag "Config"
                (choice :tag "Pattern"
                        (string :tag "Buffer Name Regexp")
                        (symbol :tag "Major Mode"))
                (plist :tag "Properties"
                       :options
                       ((:position (choice :tag "Window Position"
                                           (const :tag "Bottom" bottom)
                                           (const :tag "Top" top)
                                           (const :tag "Left" left)
                                           (const :tag "Right" right)))
                        (:activate (choice :tag "Activate Window"
                                           (const :tag "Yes" t)
                                           (const :tag "No" f)
                                           (const :tag "Default" nil)))
                        (:kill (choice :tag "Kill Window on Quit"
                                       (const :tag "Yes" t)
                                       (const :tag "No" f)
                                       (const :tag "Default" nil)))
                        ))))
  :get (lambda (symbol)
         (mapcar (lambda (element)
                   (if (consp element)
                       element
                     (list element)))
                 (default-value symbol)))
  :group 'dockwin)

(defcustom dockwin-add-buffers-to-modeline t
  "Set nil if you want to disable the modeline buffer list for docking windows."
  :type 'boolean
  :group 'dockwin)

(defcustom dockwin-trim-special-buffer-names t
  "If not nil, asterisks will be trimmed from special buffer names in mode-line."
  :type 'boolean
  :group 'dockwin)

(defcustom dockwin-on-kill 'deactivate
  "Determines what should be done when a buffer is killed.
If set to 'close, the window is closed.  If set to 'deactivate,
the window is deactivated.  If set to nil, nothing happens."
  :type 'symbol
  :group 'dockwin)

(defcustom dockwin-on-quit 'deactivate
  "Determines what should be done when `quit-window' happens.
If set to 'close, the window is closed.  If set to 'deactivate,
the window is deactivated.  If set to nil, nothing happens."
  :type 'symbol
  :group 'dockwin)

(defface dockwin-mode-line-separator-face
  '((t (:background nil)))
  "Face used for separators on DockWin mode-line."
  :group 'dockwin)

(defface dockwin-mode-line-current-buffer-face
  '((t (:inherit mode-line-buffer-id :weight bold)))
  "Face used to display current buffer on DockWin mode-line."
  :group 'dockwin)

(defface dockwin-mode-line-other-buffer-face
  '((t (:background nil :weight normal)))
  "Face used to display other buffers on DockWin mode-line."
  :group 'dockwin)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Frame-local internal variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dockwin--get-bottom-window (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--bottom-window))
(defun dockwin--get-bottom-buffer-history (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--bottom-buffer-history))
(defun dockwin--get-top-window (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--top-window))
(defun dockwin--get-top-buffer-history (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--top-buffer-history))
(defun dockwin--get-left-window (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--left-window))
(defun dockwin--get-left-buffer-history (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--left-buffer-history))
(defun dockwin--get-right-window (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--right-window))
(defun dockwin--get-right-buffer-history (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--right-buffer-history))
(defun dockwin--get-window-history (&optional frame)
  "Get FRAME local variable value.  FRAME defaults to current frame."
  (frame-parameter frame 'dockwin--window-history))

(defun dockwin--set-bottom-window (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--bottom-window . ,value))))
(defun dockwin--set-bottom-buffer-history (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--bottom-buffer-history . ,value))))
(defun dockwin--set-top-window (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--top-window . ,value))))
(defun dockwin--set-top-buffer-history (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--top-buffer-history . ,value))))
(defun dockwin--set-left-window (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--left-window . ,value))))
(defun dockwin--set-left-buffer-history (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--left-buffer-history . ,value))))
(defun dockwin--set-right-window (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--right-window . ,value))))
(defun dockwin--set-right-buffer-history (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--right-buffer-history . ,value))))
(defun dockwin--set-window-history (value &optional frame)
  "Set the frame local variable to VALUE in FRAME.  FRAME defaults to current frame."
  (modify-frame-parameters frame `((dockwin--window-history . ,value))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Buffer configuration handlers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dockwin--get-buffer-settings (buf &optional ignore)
  "Return the configuration for the buffer BUF or nil if not found.
BUF can be a buffer or a buffer name.  If the configuration is
empty, return true, otherwise, return a list of properties.
The IGNORE argument is required by
`display-buffer-alist'."
  (if (stringp buf)
      (setq buf (get-buffer buf)))
  (when buf
    (let ((buf-mm (with-current-buffer buf
                    major-mode))
          (buf-name (buffer-name buf))
          (buf-config nil)
          (case-fold-search nil))         ; Case sensitive
      ;; (message "DockWin: querying settings for buffer %s with major mode %s" buf-name buf-mm)
      (setq buf-config
            (--first
             (cond ((symbolp (car it))
                    (eq (car it) buf-mm))
                   ((stringp (car it))
                    (string-match-p (car it) buf-name)))
             dockwin-buffer-settings))
      (when buf-config
        (or (cdr buf-config) t)))))

(defun dockwin--get-position-property (buf-config)
  "Return the position property value given the BUF-CONFIG."
  (-let (((&plist :position position) buf-config))
    (or position dockwin-default-position 'bottom)))

(defun dockwin--get-activate-property (buf-config)
  "Return the activate property value given the BUF-CONFIG."
  (-let (((&plist :activate activate) buf-config))
    (eq (or activate dockwin-default-activate) t)))  ; Non-t means false

(defun dockwin--get-kill-property (buf-config)
  "Return the kill property value given the BUF-CONFIG."
  (-let (((&plist :kill kill) buf-config))
    (eq (or kill dockwin-default-kill) t)))   ; Non-t means false

(defun dockwin--get-catch-switching-property (buf-config)
  "Return the catch-switching property value given the BUF-CONFIG."
  (-let (((&plist :catch-switching catch-switching) buf-config))
    (eq (or catch-switching dockwin-default-catch-switching) t)))  ; Non-t means false



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;  Getters/setters/checkers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dockwin--get-window-position (window)
  "Return position of the given WINDOW if it's a live docking window.
If it's not a live docking window, return nil.  This searches for
windows in all frames."
  (and (window-live-p window)
       (--reduce-from (or acc
                          (and (eq window (dockwin--get-bottom-window it)) 'bottom)
                          (and (eq window (dockwin--get-top-window it)) 'top)
                          (and (eq window (dockwin--get-left-window it)) 'left)
                          (and (eq window (dockwin--get-right-window it)) 'right))
                      nil               ; Init value
                      (frame-list))))

(defun dockwin--get-buffer-history (position &optional frame)
  "Return buffer history at POSITION in FRAME.
FRAME defaults to current frame."
  (cond ((eq position 'bottom) (dockwin--get-bottom-buffer-history frame))
        ((eq position 'top) (dockwin--get-top-buffer-history frame))
        ((eq position 'left) (dockwin--get-left-buffer-history frame))
        ((eq position 'right) (dockwin--get-right-buffer-history frame))))

(defun dockwin--set-buffer-history (position history &optional frame)
  "Set buffer history at POSITION to HISTORY in FRAME.
FRAME defaults to current frame."
  (cond ((eq position 'bottom) (dockwin--set-bottom-buffer-history history frame))
        ((eq position 'top) (dockwin--set-top-buffer-history history frame))
        ((eq position 'left) (dockwin--set-left-buffer-history history frame))
        ((eq position 'right) (dockwin--set-right-buffer-history history frame))))

(defun dockwin--get-window (position &optional frame)
  "Return the current window at POSITION in FRAME if it's live.
Otherwise return nil.  FRAME defaults to current frame.
Position must be one of: top, bottom, left, right."
  (let ((window (cond ((eq position 'bottom) (dockwin--get-bottom-window frame))
                      ((eq position 'top) (dockwin--get-top-window frame))
                      ((eq position 'left) (dockwin--get-left-window frame))
                      ((eq position 'right) (dockwin--get-right-window frame)))))
    (if (window-live-p window)
        window
      nil)))

(defun dockwin--set-window (position window &optional frame)
  "Set the current window at POSITION to WINDOW in FRAME.
FRAME defaults to current frame."
  (cond ((eq position 'bottom) (dockwin--set-bottom-window window frame))
        ((eq position 'top) (dockwin--set-top-window window frame))
        ((eq position 'left) (dockwin--set-left-window window frame))
        ((eq position 'right) (dockwin--set-right-window window frame))))

(defun dockwin--get-buffer (position &optional frame)
  "Return the most recent, live buffer from history at POSITION in FRAME.
If no such buffer in history, try any live buffer that would
match the window.  If none such buffer found, return nil.
FRAME defaults to current frame.  Position must be one of:
top, bottom, left, right."
  (or
   (--first (buffer-live-p it)
            (dockwin--get-buffer-history position frame))
   (--first (let ((conf (dockwin--get-buffer-settings it)))
              (and conf (eq (dockwin--get-position-property conf) position)))
            (buffer-list frame))))

(defun dockwin--get-buffers (position &optional frame)
  "Return the list of live buffers matching the window at POSITION in FRAME.
The buffers are ordered according to history (most recent first).
If a buffer was never added to history, the order is unspecified,
but certainly after all buffers present in history.  If none such
buffer found, return nil.  FRAME defaults to current frame.
Position must be one of: top, bottom, left, right."
  (-union
   (--filter (buffer-live-p it)
            (dockwin--get-buffer-history position frame))
   (--filter (let ((conf (dockwin--get-buffer-settings it)))
              (and conf (eq (dockwin--get-position-property conf) position)))
            (buffer-list frame))))

(defun dockwin--trim-buffer-name (buffer)
  "Prepare trimmed buffer name for given BUFFER."
  (let ((bn (s-trim (buffer-name buffer))))
    (if dockwin-trim-special-buffer-names
        (s-chop-suffix "*" (s-chop-prefix "*" bn))
      bn)))

(defun dockwin--get-buffers-sorted (position &optional frame)
  "Return the list of live buffers matching the window at POSITION in FRAME.
The buffers are sorted alphabetically.  If none such buffer
found, return nil.  FRAME defaults to current frame.  Position
must be one of: top, bottom, left, right."
  (--sort (string< (dockwin--trim-buffer-name it)
                   (dockwin--trim-buffer-name other))
   (--filter (let ((conf (dockwin--get-buffer-settings it)))
               (and conf (eq (dockwin--get-position-property conf) position)))
             (buffer-list frame))))

(defun dockwin--add-buffer-to-history (position buffer &optional frame)
  "Add to buffer history at POSITION the given BUFFER in FRAME.
FRAME defaults to current frame."
  (let ((history (dockwin--get-buffer-history position frame)))
    ;; Add to list
    (setq history (delq buffer history))
    (add-to-list 'history buffer)
    ;; Clear list of dead buffers
    (dockwin--set-buffer-history position
          (-filter 'buffer-live-p history) frame)))

(defun dockwin--burry-buffer-in-history (position buffer &optional frame)
  "Burry the BUFFER in history at POSITION in FRAME.
FRAME defaults to current frame."
  (let ((history (dockwin--get-buffer-history position frame)))
    ;; Add to list
    (setq history (delq buffer history))
    (add-to-list 'history buffer t)
    ;; Clear list of dead buffers
    (dockwin--set-buffer-history position
                                 (-filter 'buffer-live-p history) frame)))

(defun dockwin--add-window-to-history (win &optional frame)
  "Add the window WIN to the history in FRAME.
If it is already in the history, just bring it to the front.
Do not add windows which have the no-other-window param or
MiniBuffer.  FRAME defaults to current frame."
  (let ((history (dockwin--get-window-history frame)))
    (unless (or (window-parameter win 'no-other-window)
                (window-minibuffer-p win))
      ;; Add to list
      (setq history (delq win history))
      (add-to-list 'history win)
      ;; Clear list of closed windows
      (setq history (-filter 'window-live-p history))
      (dockwin--set-window-history history frame))))

(defun dockwin--get-previous-window (&optional frame)
  "Return the most recent, non-selected, live window from history in FRAME.
FRAME defaults to current frame."
  (--first (and (not (eq it (selected-window)))
                (window-live-p it))
           (dockwin--get-window-history frame)))

(defun dockwin--get-next-buffer (position &optional frame)
  "Return the next buffer in docking window at POSITION in FRAME.
This assumes that buffers are sorted alphabetically.
FRAME defaults to current frame.  Position must be one of:
top, bottom, left, right."
  (let* ((buf (dockwin--get-buffer position frame))
         (buf-list (dockwin--get-buffers-sorted position frame))
         (ind (-elem-index buf buf-list))
         result)
    (when ind
      (setq ind (mod (1+ ind) (length buf-list)))
      (nth ind buf-list))))

(defun dockwin--get-previous-buffer (position &optional frame)
  "Return the previous buffer in docking window at POSITION in FRAME.
This assumes that buffers are sorted alphabetically.
FRAME defaults to current frame.  Position must be one of:
top, bottom, left, right."
  (let* ((buf (dockwin--get-buffer position frame))
         (buf-list (dockwin--get-buffers-sorted position frame))
         (ind (-elem-index buf buf-list))
         result)
    (when ind
      (setq ind (mod (1- ind) (length buf-list)))
      (nth ind buf-list))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Window behavior
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dockwin--select-window (orig-fun &rest args)
  "Advice for `select-window' epanding/collapsing docking windows and
adding the previous window to history. This function operates on the
frame of the given window."
  (let* ((win-from (selected-window))
        (win-from-frame (window-frame win-from))
        (win-to (car args))
        (win-to-frame (window-frame win-to))
        recenter)
    ;; Collapse the docking windows
    (when (and (window-live-p (dockwin--get-bottom-window win-from-frame))
               (eq win-from (dockwin--get-bottom-window win-from-frame)))
      (enlarge-window (- dockwin-bottom-height-min (window-height))))
    (when (and (window-live-p (dockwin--get-top-window win-from-frame))
               (eq win-from (dockwin--get-top-window win-from-frame)))
      (enlarge-window (- dockwin-top-height-min (window-height))))
    (when (and (window-live-p (dockwin--get-left-window win-from-frame))
               (eq win-from (dockwin--get-left-window win-from-frame)))
      (enlarge-window (- dockwin-left-width-min (window-width)) t))
    (when (and (window-live-p (dockwin--get-right-window win-from-frame))
               (eq win-from (dockwin--get-right-window win-from-frame)))
      (enlarge-window (- dockwin-right-width-min (window-width)) t))
    ;; Add win-to to history
    (dockwin--add-window-to-history win-to win-to-frame)
    ;; Run the original function
    (apply orig-fun args)
    ;; Expand the docking window
    (when (and (window-live-p (dockwin--get-bottom-window win-to-frame))
               (eq win-to (dockwin--get-bottom-window win-to-frame)))
      (enlarge-window (- dockwin-bottom-height-max (window-height)))
      (setq recenter t))
    (when (and (window-live-p (dockwin--get-top-window win-to-frame))
               (eq win-to (dockwin--get-top-window win-to-frame)))
      (enlarge-window (- dockwin-top-height-max (window-height)))
      (setq recenter t))
    (when (and (window-live-p (dockwin--get-left-window win-to-frame))
               (eq win-to (dockwin--get-left-window win-to-frame)))
      (enlarge-window (- dockwin-left-width-max (window-width)) t)
      (setq recenter t))
    (when (and (window-live-p (dockwin--get-right-window win-to-frame))
               (eq win-to (dockwin--get-right-window win-to-frame)))
      (enlarge-window (- dockwin-right-width-max (window-width)) t)
      (setq recenter t))
    ;; Recenter the view
    (when (and recenter
               (equal (point-max)
                      (window-end nil t)))
      (save-excursion
        (goto-char (point-max))
        (recenter -1)))
    ;; Update keymap for docking windows
    (dockwin--buffer-mode-update-keymap)
    ;; Return win-to
    win-to))
;; Add the adivce
(advice-add 'select-window :around #'dockwin--select-window)

(defun dockwin--create-window (position)
  "Create a new docking window at POSITION.
Return the window."
  (cond ((eq position 'bottom)
         (split-window (frame-root-window)
                       (- dockwin-bottom-height-min) 'below))
        ((eq position 'top)
         (split-window (frame-root-window)
                       (- dockwin-top-height-min) 'above))
        ((eq position 'left)
         (split-window (frame-root-window)
                       (- dockwin-left-width-min) 'left))
        ((eq position 'right)
         (split-window (frame-root-window)
                       (- dockwin-right-width-min) 'right))))

(defun dockwin--display-buffer-function (buffer alist)
  "Display a docking window BUFFER with action ALIST in a docking window.
The caller can pass \(ignore-activate . t\) as an element of the action
alist to indicate that the docking window should never be activated (no
matter what the buffer settings say).  This function operates on the
current frame."
  (let* ((config (dockwin--get-buffer-settings buffer))
         (position (dockwin--get-position-property config))
         (activate (dockwin--get-activate-property config))
         (window (dockwin--get-window position))
         (ignore-activate (cdr (assq 'ignore-activate alist))))
      ;; Check if the current window is live. If not, create a new one.
      (unless window
        (setq window (dockwin--create-window position)))
      ;; Set current window and buffer
      (dockwin--set-window position window)
      (dockwin--add-buffer-to-history position buffer)
      ;; Display buffer
      (window--display-buffer buffer window 'window alist)
      ;; Make the window dedicated so that nothing else can display there
      (set-window-dedicated-p window t)
      ;; Make other-window skip that window
      (set-window-parameter window 'no-other-window t)
      (with-current-buffer buffer
        ;; Disable any scroll margin for buffers in horizontal windows
        (when (or (eq position 'top) (eq position 'bottom))
          (make-local-variable 'scroll-margin)
          (setq scroll-margin 0))
        ;; Add our minor mode
        (dockwin-buffer-mode 1))
      ;; Select the window if it should become active
      (when (and (not ignore-activate) activate)
        (select-window window t))         ; No-record for dock buffers
      ;; Return window
      window))
;; Use the action
(add-to-list 'display-buffer-alist
             '(dockwin--get-buffer-settings
               (dockwin--display-buffer-function)))

(defun dockwin--split-window-function (window)
  "Prevent the docking windows from being split.
WINDOW used as in `split-window-sensibly'."
  (if (dockwin--get-window-position window)
      nil
   (split-window-sensibly window)))
;; Use the function
(setq split-window-preferred-function 'dockwin--split-window-function)

;; Killing / quitting behavior. Implemented in
;; dockwin--quit-window and dockwin--kill-buffer:
;; -> Not in docking window
;;    - normal quit or kill
;; -> In docking window
;; ---> Kill buffer
;;      Note: Actual buffer killing must be done first,
;;            otherwise buffers with process will cause trouble
;; -----> On kill: close
;;        - kill buffer (protect window from closing)
;;        - close window (this goes to previous window)
;; -----> On kill: deactivate
;;        - kill buffer (protect window from closing)
;;        - show the new current buffer
;;        - if no other buffer in window, close window
;;        - otherwise, go to previous window
;; -----> On kill: nil
;;        - kill buffer (protect window from closing)
;;        - show the new current buffer
;;        - if no other buffer in window, close window
;; ---> Bury buffer
;; -----> On kill: close
;;        - bury buffer in history
;;        - close window (this goes to previous window)
;; -----> On kill: deactivate
;;        - bury buffer in history
;;        - show the new current buffer
;;        - go to previous window
;; -----> On kill: nil
;;        - bury buffer in history
;;        - show the new current buffer

(defun dockwin--quit-restore-window (orig-fun &rest args)
  "Advice `quit-restore-window' to implement quitting behavior for docking windows.
It is better than advicing `quit-window' since sometimes `quit-restore-window'
is being used directly (e.g. in case of the backtrace window).
This behavior is conditional on `dockwin-on-quit' and the `:kill' property
of `dockwin-buffer-settings'. This function operates on the frame of
the window."
  (let* ((window (window-normalize-window (nth 0 args) t))
         (frame (window-frame window))
         (buffer (window-buffer window))
         (config (dockwin--get-buffer-settings buffer))
         (position (dockwin--get-window-position window))
         (kill (or (and config
                        (dockwin--get-kill-property config))
                   (eq (nth 1 args) 'kill))))
    (if (not position)
        ;; Not in docking window
        (funcall orig-fun
                 (nth 0 args)
                 (if kill
                     'kill
                     (nth 1 args)))
      ;; In docking window
      (if kill
          ;; Passing to the kill advice
          (kill-buffer buffer)
        ;; Bury buffer
        (dockwin--burry-buffer-in-history position buffer frame)
        (setq buffer (dockwin--get-buffer position frame))  ; Get new current
        (cond ((eq dockwin-on-quit 'close)
               (dockwin-close-window position frame))
              ((eq dockwin-on-quit 'deactivate)
               (dockwin--display-buffer-function buffer ; Don't activate
                                                 '((ignore-activate . t)))
               (dockwin-go-to-previous-window))
              (t
               (dockwin--display-buffer-function buffer ; Don't activate
                                                 '((ignore-activate . t)))))))))
;; Use the advice
(advice-add 'quit-restore-window :around #'dockwin--quit-restore-window)

(defun dockwin--switch-to-buffer (orig-fun &rest args)
  "Advice `switch-to-buffer' to display docking buffers in docking window instead
of the current one."
  (let* ((buffer-or-name (nth 0 args))
         (buffer (window-normalize-buffer-to-switch-to buffer-or-name))
         (window (selected-window))
         (orig-buf (window-buffer window))  ; (current-buffer) is already affected
         (config (dockwin--get-buffer-settings buffer)))
    ;; If we're switching to a buffer that should be docked
    ;; and we should be catching switching for this buffer
    ;; and we are in a non-docking window
    (if (and config
             (dockwin--get-catch-switching-property config)
             (not (dockwin--get-window-position window)))
        ;; Display the buffer in a docking window and select it
        ;; We choose to always select the window since it might be unsafe
        ;; if after switch-to-buffer we are in a different buffer than
        ;; the one requested.
        (select-window
         (dockwin--display-buffer-function buffer  ; Don't activate internally
                                           '((ignore-activate . t))))
      ;; Run the original function
      (apply orig-fun args))
    ;; Return buffer
    buffer))
;; Use the advice
(advice-add 'switch-to-buffer :around #'dockwin--switch-to-buffer)

(defun dockwin--kill-buffer (orig-fun &rest args)
  "Advice `kill-buffer' to control the post kill docking window behavior.
This behavior is conditional on `dockwin-on-kill'."
  (let* ((buffer (or (nth 0 args) (current-buffer)))
         (window (get-buffer-window buffer))
         (frame (window-frame window))
         (position (dockwin--get-window-position window)))
    (if (not position)
        ;; Not in docking window
        (apply orig-fun args)
      ;; In docking window
      (unwind-protect  ; Kill buffer and keep the window
          (progn (set-window-dedicated-p window nil)
                 (apply orig-fun args))
        (set-window-dedicated-p window t))
      (setq buffer (dockwin--get-buffer position frame))  ; Get new current
      (cond ((eq dockwin-on-kill 'close)
             (dockwin-close-window position frame))
            ((eq dockwin-on-kill 'deactivate)
             (if (not buffer)
                 (dockwin-close-window position frame)
               (dockwin--display-buffer-function buffer ; Don't activate
                                                 '((ignore-activate . t)))
               (dockwin-go-to-previous-window)))
            (t
             (if (not buffer)
                 (dockwin-close-window position frame)
               (dockwin--display-buffer-function buffer ; Don't activate
                                                 '((ignore-activate . t)))))))))
;; Use the advice
(advice-add 'kill-buffer :around #'dockwin--kill-buffer)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Public functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defalias 'dockwin-get-window 'dockwin--get-window)
(defalias 'dockwin-get-buffer 'dockwin--get-buffer)

(defun dockwin-clear-history ()
  "Clear all window and buffer history."
  (dockwin--set-window-history nil)
  (dockwin--set-bottom-buffer-history nil)
  (dockwin--set-top-buffer-history nil)
  (dockwin--set-left-buffer-history nil)
  (dockwin--set-right-buffer-history nil))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Interactive public functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dockwin-go-to-previous-window ()
  "Go to previous non-docking window.
If there is no history, go to other window."
  (interactive)
  (let ((window (dockwin--get-previous-window)))
    (if window
        (select-window window)
      (other-window 1))))

(defun dockwin-create-window (position)
  "Create the docking window at POSITION if not yet created.
Show the most recent buffer in the window.
If there is no buffer to show, display message.
Return the window."
  (interactive)
  (unless (eq major-mode 'minibuffer-inactive-mode)  ; Safety mechanism for things like helm
    (let ((window (dockwin--get-window position))
          (buffer (dockwin--get-buffer position)))
      ;; If no window already
      (unless window
        ;; Check if we have a buffer for this window
        (if buffer
            ;; Recreate the window with previous buffer
            (setq window
                  (dockwin--display-buffer-function buffer  ; Don't activate
                                                    '((ignore-activate . t))))
          ;; Otherwise, report an error
          (message "No buffer to display")))
      window)))

(defun dockwin-create-bottom-window ()
  "Create the bottom docking window if not yet created.
Show the most recent buffer in the window.
If there is no buffer to show, display message."
  (interactive)
  (dockwin-create-window 'bottom))

(defun dockwin-create-top-window ()
  "Create the top docking window if not yet created.
Show the most recent buffer in the window.
If there is no buffer to show, display message."
  (interactive)
  (dockwin-create-window 'top))

(defun dockwin-create-left-window ()
  "Create the left docking window if not yet created.
Show the most recent buffer in the window.
If there is no buffer to show, display message."
  (interactive)
  (dockwin-create-window 'left))

(defun dockwin-create-right-window ()
  "Create the right docking window if not yet created.
Show the most recent buffer in the window.
If there is no buffer to show, display message."
  (interactive)
  (dockwin-create-window 'right))

(defun dockwin-activate-window (position)
  "Activate the docking window at POSITION if it's live.
If not, create it, activate it and show the most recent buffer.
If there is no buffer to show, display message.  Return the window."
  (interactive)
  (unless (eq major-mode 'minibuffer-inactive-mode)  ; Safety mechanism for things like helm
      (let ((window (dockwin-create-window position)))
        ;; If window is live
        (when window
          (select-window window)))))

(defun dockwin-activate-bottom-window ()
  "Activate the bottom docking window if it's live.
If not, create it, activate it and show the most recent buffer.
If there is no buffer to show, display message.  Return the window."
  (interactive)
  (dockwin-activate-window 'bottom))

(defun dockwin-activate-top-window ()
  "Activate the top docking window if it's live.
If not, create it, activate it and show the most recent buffer.
If there is no buffer to show, display message.  Return the window."
  (interactive)
  (dockwin-activate-window 'top))

(defun dockwin-activate-left-window ()
  "Activate the left docking window if it's live.
If not, create it, activate it and show the most recent buffer.
If there is no buffer to show, display message.  Return the window."
  (interactive)
  (dockwin-activate-window 'left))

(defun dockwin-activate-right-window ()
  "Activate the right docking window if it's live.
If not, create it, activate it and show the most recent buffer.
If there is no buffer to show, display message.  Return the window."
  (interactive)
  (dockwin-activate-window 'right))

(defun dockwin-toggle-bottom-window ()
  "Activate the bottom docking window if it's not active.
If it is active, return to previous non-docking window."
  (interactive)
  (if (dockwin--get-window-position (selected-window))
      (dockwin-go-to-previous-window)
    (dockwin-activate-window 'bottom)))

(defun dockwin-toggle-top-window ()
  "Activate the top docking window if it's not active.
If it is active, return to previous non-docking window."
  (interactive)
  (if (dockwin--get-window-position (selected-window))
      (dockwin-go-to-previous-window)
    (dockwin-activate-window 'top)))

(defun dockwin-toggle-left-window ()
  "Activate the left docking window if it's not active.
If it is active, return to previous non-docking window."
  (interactive)
  (if (dockwin--get-window-position (selected-window))
      (dockwin-go-to-previous-window)
    (dockwin-activate-window 'left)))

(defun dockwin-toggle-right-window ()
  "Activate the right docking window if it's not active.
If it is active, return to previous non-docking window."
  (interactive)
  (if (dockwin--get-window-position (selected-window))
      (dockwin-go-to-previous-window)
    (dockwin-activate-window 'right)))

(defun dockwin-close-window (&optional position frame)
  "Close the docking window at POSITION in FRAME if it's live.
If not, do nothing.  If POSITION is nil, try to close the
currently selected window.  FRAME defaults to current frame"
  (interactive)
  (unless position
    (setq position (dockwin--get-window-position (selected-window))))
  (let ((window (dockwin--get-window position frame)))
    (when window
      (dockwin-go-to-previous-window)
      (delete-window window))))

(defun dockwin-close-top-window ()
  "Close the top docking window if it's live.  If not, do nothing."
  (interactive)
  (dockwin-close-window 'top))

(defun dockwin-close-bottom-window ()
  "Close the bottom docking window if it's live.  If not, do nothing."
  (interactive)
  (dockwin-close-window 'bottom))

(defun dockwin-close-left-window ()
  "Close the left docking window if it's live.  If not, do nothing."
  (interactive)
  (dockwin-close-window 'left))

(defun dockwin-close-right-window ()
  "Close the right docking window if it's live.  If not, do nothing."
  (interactive)
  (dockwin-close-window 'right))

(defun dockwin-switch-to-buffer (&optional position)
  "Switch buffer in the window at POSITION to other valid buffer in that window.
If POSITION is nil, and inside a docking window, use the current window position."
  (interactive)
  (unless position
    (setq position (dockwin--get-window-position (selected-window))))
  (when position
    (let* ((buffer-list (dockwin--get-buffers position))
           (buffer-names (-map 'buffer-name buffer-list))
           (window (dockwin--get-window position)))
      (when buffer-names
        ;; If the dockwindow is showing the first buffer, make the buffer last
        (if (and window (eq (car buffer-list) (window-buffer window)))
            (setq buffer-names (-rotate -1 buffer-names)))
        ;; Choose and display the new buffer
        (select-window
         (display-buffer
          (ido-completing-read "Switch to buffer: " buffer-names)))))))

(defun dockwin-kill-buffer (&optional position)
  "Kill the current buffer in window at POSITION.
If POSITION is nil, use the currently selected window."
  (interactive)
  (unless position
    (setq position (dockwin--get-window-position (selected-window))))
  (let ((window (dockwin--get-window position))
        cur-buf)
    (when window
      (setq cur-buf (window-buffer window))
      (kill-buffer cur-buf))))

(defun dockwin-next-buffer (&optional position)
  "Display the next buffer in docking window at POSITION.
The next buffer is the next one in the alphabetical order.
Position must be one of: top, bottom, left, right."
  (interactive)
  (unless position
    (setq position (dockwin--get-window-position (selected-window))))
  (let ((window (dockwin--get-window position))
         buffer)
    (when window
      (setq buffer (dockwin--get-next-buffer position))
      (when buffer
        (dockwin--display-buffer-function buffer  ; Don't activate
                                          '((ignore-activate . t)))))))

(defun dockwin-previous-buffer (&optional position)
  "Display the previous buffer in docking window at POSITION.
The previous buffer is the previous one in the alphabetical order.
Position must be one of: top, bottom, left, right."
  (interactive)
  (unless position
    (setq position (dockwin--get-window-position (selected-window))))
  (let ((window (dockwin--get-window position))
        buffer)
    (when window
      (setq buffer (dockwin--get-previous-buffer position))
      (when buffer
        (dockwin--display-buffer-function buffer  ; Don't activate
                                          '((ignore-activate . t)))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; dockwin-buffer-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar dockwin-buffer-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x C-b")       'dockwin-switch-to-buffer)
    (define-key map (kbd "C-x C-g")       'dockwin-close-window)
    (define-key map (kbd "C-x C-<left>")  'dockwin-previous-buffer)
    (define-key map (kbd "C-x C-<right>") 'dockwin-next-buffer)
    map)
  "Keymap for DockWin buffers when displayed in docking windows.")

(defun dockwin--buffer-mode-update-keymap ()
  "Update the current keymap in dockwin-buffer-mode.
It disables the keymap for buffers not shown in a docking window."
  (setq minor-mode-map-alist (--map-when (eq (car it) 'dockwin-buffer-mode)
                                         (if (dockwin--get-window-position (selected-window))
                                             (cons 'dockwin-buffer-mode dockwin-buffer-mode-map)
                                           (cons 'dockwin-buffer-mode nil))
                                         minor-mode-map-alist))
  nil)

(define-minor-mode dockwin-buffer-mode
  "DockWin buffer mode.

The mode provides additional key bindings for buffers shown in
DockWin windows.

Interactively with no argument, this command
toggles the mode. A positive prefix argument enables the mode,
any other prefix argument disables it. From Lisp, argument
omitted or nil enables the mode, `toggle' toggles the state."
  :init-value nil
  :lighter " DockWinB"
  :keymap dockwin-buffer-mode-map
  ;; Make this minor mode survive major mode change
  (put 'dockwin-buffer-mode 'permanent-local t)
  ;; Add modeline
  (dockwin--add-mode-line)
  (add-hook 'after-change-major-mode-hook  ; Needed in case the major mode
            'dockwin--add-mode-line))      ; is changed



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Modeline
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defconst dockwin--mode-line-format '(:eval (dockwin--get-mode-line)))

(defun dockwin--get-mode-line ()
  "Return mode-line string for the current docking window."
  (let ((position (dockwin--get-window-position (selected-window))))
    (if position
        ;; Buffer is in a docking window
        (concat
         (propertize "│" 'face 'dockwin-mode-line-separator-face)
         (--reduce-from (let ((bn (propertize (dockwin--trim-buffer-name it)
                                              'face
                                              (if (eq it (current-buffer))
                                                  'dockwin-mode-line-current-buffer-face
                                                'dockwin-mode-line-other-buffer-face))))
                          (if acc (concat acc
                                          (propertize "│" 'face 'dockwin-mode-line-separator-face)
                                          bn) bn))
                        nil (dockwin--get-buffers-sorted position))
         (propertize "│" 'face 'dockwin-mode-line-separator-face))
      ;; Buffer is not in a docking window
      (propertize (buffer-name) 'face 'mode-line-buffer-id))))

(defsubst dockwin--mode-line-set-p ()
  "Check if DockWin modeline is set."
  (and (listp mode-line-format)
       (member dockwin--mode-line-format mode-line-format)))

(defun dockwin--add-mode-line ()
  "Add DockWin info to modeline."
  (when (and dockwin-add-buffers-to-modeline
             (dockwin--get-buffer-settings (current-buffer))
             (not (dockwin--mode-line-set-p)))
    (setq mode-line-buffer-identification dockwin--mode-line-format)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Setting up other Emacs packages to work best with DockWin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let DockWin control what gets activated
(setq help-window-select nil)



(provide 'dockwin)
;;; dockwin.el ends here
