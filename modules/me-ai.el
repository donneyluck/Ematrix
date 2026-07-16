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
  :after websocket
  :config
  (claude-ide-bridge-mode 1)
  ;; Auto-revert so Claude's file edits show up in buffers automatically.
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 1))

;; 以前的 AI 配置，改用 claude-code-ide，注释掉备用
;; (use-package ai-code
;;   :straight (:host github :repo "tninja/ai-code-interface.el")
;;   :config
;;   ;; use codex as backend, other options are 'gemini, 'github-copilot-cli, 'opencode, 'grok, 'claude-code-ide, 'claude-code, 'cursor
;;   (ai-code-set-backend 'cursor)
;;   ;; Enable global keybinding for the main menu
;;   ;; (global-set-key (kbd "C-c a") #'ai-code-menu) ;; Optional: Use eat if you prefer, by default it is vterm
;;   ;; (setq ai-code-backends-infra-terminal-backend 'eat) ;; for openai codex, github copilot cli, opencode, grok; for claude-code-ide.el, you can check their config
;;   ;; Optional: Turn on auto-revert buffer, so that the AI code change automatically appears in the buffer
;;   (global-auto-revert-mode 1)
;;   (setq auto-revert-interval 1) ;; set to 1 second for faster update
;;   ;; Optional: Set up Magit integration for AI commands in Magit popups
;;   (with-eval-after-load 'magit
;;     (ai-code-magit-setup-transients)))


;; (use-package aider
;;   :straight
;;   :config
;;   ;; For latest claude sonnet model
;;   (setq aider-args '("--model" "sonnet" "--no-auto-accept-architect"))
;;   (setenv "ANTHROPIC_API_KEY" anthropic-api-key)
;;   ;; Or gemini model
;;   ;; (setq aider-args '("--model" "gemini"))
;;   ;; (setenv "GEMINI_API_KEY" <your-gemini-api-key>)
;;   ;; Or chatgpt model
;;   ;; (setq aider-args '("--model" "o4-mini"))
;;   ;; (setenv "OPENAI_API_KEY" <your-openai-api-key>)
;;   ;; Or use your personal config file
;;   ;; (setq aider-args `("--config" ,(expand-file-name "~/.aider.conf.yml")))
;;   ;; ;;
;;   ;; Optional: Set a key binding for the transient menu
;;   ;; (global-set-key (kbd "C-c a") 'aider-transient-menu) ;; for wider screen
;;   ;; or use aider-transient-menu-2cols / aider-transient-menu-1col, for narrow screen
;;   (aider-magit-setup-transients)) ;; add aider magit function to magit menu

;; (use-package llm
;;   :straight t)

;; (use-package llm-ollama
;;   :straight llm
;;   :autoload make-llm-ollama +ollama-serve +ollama-kill-server +ollama-list-installed-models
;;   :config
;;   (defvar +ollama-process-name "ellama-server")
;;   (defvar +ollama-server-buffer-name " *ellama-server*")

;;   (defun +ollama-serve ()
;;     "Start Ellama server."
;;     (interactive)
;;     (if (executable-find "ollama")
;;         (if (get-process +ollama-process-name)
;;             (message "The Ollama server is already running, call `+ollama-kill-server' to stop it.")
;;           (if (make-process :name +ollama-process-name :buffer +ollama-server-buffer-name :command '("ollama" "serve"))
;;               (message "Successfully started Ollama server.")
;;             (user-error "Cannot start the Ollama server"))
;;           (with-eval-after-load 'ellama (+ellama-set-providers)))
;;       (user-error "Cannot find the \"ollama\" executable")))

;;   (defun +ollama-kill-server ()
;;     "Kill Ellama server."
;;     (interactive)
;;     (let ((ollama (get-process +ollama-process-name)))
;;       (if ollama
;;           (if (kill-process ollama)
;;               (message "Killed Ollama server.")
;;             (user-error "Cannot kill the Ollama server"))
;;         (message "No running Ollama server."))))

;;   (defun +ollama-list-installed-models ()
;;     "Return the installed models"
;;     (let* ((ret (shell-command-to-string "ollama list"))
;;            (models (cdr (string-lines ret))))
;;       (if (and (string-match-p "NAME[[:space:]]*ID[[:space:]]*SIZE[[:space:]]*MODIFIED" ret) (length> models 0))
;;           (mapcar (lambda (m) (car (string-split m))) models)
;;         (user-error "Cannot detect installed models, please make sure Ollama server is started")))))

;; (use-package ellama
;;   :straight t
;;   :config
;;   (defun +ellama-set-providers ()
;;     (setopt ellama-providers
;;             (cl-loop for model in (+ollama-list-installed-models)
;;                      collect (cons model (make-llm-ollama :chat-model model :embedding-model model)))
;;             ellama-provider (cdr (car ellama-providers)))))

;; (use-package elisa
;;   :straight t)




(provide 'me-ai)

;;; me-ai.el ends here
