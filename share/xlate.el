;;; xlate.el

(defvar xlate-default-target-lang "EN-US"
  "Default target language for translation.")

(defun xlate-buffer (&optional prefix)
  "Execute deepl command on current buffer."
  (interactive "P")
  (if prefix
      (xlate-region (region-beginning) (region-end))
    (xlate-region (point-min) (point-max))))

(defun xlate-region (begin end &optional target-lang)
  "Execute xlate on region with an optional target language.
If called with a prefix argument (C-u), prompt for the target language."
  (interactive (let* ((region (list (region-beginning) (region-end)))
                      (lang (when current-prefix-arg
                              (read-string (format "Target language (default: %s): "
						   xlate-default-target-lang)))))
                 (append region (list lang))))
  (let ((opoint (point))
        (lang (or target-lang xlate-default-target-lang)))
    (set-mark end)
    (goto-char begin)
    (shell-command-on-region
     begin end
     (format "xlate -a -s -o cm -w72 -p '(?s).+' -t %s -" lang)
     t t nil t)
    (goto-char (region-beginning))
    (setq xlate-default-target-lang lang))) ; Update the default target language
