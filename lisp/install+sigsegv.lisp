(roswell:include "util-install-quicklisp")
(defpackage :roswell.install.sigsegv+
  (:use :cl :roswell.install :roswell.util :roswell.locations)
  (:export :*sigsegv-version*))
(in-package :roswell.install.sigsegv+)

(defvar *sigsegv-version* "2.11")

(defun sigsegv-setup (argv)
  (let* ((uri (format nil "~Alibsigsegv-~A.tar.gz" (sigsegv-uri) *sigsegv-version*))
         (pos (position #\/ uri :from-end t))
         (path (merge-pathnames (format nil "archives/~A" (subseq uri (1+ pos))) (homedir)))
         (expand-dir (merge-pathnames (format nil "src/libsigsegv-~A/" *sigsegv-version*) (homedir)))
         (prefix (merge-pathnames (format nil "lib/~A/~A/~A/~A/" (uname-m) (uname) "sigsegv" *sigsegv-version*) (homedir)))
         (logdir (ensure-directories-exist (merge-pathnames "impls/log/sigsegv/" (homedir)))))
    (if (or (not (probe-file path))
            (opt "download.force"))
        (progn
          (format *error-output* "~&Downloading archive: ~A~%" uri)
          (force-output *error-output*)
          (download uri path)
          (format *error-output* " done.~%"))
        (format *error-output* "~&Skip downloading ~A.~%Specify 'download.force=t' to download it again.~%" uri))
    (expand path (ensure-directories-exist (merge-pathnames "src/" (homedir))))
    (chdir expand-dir)
    (format t "~&configure~%")
    (with-open-file (out (merge-pathnames "config.log" logdir)
                         :direction :output :if-exists :append :if-does-not-exist :create)
      (format out "~&--~&~A~%" (date))
      (let* ((cmd (format nil "~A ./configure '--prefix=~A'" (sh) (ensure-directories-exist prefix)))
             (*standard-output* (make-broadcast-stream out #+sbcl(make-instance 'count-line-stream))))
        (uiop/run-program:run-program cmd :output t :error-output t :ignore-error-status t)))
    (format t "~&make~%")
    (with-open-file (out (merge-pathnames "make.log" logdir)
                         :direction :output :if-exists :append :if-does-not-exist :create)
      (format out "~&--~&~A~%" (date))
      (let* ((cmd (format nil "make"))
             (*standard-output* (make-broadcast-stream out #+sbcl(make-instance 'count-line-stream))))
        (uiop/run-program:run-program cmd :output t :error-output t :ignore-error-status t)))
    (format t "~&install~%")
    (with-open-file (out (merge-pathnames "install.log" logdir)
                         :direction :output :if-exists :append :if-does-not-exist :create)
      (format out "~&--~&~A~%" (date))
      (let ((*standard-output* (make-broadcast-stream
                                out #+sbcl(make-instance 'count-line-stream))))
        (uiop/run-program:run-program "make install" :output t :error-output t))
      (format *error-output* "done.~%")))
  (setf (config "sigsegv.version") *sigsegv-version*)
  (cons t argv))

(defun sigsegv-help (argv)
  (format t "~%")
  (cons t argv))

(defun sigsegv+ (type)
  (case type
    (:help '(sigsegv-help))
    (:install '(sigsegv-setup))))
