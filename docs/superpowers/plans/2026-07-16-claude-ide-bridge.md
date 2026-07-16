# me-claude-ide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An Emacs package that impersonates a VS Code-style IDE so the Claude Code CLI `/ide` command auto-discovers Emacs and auto-injects the current selection.

**Architecture:** One package `modules/extras/me-claude-ide.el` using `websocket.el` (server). Emacs starts a loopback WS server on a random port, writes a lock file to `~/.claude/ide/<port>.lock`, pushes `selection_changed` notifications on region change, and answers `tools/list` + `tools/call` (read-only tools only). Wired into `me-ai`, on by default.

**Tech Stack:** Emacs Lisp (lexical-binding), `websocket.el` (github `ahyatt/emacs-websocket`), built-in `json`, built-in `flymake`.

## Global Constraints

- Lexical-binding: `t` on every new file (`;; -*- lexical-binding: t; -*-`).
- Follow ematrix file-header convention (see `modules/extras/me-writing-mode.el` lines 1-9): `;;; me-NAME.el --- DESC -*- lexical-binding: t; -*-`, author/copyright line, `;;; Commentary:`, `;;; Code:`, ends with `(provide 'me-NAME)` + `;;; me-NAME.el ends here`.
- Naming: ematrix uses `+`-prefixed private helpers (see `+evil-conf-for!` etc in `me-evil.el`). Internal helpers here use `+claude-ide--` prefix; the public minor mode is `claude-ide-bridge-mode`.
- Test runner: `emacs --batch -L . -l me-claude-ide-test.el -f claude-ide-run-tests` (plan defines this entrypoint; no framework beyond `ert`).
- Package deps added via `straight` in `me-ai.el` (straight is ematrix's package manager).
- 0-based line/character offsets in the protocol; Emacs is 1-based — convert with `1-`.
- Lock file dir `0700`, file `0600`. Use `~/.claude/ide/` unless `CLAUDE_CONFIG_DIR` set.

---

## File Structure

| File | Responsibility |
|------|----------------|
| `modules/extras/me-claude-ide.el` | The package: lock file, WS server, JSON-RPC dispatch, selection tracker, read-only tools, minor mode. |
| `modules/extras/me-claude-ide-test.el` | `ert` self-check: round-trip a WS client against the bridge. |
| `modules/me-ai.el` (modify) | Drop `claude-code-ide` (manzaltu); add `websocket` + `me-claude-ide`; drop the now-dead `SPC a` keybindings from `me-evil.el`. |
| `modules/me-evil.el` (modify) | Remove the `claude-code-ide-*` keybindings under the `;; ====== AI functions ======` block (lines ~185-197). |

---

## Task 1: Skeleton + lock file

**Files:**
- Create: `modules/extras/me-claude-ide.el`

**Interfaces:**
- Produces: `+claude-ide--config-dir`, `+claude-ide--lock-dir`, `+claude-ide--lock-path` (fn of port), `+claude-ide--auth-token`, `+claude-ide--port`, `+claude-ide--write-lock-file`, `+claude-ide--delete-lock-file`, `+claude-ide--pick-port`.

- [ ] **Step 1: Write the failing test**

Create `modules/extras/me-claude-ide-test.el`:

```elisp
;;; me-claude-ide-test.el --- tests for me-claude-ide -*- lexical-binding: t; -*-

;;; Code:
(require 'ert)
(require 'me-claude-ide)

(ert-deftest +claude-ide-test/lock-file-shape ()
  "Lock file is written with correct JSON shape and 0600 perms."
  (let* ((+claude-ide--port 54921)            ; fixed for the test
         (+claude-ide--auth-token "deadbeefdeadbeefdeadbeefdeadbeef")
         (tmpdir (make-temp-file "claude-ide-test-" t))
         (+claude-ide--lock-dir (file-name-concat tmpdir "ide")))
    (unwind-protect
        (progn
          (make-directory +claude-ide--lock-dir t)
          (set-file-modes +claude-ide--lock-dir #o700)
          (+claude-ide--write-lock-file)
          (let* ((path (+claude-ide--lock-path))
                 (json (with-temp-buffer
                         (insert-file-contents path)
                         (buffer-string)))
                 (data (json-read-from-string json)))
            (should (file-exists-p path))
            (should (= (file-modes path) #o600))
            (should (equal (map-elt data 'pid) (emacs-pid)))
            (should (equal (map-elt data 'transport) "ws"))
            (should (equal (map-elt data 'ideName) "Emacs"))
            (should (equal (map-elt data 'authToken)
                           "deadbeefdeadbeefdeadbeefdeadbeef"))
            (should (listp (map-elt data 'workspaceFolders)))))
      (+claude-ide--delete-lock-file)
      (when (file-exists-p tmpdir) (delete-directory tmpdir t)))))

(provide 'me-claude-ide-test)
;;; me-claude-ide-test.el ends here
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
emacs --batch -L modules/extras -l modules/extras/me-claude-ide-test.el \
  -f ert-run-tests-batch-and-exit
```
Expected: FAIL — `file me-claude-ide.el not found` / `void-variable +claude-ide--port` (package doesn't exist yet).

- [ ] **Step 3: Write minimal implementation**

Create `modules/extras/me-claude-ide.el`:

```elisp
;;; me-claude-ide.el --- Claude Code /ide bridge for Emacs -*- lexical-binding: t; -*-

;; Author: donneyluck@gmail.com

;;; Commentary:
;; Impersonates a VS Code-style IDE so the Claude Code CLI `/ide` command
;; auto-discovers this Emacs session and auto-injects the current selection.

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'seq)

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
          (setq port (cadr (process-contact server :local)))
          (when (or (not port) (< port 10000))
            (setq port (+ 10000 (random 55535))))
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
        (set-file-modes (buffer-file-name) #o600)
        (insert (json-encode data)))
      (set-file-modes path #o600))))

(defun +claude-ide--delete-lock-file ()
  "Remove the lock file for the current port, if present."
  (let ((path (+claude-ide--lock-path)))
    (when (and path (file-exists-p path))
      (delete-file path))))

(provide 'me-claude-ide)
;;; me-claude-ide.el ends here
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
emacs --batch -L modules/extras -l modules/extras/me-claude-ide-test.el \
  -f ert-run-tests-batch-and-exit
```
Expected: PASS — 1 test passed.

- [ ] **Step 5: Commit**

```bash
git add modules/extras/me-claude-ide.el modules/extras/me-claude-ide-test.el
git commit -m "feat(claude-ide): lock file skeleton"
```

---

## Task 2: JSON-RPC framing + offset conversion

**Files:**
- Modify: `modules/extras/me-claude-ide.el`
- Modify: `modules/extras/me-claude-ide-test.el`

**Interfaces:**
- Produces: `+claude-ide--point->pos` (converts an Emacs position to `(line . character)` 0-based), `+claude-ide--make-response`, `+claude-ide--make-error`, `+claude-ide--handle-message` (dispatch entry: takes a JSON string, returns a JSON string or nil for notifications).
- Consumes: none new.

- [ ] **Step 1: Write the failing tests**

Append to `me-claude-ide-test.el` (before `(provide ...)`):

```elisp
(ert-deftest +claude-ide-test/point->pos-0-based ()
  "Emacs 1-based positions become 0-based line/character."
  (with-temp-buffer
    (insert "abc\ndef\nghi")
    ;; point at beginning = line 1 col 1 -> 0,0
    (goto-char (point-min))
    (should (equal (+claude-ide--point->pos (point)) (cons 0 0)))
    ;; second line first char
    (forward-line 1)
    (should (equal (+claude-ide--point->pos (point)) (cons 1 0)))
    ;; third line third char (i)
    (forward-line 1)
    (forward-char 2)
    (should (equal (+claude-ide--point->pos (point)) (cons 2 2)))))

(ert-deftest +claude-ide-test/handle-tools-list ()
  "tools/list returns the five read-only tool names."
  (let ((resp (+claude-ide--handle-message
               (json-encode
                '((jsonrpc . "2.0") (method . "tools/list") (id . 1))))))
    (should resp)
    (let* ((data (json-read-from-string resp))
           (tools (map-nested-elt data '(result tools))))
      (should tools)
      (should (equal (sort (mapcar (lambda (t) (alist-get 'name t))
                                   (append tools nil))
                           #'string<)
                     (sort '("getCurrentSelection" "getLatestSelection"
                             "getOpenEditors" "getWorkspaceFolders"
                             "getDiagnostics")
                           #'string<))))))

(ert-deftest +claude-ide-test/handle-initialize ()
  "initialize responds with protocolVersion and tools capability."
  (let ((resp (+claude-ide--handle-message
               (json-encode
                '((jsonrpc . "2.0") (method . "initialize") (id . 1))))))
    (should resp)
    (let* ((data (json-read-from-string resp))
           (result (alist-get 'result data)))
      (should (alist-get 'protocolVersion result))
      (should (alist-get 'capabilities result))
      (should (alist-get 'serverInfo result)))))
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
emacs --batch -L modules/extras -l modules/extras/me-claude-ide-test.el \
  -f ert-run-tests-batch-and-exit
```
Expected: FAIL — `void-function +claude-ide--point->pos` / `void-function +claude-ide--handle-message`.

- [ ] **Step 3: Write minimal implementation**

Add to `me-claude-ide.el` before `(provide 'me-claude-ide)`:

```elisp
(defun +claude-ide--point->pos (pos)
  "Convert Emacs position POS to a (LINE . CHARACTER) cons, both 0-based."
  (save-excursion
    (goto-char pos)
    (let ((line (1- (line-number-at-pos pos))))
      ;; column is 0-based already via current-column
      (cons line (current-column)))))

(defun +claude-ide--make-response (id result)
  "Build a JSON-RPC success response string for ID with RESULT alist."
  (json-encode `((jsonrpc . "2.0") (id . ,id) (result . ,result))))

