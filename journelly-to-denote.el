(defun tw/journelly-to-denote-journal ()
  (interactive)
  (let* ((journelly-file "/Users/t.welch2/Library/Mobile Documents/iCloud~com~xenodium~Journelly/Documents/Journelly.org")
         (denote-dir "~/Org/Journal/")
         (image-dir "~/Org/Journal/images/")
         (heading-regexp "^\\* \\[\\([0-9-]+\\) \\([A-Za-z]+\\) \\([0-9:]+\\)\\] @ \\(.*\\)"))

    (unless (file-directory-p denote-dir)
      (make-directory denote-dir t))
    (unless (file-directory-p image-dir)
      (make-directory image-dir t))

    (find-file journelly-file)
    ;; Loop over the top-level headings
    (goto-char (point-min))
    (while (re-search-forward heading-regexp nil t)
      (let* ((date (match-string 1))
             (time (match-string 3))
             (location (match-string 4))
             (heading-start (line-beginning-position))
             (heading-end (progn (outline-next-heading) (point)))
             (content (buffer-substring-no-properties heading-start heading-end))
             (day-of-week (format-time-string "%A" (date-to-time date)))
             (human-readable-date (format-time-string "%-d-%B-%Y" (date-to-time date)))
             (date-without-dashes (replace-regexp-in-string "-" "" date))
             (timestamp (format-time-string "%Y%m%dT%H%M%S" (date-to-time (concat date " " time))))
             (location-slug (concat "@" (downcase (replace-regexp-in-string " " "-" location))))
             (new-file-name (concat denote-dir
                                    timestamp "--"
                                    (downcase day-of-week) "-"
                                    human-readable-date "-"
                                    location-slug
                                    "__journal.org"))
             (image-links '()))

        ;; Extract image links
        (save-excursion
          (goto-char heading-start)
          (while (re-search-forward "\\[\\[file:\\(Journelly\\.org\\.assets/[^\]]+\\)\\]\\]" heading-end t)
            (push (match-string 1) image-links)))

        ;; Add Denote metadata and content
        (with-temp-file new-file-name
          (insert (format "#+title: %s\n" human-readable-date))
          (insert (format "#+date: [%s %s]\n" date time))
          (insert "#+filetags: :journal:\n")
          (insert (format "#+identifier: %s\n\n" timestamp))
          (insert content)
          
          ;; Copy image files and update links in the content
          (dolist (image-link image-links)
            (let* ((image-file (expand-file-name image-link "/Users/t.welch2/Library/Mobile Documents/iCloud~com~xenodium~Journelly/Documents/"))
                   (new-image-path (concat image-dir (file-name-nondirectory image-file))))
              (when (file-exists-p image-file)
                (copy-file image-file new-image-path t)
                (goto-char (point-min))
                (while (re-search-forward (regexp-quote image-link) nil t)
                  (replace-match (concat "file:" new-image-path)))))))))

    (message "Journelly entries extracted to Denote journal")))
