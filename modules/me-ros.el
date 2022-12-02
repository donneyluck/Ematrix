;; -*- lexical-binding: t; -*-

(with-eval-after-load 'minemacs-loaded
  (add-to-list 'auto-mode-alist '("\\.rviz\\'"   . conf-unix-mode))
  (add-to-list 'auto-mode-alist '("\\.urdf\\'"   . xml-mode))
  (add-to-list 'auto-mode-alist '("\\.xacro\\'"  . xml-mode))
  (add-to-list 'auto-mode-alist '("\\.launch\\'" . xml-mode))

  ;; Use gdb-script-mode for msg and srv files
  (add-to-list 'auto-mode-alist '("\\.msg\\'"    . gdb-script-mode))
  (add-to-list 'auto-mode-alist '("\\.srv\\'"    . gdb-script-mode))
  (add-to-list 'auto-mode-alist '("\\.action\\'" . gdb-script-mode))

  ;; A mode to display infos for ROS bag files
  (define-derived-mode rosbag-view-mode
    fundamental-mode "ROS bag view mode"
    "Major mode for viewing ROS/ROS2 bag files."
    (let ((f (buffer-file-name)))
      (let ((buffer-read-only nil))
        (erase-buffer)
        (message "Calling rosbag info")
        (pcase f
          ((rx (seq ".bag" eol))
           (call-process "rosbag" nil (current-buffer) nil "info" f))
          ((rx (seq "." (or "db3" "mcap") eol))
           (call-process "ros2" nil (current-buffer) nil "bag" "info" f)))
        (set-buffer-modified-p nil))
      (view-mode
       (set-visited-file-name nil t))))

  (when (executable-find "rosbag")
    (add-to-list 'auto-mode-alist '("\\.bag$" . rosbag-view-mode)))

  (when (executable-find "ros2")
    (add-to-list 'auto-mode-alist '("\\.db3$" . rosbag-view-mode)))

  (when (executable-find "mcap")
    (add-to-list 'auto-mode-alist '("\\.mcap$" . rosbag-view-mode))))

;; Needed by ros.el
(use-package kv
  :straight t
  :defer t)

(use-package string-inflection
  :straight t
  :defer t)

(use-package with-shell-interpreter
  :straight t
  :defer t)

(when (< emacs-major-version 29)
  (use-package docker-tramp
    :straight t
    :defer t))

;; ROS package
(use-package ros
  :straight (:host github :repo "DerBeutlin/ros.el")
  :general
  (+map
    "or"  '(nil :wk "ROS")
    "orr" '(+hydra-ros-main/body :wk "Hydra")
    "ors" '(ros-set-workspace :wk "Set workspace")
    "orp" '(ros-go-to-package :wk "Go to package")
    "orC" '(ros-cache-clean :wk "Clean cache"))

  :config
  (defhydra +hydra-ros-main (:color blue :hint nil :foreign-keys warn)
    "
[ROS]                                                  [_q_] quit
  ├──────────────────────────────────────────────────────────────────────╮
  │  [_c_] Compile    [_t_] Test       [_w_] Set workspace   [_p_] Packages      │
  │  [_m_] Messages   [_s_] Services   [_a_] Actions         [_x_] Clean cache   │
  ╰──────────────────────────────────────────────────────────────────────╯
"
    ("c" ros-colcon-build-transient)
    ("t" ros-colcon-test-transient)
    ("w" ros-set-workspace)
    ("p" hydra-ros-packages/body)
    ("m" hydra-ros-messages/body)
    ("s" hydra-ros-srvs/body)
    ("a" hydra-ros-actions/body)
    ("x" ros-cache-clean)
    ("q" nil :color blue)))


(provide 'me-ros)
