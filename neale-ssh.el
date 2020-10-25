;;
;; ssh
;;
(defvar ssh/default-host "fsf.org"
  "Default if you just hit enter for hostname")

(defvar ssh/frequent-hosts '("host1.fsf.org")
  "List of hosts to add to completion options")

(defun ssh/known-hosts ()
  "Return a list of hosts for completion"
  (with-temp-buffer
    (insert-file-contents-literally "~/.ssh/known_hosts")
    (let ((ssh-hosts-list) '())
      (while (not (eobp))
	(add-to-list 'ssh-hosts-list (buffer-substring (point) (- (search-forward-regexp "[, ]") 1)))
	(forward-line))
      ssh-hosts-list)))

(setq ssh/host-history '())
(defun ssh (remote)
  (interactive
   (list
    (completing-read (format "Remote host (default %s): " ssh/default-host)
		     (append ssh/frequent-hosts (ssh/known-hosts))
		     nil nil (format "%s@" init-file-user) 'ssh/host-history)))
  (if (string= remote "")
      (setq remote ssh/default-host))
  (let ((name (generate-new-buffer-name (format "*%s*" remote)))
	(default-directory "/tmp")
	(explicit-shell-file-name "ssh")
	(explicit-ssh-args (list remote)))
    (shell name)
    ;; Doing it this way is goofy, but whatevs.
    (with-current-buffer name
      ;; HP iLO needs a carriage return instead of newline.
      (if (string-match "\.ilo$" remote)
	  (setq-local comint-input-sender 'ssh/comint-cr-send))
      (setq-local dabbrev-abbrev-char-regexp "\\sw\\|\\s_\\|[-._,]"))))
(global-set-key (kbd "C-c s") 'ssh)

;;
;; Kill old buffers; not sure this is a fantastic idea
;;
(defun ssh/shell-kill-buffer-sentinel (process event)
  (when (memq (process-status process) '(exit signal))
    (kill-buffer (process-buffer process))))

(defun ssh/kill-process-buffer-on-exit ()
  (set-process-sentinel (get-buffer-process (current-buffer))
                        #'ssh/shell-kill-buffer-sentinel))
(add-hook 'comint-exec-hook 'ssh/kill-process-buffer-on-exit)

(defun ssh/comint-cr-send (proc string)
  "Send a comint string terminated with carriage return

Some machines (HP iLO) need this, because reasons."
  (let ((send-string
         (if comint-input-sender-no-newline
             string
           (concat string "\r"))))
    (comint-send-string proc send-string))
  (if (and comint-input-sender-no-newline
	   (not (string-equal string "")))
      (process-send-eof)))

(defun mmb-proceed ()
  (interactive)
  (with-current-buffer "*mmb*"
    (start-file-process "mmb" (current-buffer) "~/work/bin/mmb" "-a" ircname)))

(defun mmb (who)
  (interactive "MMerge who? ")
  (with-current-buffer (get-buffer-create "*mmb*")
    (setq-local ircname who)
    (display-buffer (current-buffer))
    (erase-buffer)
    (start-file-process "mmb" (current-buffer) "~/work/bin/mmb" ircname)
    (local-set-key (kbd "C-c C-c") 'mmb-proceed)))


(provide 'neale-ssh)
