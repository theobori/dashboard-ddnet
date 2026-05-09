;;; dashboard-ddnet.el --- Display DDNet player informations on Dashboard  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Théo Bori

;; Author: Théo Bori <theobori@disroot.org>
;; Maintainer: Théo Bori <theobori@disroot.org>
;; Keywords: tools
;; URL: https://github.com/theobori/dashboard-ddnet.el
;; Version: 1.0.0
;; Package-Requires: ((emacs "30.1") (dashboard "1.8.0") (request "0.3.3"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary

;; Display DDNet player informations on Dashboard

(require 'seq)
(require 'request)
(require 'dashboard)
(require 'dashboard-widgets)

(add-to-list
 'dashboard-item-generators
 '(ddnet-player-last-finishes . dashboard-ddnet--insert-player-last-finishes))

(add-to-list
 'dashboard-item-generators
 '(ddnet-player-favorite-partners . dashboard-ddnet--insert-player-favorite-partners))

(add-to-list
 'dashboard-item-generators
 '(ddnet-player-last-activity . dashboard-ddnet--insert-player-last-activity))

(defgroup dashboard-ddnet ()
  "Display DDNet player informations on Dashboard"
  :group 'tools
  :link '(url-link :tag "GitHub Repository" "https://github.com/theobori/dashboard-ddnet"))

;;;; User options and variables

(defvar dashboard-ddnet--cache nil "")
(defvar dashboard-ddnet--cache-float-time 0 "")
(defvar dashboard-ddnet--cache-ttl 15 "")

(defcustom dashboard-ddnet-player-name "nameless tee"
  "DDNet player name"
  :type 'string
  :group 'dashboard-ddnet)

(defcustom dashboard-ddnet-url "https://ddnet.org"
  "DDNet base url"
  :type 'string
  :group 'dashboard-ddnet)

;;;; Functions and Emacs user commands

(defun assocdr (key alist &optional testfn)
  ""
  (cdr (assoc key alist testfn)))

(defun dashboard-ddnet--unix-timestamp-format (timestamp &optional zone)
  "Convert unix timestamp integer to human-readable string."
  (format-time-string "%Y-%m-%d %H:%M" timestamp (or zone "UTC")))

(defun dashboard-ddnet--json-player-url-format ()
  ""
  (url-encode-url
   (format "%s/players/?json2=%s"
	   dashboard-ddnet-url dashboard-ddnet-player-name)))

(defun dashboard-ddnet--page-player-url-format (&optional player-name)
  ""
  (url-encode-url
   (format "%s/players/%s"
	   dashboard-ddnet-url (or player-name
				   dashboard-ddnet-player-name))))

(defun dashboard-ddnet--page-map-url-format (map-name)
  ""
  (url-encode-url
   (format "%s/maps/%s"
	   dashboard-ddnet-url map-name)))

(defun dashboard-ddnet--get-json-player-informations ()
  ""
  (if (<= (- (float-time) dashboard-ddnet--cache-float-time) dashboard-ddnet--cache-ttl)
      dashboard-ddnet--cache
    (setq dashboard-ddnet--cache (request-response-data
				  (request (dashboard-ddnet--json-player-url-format)
				    :parser 'json-read
				    :sync t)))
    (setq dashboard-ddnet--cache-float-time (float-time))
    dashboard-ddnet--cache))

(defun dashboard-ddnet--insert-pairs-helper (title pairs)
  ""
  (when pairs
    (dashboard-insert-heading title)
    (dolist (pair pairs)
      (insert "\n    ")
      (widget-create 'push-button
                     :action `(lambda (&rest ignore)
				(browse-url ,(cdr pair)))
                     :mouse-face 'highlight
                     :button-face 'dashboard-items-face
                     :follow-link "\C-m"
                     :button-prefix ""
                     :button-suffix ""
                     :format "%[%t%]"
		     (car pair)))))

(defun dashboard-ddnet--insert-player-vector-helper (title player-information-key vector-parser-function list-size)
  ""
  (let* ((player-informations (dashboard-ddnet--get-json-player-informations))
	 (vector (seq-take
		  (assocdr player-information-key player-informations)
		  list-size))
	 (pairs (funcall vector-parser-function vector)))
    (dashboard-ddnet--insert-pairs-helper title pairs)))

(defun dashboard-ddnet--player-last-finish-format (last-finish)
  ""
  (let ((time (floor (assocdr 'time last-finish)))
	(timestamp (assocdr 'timestamp last-finish)))
    (format "%s: %s %s: %s (%02d:%02d)"
	    (dashboard-ddnet--unix-timestamp-format timestamp)
	    (assocdr 'country last-finish)
	    (assocdr 'type last-finish)
	    (assocdr 'map last-finish)
	    (/ time 60)
	    (% time 60))))

(defun dashboard-ddnet--player-last-finishes-parse (last-finishes)
  "list of cons desired format 08/05/2026 23:36: GER Moderate: Jvice (12:34)"
  (let (ans)
    (dotimes (i (length last-finishes))
      (let* ((last-finish (aref last-finishes i))
	     (map-name (assocdr 'map last-finish)))
	(push (cons
	       (dashboard-ddnet--player-last-finish-format last-finish)
	       (dashboard-ddnet--page-map-url-format map-name))
	      ans)))
    (reverse ans)))

(defun dashboard-ddnet--insert-player-last-finishes (list-size)
  ""
  (when (> list-size 10)
    (error "It cannot fetch more than 10 last finishes"))
  (dashboard-ddnet--insert-player-vector-helper "DDNet last finishes:"
						'last_finishes
						#'dashboard-ddnet--player-last-finishes-parse
						list-size))

(defun dashboard-ddnet--player-favorite-partner-format (favorite-partner)
  ""
  (format "%s: %d ranks"
	  (assocdr 'name favorite-partner)
	  (assocdr 'finishes favorite-partner)))

(defun dashboard-ddnet--player-favorite-partners-parse (favorite-partners)
  ""
  (let (ans)
    (dotimes (i (length favorite-partners))
      (let ((favorite-partner (aref favorite-partners i)))
	(push (cons (format "%d. %s"
			    (+ i 1)
			    (dashboard-ddnet--player-favorite-partner-format favorite-partner))
		    (dashboard-ddnet--page-player-url-format (assocdr 'name favorite-partner)))
	      ans)))
    (reverse ans)))

(defun dashboard-ddnet--insert-player-favorite-partners (list-size)
  ""
  (when (> list-size 10)
    (error "It cannot fetch more than 10 favorite partners"))
  (dashboard-ddnet--insert-player-vector-helper "DDNet favorite partners:"
						'favorite_partners
						#'dashboard-ddnet--player-favorite-partners-parse
						list-size))

(defun dashboard-ddnet--player-last-activity-parse (activity)
  ""
  (let ((ans)
	(activity-desc (reverse activity)))
    (dotimes (i (length activity-desc))
      (let ((day (aref activity i)))
	(push (cons (format "%d hours played on %s"
			    (assocdr 'hours_played day)
			    (assocdr 'date day))
		    (dashboard-ddnet--page-player-url-format))
	      ans)))
    (reverse ans)))

(defun dashboard-ddnet--insert-player-last-activity (list-size)
  ""
  (dashboard-ddnet--insert-player-vector-helper "DDNet last activity:"
						'activity
						#'dashboard-ddnet--player-last-activity-parse
						list-size))

;;; Code
(provide 'dashboard-ddnet)

;;; dashboard-ddnet.el ends here
