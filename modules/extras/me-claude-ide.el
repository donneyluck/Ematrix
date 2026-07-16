;;; me-claude-ide.el --- Claude Code /ide bridge for Emacs -*- lexical-binding: t; -*-

;; Author: donneyluck@gmail.com

;;; Commentary:
;; Impersonates a VS Code-style IDE so the Claude Code CLI `/ide` command
;; auto-discovers this Emacs session and auto-injects the current selection.

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'websocket nil t)

(defgroup claude-ide nil
  "Claude Code /ide bridge."
  :group 'tools)

(defcustom claude-ide-bridge-enable t
  "Non-nil enables the bridge on `me-ai' load."
  :type 'boolean)

(defvar +claude-ide--port nil
  "Port the WS server listens on.")

(defvar +claude-ide--auth-token nil
  "Auth token written into the lock file (not verified on connect).")

(defvar +claude-ide--lock-dir nil
  "Directory holding the lock file. Bound per session.")

(defun +claude-ide--config-dir ()
  "Return the Claude config directory."
  (let ((env (getenv "CLAUDE_CONFIG_DIR")))
    (if (and env (not (string-empty-p env)))
        (expand-file-name env)
      (expand-file-name "~/.claude"))))

(defun +claude-ide--lock-path ()
  "Return the lock file path for the current port."
  (and +claude-ide--lock-dir +claude-ide--port
       (expand-file-name (format "%d.lock" +claude-ide--port)
                         +claude-ide--lock-dir)))

(defun +claude-ide--gen-token ()
  "Return a 32-char hex token."
  (let ((bytes (lambda () (random 256))))
    ;; random is seeded by Emacs at startup; fine for a local nonce.
    (mapconcat (lambda (_)
                 (let ((b (funcall bytes)))
                   (format "%02x" b)))
               (make-list 16 0) "")))

(defun +claude-ide--pick-port ()
  "Return a free port in 10000-65535."
  ;; Open a transient listening socket to grab a free ephemeral port, then close.
  (let (server port)
    (unwind-protect
        (progn
          (setq server (make-network-process :name "claude-ide-portprobe"
                                            :server t
                                            :host "127.0.0.1"
                                            :service t
                                            :family 'ipv4))
          ;; `process-contact' returns [HOST ... PORT] as a vector on
          ;; Emacs 27+; the port is the last element regardless of shape.
          (setq port (let ((local (process-contact server :local)))
                       (if (vectorp local) (aref local (1- (length local)))
                         (car (last local)))))
          (when (or (not port) (< port 10000) (> port 65535))
            (setq port (+ 10000 (random 55536))))
          port)
      (when server (delete-process server)))))

(defun +claude-ide--workspace-folders ()
  "Return a list of workspace root absolute paths."
  (let ((root (condition-case nil
                  (vc-root-dir)
                (error nil))))
    (list (or (and root (expand-file-name root))
              (expand-file-name default-directory)))))

(defun +claude-ide--write-lock-file ()
  "Write the lock file for the current port/token."
  (let ((path (+claude-ide--lock-path))
        (data `((pid . ,(emacs-pid))
                (workspaceFolders . ,(+claude-ide--workspace-folders))
                (ideName . "Emacs")
                (transport . "ws")
                (authToken . ,+claude-ide--auth-token))))
    (when path
      (make-directory +claude-ide--lock-dir t)
      (with-temp-file path
        (insert (json-encode data)))
      (set-file-modes path #o600))))

(defun +claude-ide--delete-lock-file ()
  "Remove the lock file for the current port, if present."
  (let ((path (+claude-ide--lock-path)))
    (when (and path (file-exists-p path))
      (delete-file path))))

;; ── JSON-RPC: offset conversion ────────────────────────────────

(defun +claude-ide--point->pos (pos)
  "Convert Emacs position POS to a (LINE . CHARACTER) cons, both 0-based."
  (save-excursion
    (goto-char pos)
    (list (1- (line-number-at-pos pos)) (current-column))))

;; ── JSON-RPC: response builders ────────────────────────────────

(defun +claude-ide--make-response (id result)
  "Build a JSON-RPC success response string for ID with RESULT alist."
  (json-encode `((jsonrpc . "2.0") (id . ,id) (result . ,result))))

(defun +claude-ide--make-error (id code message)
  "Build a JSON-RPC error response string."
  (json-encode
   `((jsonrpc . "2.0") (id . ,id)
     (error . ((code . ,code) (message . ,message))))))

;; ── Tool schemas ───────────────────────────────────────────────

(defun +claude-ide--tools ()
  "Return the list of tool schema alists."
  (let ((names-descs
         '(("getCurrentSelection" . "Return the active editor selection, or empty if none.")
           ("getLatestSelection" . "Return the most recently recorded selection.")
           ("getOpenEditors" . "Return open file-backed buffers.")
           ("getWorkspaceFolders" . "Return workspace root paths.")
           ("getDiagnostics" . "Return flymake diagnostics for the active buffer."))))
    (mapcar (lambda (nd)
              `((name . ,(car nd))
                (description . ,(cdr nd))
                (inputSchema . ((type . "object") (properties . nil) (required . nil)))))
            names-descs)))

;; ── Shared state ───────────────────────────────────────────────

(defvar +claude-ide--latest-selection nil
  "Last pushed selection alist, for pull.")

;; ── Tool implementations ───────────────────────────────────────

(defun +claude-ide--current-selection ()
  "Return an alist describing the current region (or empty)."
  (if (region-active-p)
      (let* ((beg (region-beginning))
             (end (region-end))
             (buf (current-buffer))
             (file (buffer-file-name buf)))
        `((success . t)
          (text . ,(buffer-substring-no-properties beg end))
          (filePath . ,(and file (expand-file-name file)))
          (selection . ((start . ,(append (+claude-ide--point->pos beg) nil))
                        (end . ,(append (+claude-ide--point->pos end) nil))
                        (isEmpty . :json-false)))))
    '((success . :json-false))))

(defun +claude-ide--open-editors ()
  "Return open file-backed buffers as a tabs alist."
  (let (tabs)
    (dolist (buf (buffer-list))
      (let ((file (buffer-file-name buf)))
        (when file
          (push `((uri . ,(concat "file://" (expand-file-name file)))
                  (isActive . ,(eq buf (current-buffer)))
                  (label . ,(file-name-nondirectory file))
                  (languageId . ,(symbol-name (buffer-local-value 'major-mode buf)))
                  (isDirty . ,(buffer-modified-p buf)))
                tabs))))
    `((tabs . ,(vconcat tabs)))))

(defun +claude-ide--workspace-folders-result ()
  "Return workspace folders result alist."
  (let ((root (car (+claude-ide--workspace-folders))))
    `((success . t)
      (rootPath . ,root)
      (folders . [((name . ,(file-name-nondirectory (directory-file-name root)))
                   (uri . ,(concat "file://" root))
                   (path . ,root))]))))

(defun +claude-ide--diagnostics ()
  "Return flymake diagnostics for the current buffer as an alist."
  (require 'flymake nil t)
  (let ((file (buffer-file-name))
        (diags (condition-case nil (flymake-diagnostics) (error nil))))
    `[(,(if file (concat "file://" (expand-file-name file)) "")
       .
       ,(vconcat
         (mapcar (lambda (d)
                   `((message . ,(flymake--diag-text d))
                     (severity . ,(symbol-name (or (flymake--diag-type d) 'warning)))
                     (range . ((start . ,(append (+claude-ide--point->pos
                                                  (flymake--diag-beg d)) nil))
                               (end . ,(append (+claude-ide--point->pos
                                                (flymake--diag-end d)) nil))))))
                 (or diags nil))))]))

;; ── JSON-RPC dispatch ──────────────────────────────────────────

(defun +claude-ide--handle-message (json-str)
  "Dispatch a JSON-RPC message JSON-STR. Return a response JSON string or nil."
  (let* ((msg (condition-case nil (json-read-from-string json-str)
                (error nil))))
    (when msg
      (let ((method (alist-get 'method msg))
            (id (alist-get 'id msg)))
        (cond
         ((equal method "initialize")
          (+claude-ide--make-response
           id `((protocolVersion . "2025-03-26")
                (capabilities . ((tools . nil)))
                (serverInfo . ((name . "Emacs") (version . "0.1"))))))
         ((equal method "initialized") nil) ; notification, no response
         ((equal method "tools/list")
          (+claude-ide--make-response
           id `((tools . ,(+claude-ide--tools)))))
         ((equal method "tools/call")
          (let ((name (alist-get 'name (alist-get 'params msg))))
            (cond
             ((equal name "getCurrentSelection")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--current-selection))))]))))
             ((equal name "getLatestSelection")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode
                                           (or +claude-ide--latest-selection
                                               '((success . :json-false))))))]))))
             ((equal name "getOpenEditors")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--open-editors))))]))))
             ((equal name "getWorkspaceFolders")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--workspace-folders-result))))]))))
             ((equal name "getDiagnostics")
              (+claude-ide--make-response
               id `((content . [((type . "text")
                                 (text . ,(json-encode (+claude-ide--diagnostics))))]))))
             (t (when id (+claude-ide--make-error id -32601 (format "Unknown tool: %s" name)))))))
         (t (when id (+claude-ide--make-error id -32601 (format "Unknown method: %s" method)))))))))

;; ── WebSocket server ───────────────────────────────────────────

(defvar +claude-ide--server nil
  "The websocket server process, or nil.")

(defvar +claude-ide--conn nil
  "The current client websocket (bridge supports one CLI at a time).")

(defvar +claude-ide--debounce-timer nil
  "Debounce timer for selection pushes.")

(defvar +claude-ide--last-selection-key nil
  "Stringified (file . beg . end) of the last pushed selection.")

(defun +claude-ide--send (txt)
  "Send TXT as a WS text frame to the connected CLI, if any."
  (when (and +claude-ide--conn (fboundp 'websocket-send-text))
    (condition-case nil
        (websocket-send-text +claude-ide--conn txt)
      (error nil))))

(defun +claude-ide--push-selection (sel)
  "Push a selection_changed notification built from SEL alist."
  ;; No +claude-ide--conn guard here — +claude-ide--send checks it.
  ;; This lets tests stub +claude-ide--send without needing a live conn.
  (let* ((file (alist-get 'filePath sel))
         (start (alist-get 'start (alist-get 'selection sel)))
         (end (alist-get 'end (alist-get 'selection sel)))
         (text (alist-get 'text sel))
         (notif `((jsonrpc . "2.0")
                  (method . "selection_changed")
                  (params . ((text . ,text)
                             (filePath . ,file)
                             (fileUrl . ,(and file (concat "file://" file)))
                             (selection . ((start . ,start)
                                           (end . ,end)
                                           (isEmpty . ,(if (string-empty-p text)
                                                           t :json-false)))))))))
    (+claude-ide--send (json-encode notif))))

(defun +claude-ide--maybe-push-selection ()
  "Debounced: push the current selection if it changed."
  (when (timerp +claude-ide--debounce-timer)
    (cancel-timer +claude-ide--debounce-timer))
  (setq +claude-ide--debounce-timer
        (run-with-idle-timer 0.2 nil #'+claude-ide--do-push-selection)))

(defun +claude-ide--do-push-selection ()
  "Actual push, run after debounce."
  (when (region-active-p)
    (let* ((beg (region-beginning))
           (end (region-end))
           (file (buffer-file-name))
           (key (format "%S:%d:%d" file beg end)))
      (unless (equal key +claude-ide--last-selection-key)
        (setq +claude-ide--last-selection-key key)
        (let ((sel (+claude-ide--current-selection)))
          (setq +claude-ide--latest-selection sel)
          (+claude-ide--push-selection sel))))))

(defun +claude-ide--on-open (ws)
  "Called when the CLI connects."
  (setq +claude-ide--conn ws))

(defun +claude-ide--on-message (_ws frame)
  "Called when the CLI sends a JSON-RPC message."
  (let* ((txt (websocket-frame-text frame))
         (resp (+claude-ide--handle-message txt)))
    (when resp (+claude-ide--send resp))))

(defun +claude-ide--on-close (_ws)
  "Called when the CLI disconnects."
  (setq +claude-ide--conn nil))

(defun +claude-ide--on-error (_ws _type _err)
  "Log, don't crash."
  (message "claude-ide: websocket error"))

(defun +claude-ide--start ()
  "Start the bridge: pick port, start WS server, write lock file."
  (unless (fboundp 'websocket-server)
    (user-error "websocket.el not installed; install ahyatt/emacs-websocket"))
  (unless +claude-ide--server
    (setq +claude-ide--lock-dir (expand-file-name "ide" (+claude-ide--config-dir)))
    (make-directory +claude-ide--lock-dir t)
    (set-file-modes +claude-ide--lock-dir #o700)
    (setq +claude-ide--port (+claude-ide--pick-port)
          +claude-ide--auth-token (+claude-ide--gen-token))
    (setq +claude-ide--server
          (websocket-server
           +claude-ide--port
           :host "127.0.0.1"
           :on-open #'+claude-ide--on-open
           :on-message #'+claude-ide--on-message
           :on-close #'+claude-ide--on-close
           :on-error #'+claude-ide--on-error))
    (+claude-ide--write-lock-file)
    (add-hook 'post-command-hook #'+claude-ide--maybe-push-selection)
    (message "claude-ide: bridge on port %d" +claude-ide--port)))

(defun +claude-ide--stop ()
  "Stop the bridge, delete the lock file."
  (when (timerp +claude-ide--debounce-timer)
    (cancel-timer +claude-ide--debounce-timer))
  (remove-hook 'post-command-hook #'+claude-ide--maybe-push-selection)
  (when +claude-ide--server
    (when (fboundp 'websocket-server-close)
      (websocket-server-close +claude-ide--server))
    (setq +claude-ide--server nil))
  (setq +claude-ide--conn nil)
  (+claude-ide--delete-lock-file))

;;;###autoload
(define-minor-mode claude-ide-bridge-mode
  "Toggle the Claude Code /ide bridge."
  :global t
  :group 'claude-ide
  (if claude-ide-bridge-mode
      (+claude-ide--start)
    (+claude-ide--stop)))

(provide 'me-claude-ide)
;;; me-claude-ide.el ends here