(defun +claude-ide--make-error (id code message)
  "Build a JSON-RPC error response string."
  (json-encode
   `((jsonrpc . "2.0") (id . ,id)
     (error . ((code . ,code) (message . ,message))))))

(defconst +claude-ide--tool-schemas
  `((name . "getCurrentSelection")
    (description . "Return the active editor selection, or empty if none.")
    (inputSchema . ((type . "object") (properties . ()) (required . nil))))
  "Stored as a list of schema alists below.")

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

(defun +claude-ide--handle-message (json-str)
  "Dispatch a JSON-RPC message JSON-STR. Return a response JSON string or nil."
  (let* ((msg (condition-case nil (json-read-from-string json-str)
                (error nil))))
    (unless msg (cl-return-from +claude-ide--handle-message nil))
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
           (t (+claude-ide--make-error id -32601 (format "Unknown tool: %s" name))))))
       (t (+claude-ide--make-error id -32601 (format "Unknown method: %s" method)))))))
```

Also add the tool implementation stubs near the top of the Code section (after the defvars from Task 1):

```elisp
(defvar +claude-ide--latest-selection nil
  "Last pushed selection alist, for pull.")

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
                 (or diags nil))))])))
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
emacs --batch -L modules/extras -l modules/extras/me-claude-ide-test.el \
  -f ert-run-tests-batch-and-exit
