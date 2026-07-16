;;; me-claude-ide-test.el --- tests for me-claude-ide -*- lexical-binding: t; -*-

;; Author: donneyluck@gmail.com

;;; Commentary:
;; Tests for me-claude-ide.

;;; Code:
(require 'ert)
(require 'map)
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
            (should (vectorp (map-elt data 'workspaceFolders)))))
      (+claude-ide--delete-lock-file)
      (when (file-exists-p tmpdir) (delete-directory tmpdir t)))))

(ert-deftest +claude-ide-test/point->pos-0-based ()
  "Emacs 1-based positions become 0-based {line,character} objects."
  (with-temp-buffer
    (insert "abc\ndef\nghi")
    ;; point at beginning = line 1 col 1 -> {line:0,character:0}
    (goto-char (point-min))
    (should (equal (+claude-ide--point->pos (point)) '((line . 0) (character . 0))))
    ;; second line first char
    (forward-line 1)
    (should (equal (+claude-ide--point->pos (point)) '((line . 1) (character . 0))))
    ;; third line third char (i)
    (forward-line 1)
    (forward-char 2)
    (should (equal (+claude-ide--point->pos (point)) '((line . 2) (character . 2))))))

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

(ert-deftest +claude-ide-test/handle-unknown-method ()
  "unknown method returns JSON-RPC error -32601."
  (let ((resp (+claude-ide--handle-message
               (json-encode
                '((jsonrpc . "2.0") (method . "bogus/method") (id . 1))))))
    (should resp)
    (let* ((data (json-read-from-string resp))
           (err (alist-get 'error data)))
      (should err)
      (should (= (alist-get 'code err) -32601))
      (should (string-match "Unknown method" (alist-get 'message err))))))

(ert-deftest +claude-ide-test/notification-no-response ()
  "A JSON-RPC notification (no id) gets no response, even for unknown methods."
  (let ((resp (+claude-ide--handle-message
               (json-encode
                '((jsonrpc . "2.0") (method . "someUnknownMethod"))))))
    (should (null resp))))

(ert-deftest +claude-ide-test/selection-pushes-notification ()
  "A region change sends a selection_changed JSON-RPC notification."
  (let ((received nil)
        (+claude-ide--conn nil)
        (+claude-ide--last-selection-key nil))
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
              ;; Call do-push directly: idle timers don't fire in batch ert.
              (+claude-ide--do-push-selection))
            (should received)
            (let* ((msg (json-read-from-string (car (last received))))
                   (method (alist-get 'method msg)))
              (should (equal method "selection_changed"))
              (should-not (alist-get 'id msg)) ; notification has no id
              (let* ((params (alist-get 'params msg))
                     (text (alist-get 'text params)))
                (should (equal text "hello")))))
        (when (fboundp 'orig-sender) (fset '+claude-ide--send orig-sender))))))

(provide 'me-claude-ide-test)
;;; me-claude-ide-test.el ends here
