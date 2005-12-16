(in-package "ACL2")

(program)
(set-state-ok t)

(include-book "filter-forms") ; for expand-forms

; The following utility, pprint-file, takes an input file of forms and writes
; out a file of corresponding forms in user-level syntax.  In order to do this,
; it applies ACL2's untranslate function to the the result of translating each
; definition and theorem.  An optional argument controls whether or not first
; to evaluate the forms in the input file -- generally necessary for
; translation to work, but not if we are dealing with a file of built-ins.

; This tool handles events defaxiom, defthm, defun, and mutual-recursion.
; Everything else is left unchanged, including encapsulate and local events, as
; our intention is to use this tool on the output of translators that do not
; generate such events.

; Note:
; To run this on forms derived from axioms.lisp:
; (include-book "pprint-file")
; :q
; (setf (cadr (assoc 'global-value (get 'untouchables *current-acl2-world-key*))) nil)
; ; Version 2.9.3 only:
; (acl2-compile-file "patch.lisp" "patch.lisp") ; can skip if done earlier
; (load "patch")
; (lp)
; (pprint-file "ppTestAll.lisp" "some-output-filename" nil)

(defun pprint-file-fn (infile outfile ld-p state)
  (let ((ctx 'pprint-file))
    (er-progn
     (if ld-p
         (ld `((ld ,infile)))
       (value nil))
     (er-let* ((forms (read-list infile ctx state))
               (axioms (expand-forms forms nil t nil state)))
              (write-list (reverse axioms) outfile ctx state)))))

(defmacro pprint-file (infile outfile &optional (ld-p 't))
  (declare (xargs :guard (and (stringp infile)
                              (stringp outfile))))
  `(pprint-file-fn ,infile ,outfile ,ld-p state))