```
Expected: PASS — 4 tests passed.

- [ ] **Step 5: Commit**

```bash
git add modules/extras/me-claude-ide.el modules/extras/me-claude-ide-test.el
git commit -m "feat(claude-ide): JSON-RPC dispatch + read-only tools"
```

---

## Task 3: WebSocket server + selection push

**Files:**
- Modify: `modules/extras/me-claude-ide.el`
- Modify: `modules/extras/me-claude-ide-test.el`

**Interfaces:**
- Produces: `+claude-ide--start`, `+claude-ide--stop`, `claude-ide-bridge-mode`, `+claude-ide--on-open`, `+claude-ide--on-message`, `+claude-ide--on-close`, `+claude-ide--send` (send text to connected CLI), `+claude-ide--maybe-push-selection` (debounced hook fn).
- Consumes: `+claude-ide--handle-message`, `+claude-ide--current-selection`, `+claude-ide--write/delete-lock-file`, `+claude-ide--pick-port` from Tasks 1-2.

- [ ] **Step 1: Write the failing test**

Append to `me-claude-ide-test.el`:

```elisp
(ert-deftest +claude-ide-test/selection-pushes-notification ()
  "A region change sends a selection_changed JSON-RPC notification."
  (let ((received nil)
        (+claude-ide--conn nil))
    ;; stub the sender to capture instead of sending over a socket
    (let ((orig-sender (symbol-function '+claude-ide--send)))
      (unwind-protect
          (progn
            (fset '+claude-ide--send
                  (lambda (txt) (push txt received)))
            (with-temp-buffer
              (insert "hello world")
              (transient-mark-mode 1)
              (push-mark (point-min) t t)
              (goto-char (+ (point-min) 5))  ; select "hello"
              (+claude-ide--maybe-push-selection))
            (should received)
            (let* ((msg (json-read-from-string (car (last received))))
                   (method (alist-get 'method msg)))
              (should (equal method "selection_changed"))
              (should-not (alist-get 'id msg)) ; notification has no id
              (let* ((params (alist-get 'params msg))
                     (text (alist-get 'text params)))
                (should (equal text "hello")))))
        (when (fboundp 'orig-sender) (fset '+claude-ide--send orig-sender))))))
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
emacs --batch -L modules/extras -l modules/extras/me-claude-ide-test.el \
  -f ert-run-tests-batch-and-exit
```
Expected: FAIL — `void-function +claude-ide--maybe-push-selection` / `void-function +claude-ide--send`.

- [ ] **Step 3: Write minimal implementation**

Add `websocket` require at top of `me-claude-ide.el` (after `(require 'json)`):

```elisp
(require 'websocket nil t)
```

Add before `(provide 'me-claude-ide)`:

```elisp
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
  (when +claude-ide--conn
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
      (+claude-ide--send (json-encode notif)))))

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
```

Note: the `(provide ...)` and footer already exist from Task 1; in this step you are inserting everything above them and replacing the Task-1 `(provide 'me-claude-ide)` — keep exactly one provide and one footer at the end.

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
emacs --batch -L modules/extras -l modules/extras/me-claude-ide-test.el \
  -f ert-run-tests-batch-and-exit
```
Expected: PASS — 5 tests passed.

- [ ] **Step 5: Commit**

```bash
git add modules/extras/me-claude-ide.el modules/extras/me-claude-ide-test.el
git commit -m "feat(claude-ide): WS server + debounced selection push"
```

---

## Task 4: Wire into me-ai + clean dead keybindings

**Files:**
- Modify: `modules/me-ai.el`
- Modify: `modules/me-evil.el` (lines 185-197)

**Interfaces:**
- Produces: `me-ai` now loads `me-claude-ide` and the `websocket` straight dep; `SPC a` block in `me-evil.el` removed.

- [ ] **Step 1: Replace me-ai.el AI config**

Open `modules/me-ai.el`. Replace lines 1-18 (the `claude-code-ide` use-package block) with:

```elisp
;; me-ai.el --- AI assistants -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2024  Abdelhak Bougouffa

;; Author: Abdelhak Bougouffa (rot13 "nobhtbhssn@srqbencebwrpg.bet")

;;; Commentary:

;;; Code:

;; websocket: dependency of me-claude-ide
(use-package websocket
  :straight (:type git :host github :repo "ahyatt/emacs-websocket"))

;; me-claude-ide: impersonate a VS Code-style IDE so the Claude Code CLI
;; `/ide` command auto-discovers this Emacs and auto-injects the selection.
(use-package me-claude-ide
  :straight (:type git :host github :repo "donneyluck/me-claude-ide"
                   ;; local dev: keep the repo next to ematrix while developing.
                   :local-root "~/code/me-claude-ide")
  :after websocket
  :config
  (claude-ide-bridge-mode 1)
  ;; Auto-revert so Claude's file edits show up in buffers automatically.
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 1))
```

Note: the `:local-root` line assumes you'll keep the package in a separate repo during development. If you instead ship it inside ematrix (path `modules/extras/`), drop the `:straight` recipe and use:

```elisp
(use-package me-claude-ide
  :after websocket
  :config
  (claude-ide-bridge-mode 1)
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 1))
```

Decide based on whether the package lives in-tree or as its own repo. For in-tree (recommended for now), use the second form and delete the `:straight` line — `me-claude-ide.el` lives in `modules/extras/` which is already on `load-path`.

- [ ] **Step 2: Remove dead claude-code-ide keybindings from me-evil.el**

In `modules/me-evil.el`, delete lines 185-197 (the `;; ====== AI functions (claude-code-ide) ======` block). They bind `claude-code-ide-menu`, `claude-code-ide`, etc., which belong to the removed manzaltu package. The block starts with `"a"    '(nil :wk "ai menu")` and ends at `"a SPC" ...`. After deletion the `"q"` quit/session block follows directly.

- [ ] **Step 3: Byte-compile check**

Run:
```bash
emacs --batch -L modules -L modules/extras -f batch-byte-compile modules/me-ai.el
```
Expected: no errors (warnings about `websocket` being an unknown package are fine in batch). If `me-claude-ide` is in-tree, confirm it loads:

```bash
emacs --batch -L modules -L modules/extras \
  --eval "(condition-case e (progn (require 'me-ai)) (error (message \"LOAD-FAIL: %S\" e)))"
```
Expected: no `LOAD-FAIL` message.

- [ ] **Step 4: Commit**

```bash
git add modules/me-ai.el modules/me-evil.el
git commit -m "feat(claude-ide): wire into me-ai; drop dead claude-code-ide keys"
```

---

## Task 5: End-to-end verification against the real CLI

**Files:**
- Modify: `modules/extras/me-claude-ide-test.el` (optional smoke check — manual, not committed as ert)

**Interfaces:**
- Produces: confirmation that `claude` → `/ide` auto-discovers Emacs and shows a connected status; selection auto-injected.

- [ ] **Step 1: Start Emacs with the bridge**

Run in terminal A:
```bash
emacs -nw -L modules/extras -l modules/extras/me-claude-ide.el \
  --eval "(claude-ide-bridge-mode 1)"
```
Then in Emacs: `M-: (message "%d" +claude-ide--port)` to confirm a port printed, and check the lock file exists:
```bash
ls -l ~/.claude/ide/
```
Expected: one `*.lock` file, mode `-rw-------`.

- [ ] **Step 2: Connect from the real CLI**

Run in terminal B:
```bash
claude
```
Inside claude, run:
```
/ide
```
Expected: `/ide` shows a connection entry for Emacs (port matches the lock file). If it does NOT connect, this is the documented first-failure point: check whether a second WS connection is expected (see spec "Risk" — single vs dual). Capture the failure symptom before changing anything.

- [ ] **Step 3: Verify selection auto-injection**

In Emacs (terminal A), open a file and select a few lines (`V` in evil visual, or drag the region). Switch to terminal B and in `claude`, type a prompt like:
```
what did I just select?
```
Expected: the CLI references the selected text without you having pasted it. If it does not, fall back to the pull path: ask `claude` to call the `getCurrentSelection` tool explicitly and confirm it returns the selection.

- [ ] **Step 4: Record the result**

Append a one-line result to the plan file (or a scratch note): either `E2E OK: /ide connected, selection auto-injected` or `E2E FAIL: <symptom>`. If FAIL, do NOT mark the feature done — file the symptom and stop here for triage.

- [ ] **Step 5: Commit (only if OK)**

No code change in this task normally; if a fix was needed, commit it:
```bash
git add -A
git commit -m "fix(claude-ide): <what the e2e test forced>"
```

---

## Self-Review

**1. Spec coverage**
- Lock file (path/perms/JSON/ideName/transport/authToken/delete) → Task 1. ✓
- WS server 127.0.0.1 random port, auth header skipped → Task 3 (`+claude-ide--start`). ✓
- JSON-RPC initialize/initialized/tools/list/tools/call → Task 2. ✓
- `selection_changed` push, debounced 200ms → Task 3. ✓
- 0-based offset conversion → Task 2 (`+claude-ide--point->pos`). ✓
- Read-only tools (getCurrentSelection/getLatestSelection/getOpenEditors/getWorkspaceFolders/getDiagnostics) → Task 2. ✓
- Minor mode wired into me-ai, on by default → Task 4. ✓
- Auto-revert (already in me-ai) → preserved in Task 4. ✓
- End-to-end verification → Task 5. ✓
- websocket straight dep → Task 4. ✓

**2. Placeholder scan** — no TBD/TODO; every code step shows actual code; test code is concrete.

**3. Type consistency** — `+claude-ide--handle-message`, `+claude-ide--current-selection`, `+claude-ide--send`, `+claude-ide--maybe-push-selection`, `+claude-ide--start/stop`, `+claude-ide--point->pos`, `+claude-ide--tools` referenced in later tasks match their Task 2/3 definitions. `flymake-diagnostics` / `flymake--diag-text/type/beg/end` confirmed present in Emacs 30.2 batch probe.

One known risk carried from the spec: push-vs-pull and single-vs-dual WS connection are resolved by Task 5's real-CLI verification, not by assumption.
