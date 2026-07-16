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

(provide 'me-claude-ide-test)
;;; me-claude-ide-test.el ends here
