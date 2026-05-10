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

(add-to-list
 'dashboard-item-generators
 '(ddnet-player-general-informations . dashboard-ddnet--insert-player-general-informations))

(defgroup dashboard-ddnet ()
  "Display DDNet player informations on Dashboard"
  :group 'tools
  :link '(url-link :tag "GitHub Repository" "https://github.com/theobori/dashboard-ddnet"))

;;;; User options and variables

(defvar dashboard-ddnet--cache-data nil "HTTP request reponse data cached.")
(defvar dashboard-ddnet--cache-float-time 0 "The current time as a float of seconds since the epoch.")
(defvar dashboard-ddnet--cache-ttl 300 "Time to live for the cached data.")

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
  "Wrapping the `assoc' function then returning its CDR."
  (cdr (assoc key alist testfn)))

(defun dashboard-ddnet--unix-timestamp-format (timestamp &optional zone)
  "Convert unix timestamp integer to human-readable string."
  (format-time-string "%Y-%m-%d %H:%M" timestamp (or zone "UTC")))

(defun dashboard-ddnet--json-player-url-format ()
  "Returns the DDNet URL to get player informations as JSON."
  (url-encode-url
   (format "%s/players/?json2=%s"
	   dashboard-ddnet-url dashboard-ddnet-player-name)))

(defun dashboard-ddnet--page-player-url-format (&optional player-name)
  "Returns the DDNet URL to get a player page."
  (url-encode-url
   (format "%s/players/%s"
	   dashboard-ddnet-url (or player-name
				   dashboard-ddnet-player-name))))

(defun dashboard-ddnet--page-map-url-format (map-name)
  "Returns the DDNet URL to get a map page."
  (url-encode-url
   (format "%s/maps/%s"
	   dashboard-ddnet-url map-name)))

(defun dashboard-ddnet--get-json-player-informations ()
  "Returns the player informations as a Emacs value mirroring JSON. If the
cached data has no more time to live, it makes HTTP request and updates
the cache values."
  (if (<= (- (float-time) dashboard-ddnet--cache-float-time) dashboard-ddnet--cache-ttl)
      dashboard-ddnet--cache-data
    (setq dashboard-ddnet--cache-data (request-response-data
				       (request (dashboard-ddnet--json-player-url-format)
					 :parser 'json-read
					 :sync t)))
    (setq dashboard-ddnet--cache-float-time (float-time))
    dashboard-ddnet--cache-data))

(defun dashboard-ddnet--insert-alist-helper (title alist)
  "Helper function that first insert a TITLE, then ALIST where each cons
should have the inserted value as car and an associated url as cdr."
  (when alist
    (dashboard-insert-heading title)
    (dolist (el alist)
      (insert "\n    ")
      (widget-create 'push-button
                     :action `(lambda (&rest _)
				(browse-url ,(cdr el)))
                     :mouse-face 'highlight
                     :button-face 'dashboard-items-face
                     :follow-link "\C-m"
                     :button-prefix ""
                     :button-suffix ""
                     :format "%[%t%]"
		     (car el)))))

(defun dashboard-ddnet--insert-player-section-helper (title key parser-fn list-size)
  "Helper function for inserting a DDNet player dashboard section. It gets
player information with a specific KEY, then it is parsed using the
PARSER-FN that mush return a alist."
  (let* ((player-informations (dashboard-ddnet--get-json-player-informations))
	 (player-information (assocdr key player-informations))
	 (alist (funcall parser-fn player-information)))
    (dashboard-ddnet--insert-alist-helper title
					  (seq-take alist list-size))))

(defun dashboard-ddnet--player-last-finish-format (last-finish)
  "Returns a formatted string representing a LAST-FINISH alist."
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
  "Parses the LAST-FINISHES vector and returns a alist."
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
  "Insert the DDNet player LIST-SIZE last finishes."
  (when (> list-size 10)
    (error "It cannot fetch more than 10 last finishes."))
  (dashboard-ddnet--insert-player-section-helper "DDNet last finishes:"
						 'last_finishes
						 #'dashboard-ddnet--player-last-finishes-parse
						 list-size))

(defun dashboard-ddnet--player-favorite-partner-format (favorite-partner)
  "Returns a formatted string representing a FAVORITE-PARTNER alist."
  (format "%s: %d ranks"
	  (assocdr 'name favorite-partner)
	  (assocdr 'finishes favorite-partner)))

(defun dashboard-ddnet--player-favorite-partners-parse (favorite-partners)
  "Parses the FAVORITE-PARTNERS vector and returns a alist."
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
  "Insert the DDNet player LIST-SIZE favorite partners."
  (when (> list-size 10)
    (error "It cannot fetch more than 10 favorite partners."))
  (dashboard-ddnet--insert-player-section-helper "DDNet favorite partners:"
						 'favorite_partners
						 #'dashboard-ddnet--player-favorite-partners-parse
						 list-size))

(defun dashboard-ddnet--player-last-activity-parse (activity)
  "Parses the LAST-ACTIVITY vector and returns a alist."
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
  "Insert the DDNet player LIST-SIZE last activity."
  (let* ((player-informations (dashboard-ddnet--get-json-player-informations))
	 (last-activity-vector (seq-take
				(reverse (assocdr 'activity player-informations))
				list-size))
	 (last-activity-alist
	  (dashboard-ddnet--player-last-activity-parse last-activity-vector)))
    (dashboard-ddnet--insert-alist-helper "DDNet last activity:"
					  last-activity-alist)))

(defun dashboard-ddnet--insert-player-general-informations (&optional list-size)
  "Insert the DDNet player general informations. LIST-SIZE will not be used
for this section."
  (let ((player-informations (dashboard-ddnet--get-json-player-informations))
	(action-function `(lambda (&rest _)
			    (browse-url ,(dashboard-ddnet--json-player-url-format)))))
    (dashboard-insert-heading "DDNet player general informations:")
    (insert "\n    ")
    (widget-create 'push-button
                   :action action-function
		   :mouse-face 'highlight
		   :button-face 'dashboard-items-face
		   :follow-link "\C-m"
		   :button-prefix ""
		   :button-suffix ""
		   :format "Player: %[%t%]"
		   (assocdr 'player player-informations))
    (insert "\n    ")
    (let ((points (assocdr 'points player-informations)))
      (insert (format "Rank: %d" (assocdr 'rank points)))
      (insert "\n    ")
      (insert (format "Points: %d" (assocdr 'points points))))
    (insert "\n    ")
    (insert (format "Favorite server: %s"
		    (assocdr 'server
			     (assocdr 'favorite_server player-informations))))))

;;; Code
(provide 'dashboard-ddnet)

;;; dashboard-ddnet.el ends here
