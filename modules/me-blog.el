;;; me-blog.el --- Programming stuff -*- lexical-binding: t; -*-
;;; ___________               __         .__
;;; \_   _____/ _____ _____ _/  |________|__|__  ___
;;;  |    __)_ /     \\__  \\   __\_  __ \  \  \/  /
;;;  |        \  Y Y  \/ __ \|  |  |  | \/  |>    <
;;; /_______  /__|_|  (____  /__|  |__|  |__/__/\_ \
;;;         \/      \/     \/                     \/
;;;
;;;  EMATRIX & LIGHTWEIGHT EMACS CONFIGURATION FRAMEWORK
;;;                        donneyluck.github.io/ematrix
;;;
;;; Author: donneyluck@gmail.com
;;; Copyright (C) 2022-2024  Machine Sudio

;;; Commentary:

;;; Code:

(require 'org)
(require 'ox-publish)
(require 'ox-html)
(require 'org-element)

(use-package ox-slimhtml
  :straight (:host github :repo "balddotcat/ox-slimhtml"))

(use-package citeproc
  :straight (:host github :repo "andras-simonyi/citeproc-el"))

(setq org-link-file-path-type 'relative)
(setq org-html-htmlize-output-type 'css)

(defvar my-org-blog-head
  (concat
   "<meta charset=\"utf-8\">"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
   "<link rel=\"stylesheet\" type=\"text/css\" href=\"css/style.css\">"))

(defvar my-org-blog-posts-head
  (concat
   "<meta charset=\"utf-8\">"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
   "<link rel=\"stylesheet\" type=\"text/css\" href=\"../css/style.css\">"))

(defvar my-org-preamble
  (concat
   "<nav class=\"navbar\">"
     "<a href=\"index.html\"> home </a>"
     "<a href=\"archive.html\"> stuff </a>"
     "<a href=\"about.html\"> about </a>"
     "<a href=\"#\"> <label for=\"theme-switch\" class=\"switch-label\"></label></a>"
     "</nav>"
     "<div id=\"content\">"))

(defvar my-org-blog-posts-preamble
  (concat
   "<nav class=\"navbar\">"
     "<a href=\"../index.html\"> home </a>"
     "<a href=\"../archive.html\"> stuff </a>"
     "<a href=\"../about.html\"> about </a>"
     "<a href=\"#\"> <label for=\"theme-switch\" class=\"switch-label\"></label></a>"
     "</nav>"
     "<div id=\"content\">"))

(defvar my-org-postamble
  (concat
   "<div id=\"postamble\">"
   "Made with Emacs :)\n"
   "<p>"
   "<a href=\"disclaimer.html\"> Disclaimer </a>\n"
   "</p>"
   "</div>"))

(defun my-ox-slimhtml-publish-to-html (plist filename pub-dir)
  "Publish a file to html.
PLIST is the property list, FILENAME the name of
the published file, PUB-DIR the publishing directory."
  (let ((file-path (ox-slimhtml-publish-to-html plist filename pub-dir)))
    (with-current-buffer (find-file-noselect file-path)
  (goto-char (point-min))
      (search-forward "<body>")
      (insert (mapconcat 'identity
                         '("<input type=\"checkbox\" class=\"theme-switch\" id=\"theme-switch\"/>"
                           "<div id=\"page\">")
                           "\n"))
      (goto-char (point-max))
      (search-backward "</body>")
      (insert "</div></div>")
      (save-buffer)
      (kill-buffer))
    file-path))

(defun my-org-publish-get-date-from-keyword (file project)
  "Get date keyword from FILE in PROJECT and parse it to internal format."
           (let ((date (org-publish-find-property file :date project)))
             (cond ((let ((ts (and (consp date) (assq 'timestamp date))))
                      (and ts
                           (let ((value (org-element-interpret-data ts)))
                             (and (org-string-nw-p value)
                                  (org-time-string-to-time value))))))
                   (t (error "No timestamp in file \"%s\"" file)))))

(defun my-org-blog-sitemap-format-entry (entry _style project)
  "Return format string for each ENTRY in PROJECT."
  (if (and (s-starts-with? "posts/" entry) (not (equal "disclaimer.org" (file-name-nondirectory entry))))
   (format "@@html:<span class=\"archive-item\"><span class=\"archive-date\">@@ %s @@html:</span>@@ [[file:%s][%s]]@@html:<div class=\"description\">@@ %s @@html:</div>@@ @@html:<div class=\"filetags\">@@ %s @@html:</div>@@ @@html:</span>@@"
            (format-time-string "[%d.%m.%Y %R %Z]"
                                (my-org-publish-get-date-from-keyword entry project))
            entry
            (org-publish-find-title entry project)
            (org-publish-find-property entry :description project 'html)
            (org-publish-find-property entry :filetags project 'html))))

(defun my-org-blog-sitemap-function (title list)
  "Return sitemap using TITLE and LIST returned by `my-org-blog-sitemap-format-entry'."
  (concat "#+TITLE: " title "\n\n"
          "#+ATTR_HTML: :class archive\n"
          "#+BEGIN_DIV\n"
          (mapconcat (lambda (li)
                       (format "@@html:<li>@@ %s @@html:</li>@@" (car li)))
                     (seq-filter #'car (cdr list))
                     "\n")
          "\n#+END_DIV\n"))

(defconst ematrix-blog-source-dir (concat ematrix-blog-dir "src/"))
(defconst ematrix-blog-website-dir (concat ematrix-blog-dir "website/"))
(defconst ematrix-blog-posts-dir (concat ematrix-blog-dir "src/posts/"))
(defconst ematrix-blog-posts-publish-dir (concat ematrix-blog-dir "website/posts/"))

(setq org-publish-project-alist
      `(("pages"
         :base-directory ,ematrix-blog-source-dir
         :exclude ".*drafts/.*"
         :html-doctype "html5"
         :html-head ,my-org-blog-head
         :html-postamble ,my-org-postamble
         :html-preamble ,my-org-preamble
         :publishing-directory ,ematrix-blog-website-dir
         :publishing-function my-ox-slimhtml-publish-to-html
         :recursive t

         ;; sitemap
         :auto-sitemap t
         :sitemap-filename "archive.org"
         :sitemap-format-entry my-org-blog-sitemap-format-entry
         :sitemap-function my-org-blog-sitemap-function
         :sitemap-style list
         :sitemap-title "stuff"
         :sitemap-sort-files anti-chronologically)

        ("posts"
         :base-directory ,ematrix-blog-posts-dir
         :exclude ".*drafts/.*"
         :html-doctype "html5"
         :html-head ,my-org-blog-posts-head
         :html-postamble ,my-org-postamble
         :html-preamble ,my-org-blog-posts-preamble
         :publishing-directory ,ematrix-blog-posts-publish-dir
         :publishing-function my-ox-slimhtml-publish-to-html
         :recursive t)

        ("assets"
         :base-directory ,ematrix-blog-source-dir
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf"
         :exclude ".*drafts/.*"
         :publishing-directory ,ematrix-blog-website-dir
         :publishing-function org-publish-attachment
         :recursive t)

         ("blog" :components ("pages" "posts" "assets"))))

(provide 'me-blog)
