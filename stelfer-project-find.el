
;;; Stolen from projectile
(defvar stelfer/project-other-file-alist
  '(
    ("cpp" . ("h" "hpp" "ipp"))
    ("ipp" . ("h" "hpp" "cpp"))
    ("hpp" . ("h" "ipp" "cpp" "cc"))
    ("cxx" . ("h" "hxx" "ixx"))
    ("ixx" . ("h" "hxx" "cxx"))
    ("hxx" . ("h" "ixx" "cxx"))
    ("c"   . ("h"))
    ("m"   . ("h"))
    ("mm"  . ("h"))
    ("h"   . ("c" "cc" "cpp" "ipp" "hpp" "cxx" "ixx" "hxx" "m" "mm"))
    ("cc"  . ("h" "hh" "hpp"))
    ("hh"  . ("cc"))

    ;; vertex shader and fragment shader extensions in glsl
    ("vert" . ("frag"))
    ("frag" . ("vert"))

    ;; handle files with no extension
    (nil    . ("lock" "gpg"))
    ("lock" . (""))
    ("gpg"  . (""))
    ))

(defvar stelfer/project-find-exclude-dirs '(".ccls-cache" ".clangd" ".git" "build"))
(defvar stelfer/project-find-exclude-suffixes '("~" ".o"))

(defun stelfer/project-assemble-exclude-filter ()
  (concat
   (mapconcat (lambda (x) x )
	      (mapcar (lambda (x)
			(concat "-not -name \\*" x))
		      stelfer/project-find-exclude-suffixes)
	      " ")
   " "
   (mapconcat (lambda (x) x )
	      (mapcar (lambda (x)
			(concat "-not \\( -path $(pwd)/" x " -prune  \\)"))
		      stelfer/project-find-exclude-dirs)
	      " ")
   ))


(defun stelfer/project-assemble-find-filter (file filters)
  (mapconcat (lambda (x)
	       (concat "-name " (file-name-sans-extension file) "." x ))
	     filters
	     " -or "))

(defun stelfer/project-assemble-other-find-filter (file)
  (let* ((ext (file-name-extension file))
	 (filters (cdr (assoc ext stelfer/project-other-file-alist))))
    (stelfer/project-assemble-find-filter file filters)))

(defun stelfer/switch-or-find (file)
  (let* ((plist (mapcar (lambda (x)
			 (cons (buffer-file-name x) (buffer-name x)))
		       (buffer-list)))
	(buffer (assoc file plist)))
    (if buffer
	(switch-to-buffer (cdr buffer))
      (find-file file))))

(defun stelfer/visit-file (file)
  (if file
      (let* ((file-remote (file-remote-p default-directory))
	     (file (if file-remote (concat file-remote file) file)))
	(stelfer/switch-or-find file))))

(defun stelfer/project--find-file (&optional filter)
  (let* ((p (project-current))
	 (filter (or filter ""))
	 (default-directory (cdr p))
	 (excl (stelfer/project-assemble-exclude-filter))
	 (cmd (concat "find $(pwd) " excl " -type f " filter))
	 (helm-candidate-number-limit 1000)
	 )
    (save-current-buffer
      (if p
	  (stelfer/visit-file
	   (helm :sources (helm-build-async-source "test2"
			    :candidates-process
			    (lambda ()
			      (start-process "echo" nil "/bin/sh" "-c" cmd)))
		 :buffer "*helm async source*"))))))

(defun stelfer/project-find-similar-file (&optional file)
  (interactive)
  (let* ((file (or file (buffer-name)))
	 (r (file-name-nondirectory (file-name-sans-extension file)))
	 (find-r (concat "-name " r "\*")))
    (stelfer/project--find-file find-r)))

(defun stelfer/project-find-other-file (&optional file)
  (interactive)
  (let* ((file (or file (file-name-nondirectory (buffer-file-name))))
	 (r (file-name-nondirectory (file-name-sans-extension file)))
	 (filter (stelfer/project-assemble-other-find-filter file)))
    (message "OTHER: %S %S" filter file)
    (stelfer/project--find-file filter)))

(defun stelfer/project-find-file ()
  (interactive)
  (if (project-current)
      (stelfer/project--find-file)      
    (call-interactively 'helm-find-files)))

;; (with-current-buffer "ttv.h"
;;   ;; (stelfer/project--find-file)
;;   (stelfer/project-find-other-file)
;;   )
  

(provide 'stelfer-project-find)


