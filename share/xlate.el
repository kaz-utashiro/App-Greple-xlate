;;; xlate.el

(defun xlate-buffer (&optional prefix)
  "Execute deepl command on current buffer."
  (interactive "P")
  (if prefix
      (xlate-region (region-beginning) (region-end))
    (xlate-region (point-min) (point-max))))

(defun xlate-region (begin end)
  "Execute greple -Mxlate on region."
  (interactive "r")
  (let ((opoint (point)))
    (set-mark end)
    (goto-char begin)
    (shell-command-on-region
     begin end
     "xlate -a -s -o cm -w72 -p '(?s).+' -t EN-US"
     t t nil t)
    (goto-char (region-beginning))))
