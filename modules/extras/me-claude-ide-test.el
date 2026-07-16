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

(provide 'me-claude-ide-test)
;;; me-claude-ide-test.el ends here
