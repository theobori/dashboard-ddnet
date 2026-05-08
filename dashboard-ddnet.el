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

(require 'request)
(require 'dashboard)
(require 'dashboard-widgets)

(add-to-list
 'dashboard-item-generators
 '(ddnet-last-finishes . dashboard-ddnet--insert-player-last-finishes))

;;;; User options

(defgroup dashboard-ddnet ()
  "Display DDNet player informations on Dashboard"
  :group 'tools
  :link '(url-link :tag "GitHub Repository" "https://github.com/theobori/dashboard-ddnet"))

;;;; User options

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

(defun dashboard-ddnet--page-player-url-format ()
  ""
  (url-encode-url
   (format "%s/players/%s"
	   dashboard-ddnet-url dashboard-ddnet-player-name)))

(defun dashboard-ddnet--page-map-url-format (map-name)
  ""
  (url-encode-url
   (format "%s/maps/%s"
	   dashboard-ddnet-url map-name)))

(defun dashboard-ddnet--get-json-player-informations ()
  ""
  (request-response-data
   (request (dashboard-ddnet--json-player-url-format)
     :parser 'json-read
     :sync t)))

(defun dashboard-ddnet--player-last-finish-format (last-finish)
  ""
  (let ((time (floor (assocdr 'time last-finish))))
    (format "%s: %s %s: %s (%02d:%02d)"
	    (dashboard-ddnet--unix-timestamp-format (assocdr 'timestamp last-finish))
	    (assocdr 'country last-finish)
	    (assocdr 'type last-finish)
	    (assocdr 'map last-finish)
	    (/ time 60)
	    (% time 60))))

(defun dashboard-ddnet--player-last-finishes-parse (last-finishes)
  "list of cons desired format 08/05/2026 23:36: GER Moderate: Jvice (12:34)"
  (let (ans)
    (dotimes (i (length last-finishes))
      (let ((last-finish (aref last-finishes i)))
	(push (cons
	       (dashboard-ddnet--player-last-finish-format last-finish)
	       (dashboard-ddnet--page-map-url-format (assocdr 'map last-finish))) ans)))
    (reverse ans)))

(defun dashboard-ddnet--insert-pairs (title pairs)
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

(defun dashboard-ddnet--insert-player-last-finishes (list-size)
  ""
  (let* ((player-informations (dashboard-ddnet--get-json-player-informations))
	 (last-finishes (assocdr 'last_finishes player-informations))
	 (pairs (seq-take (dashboard-ddnet--player-last-finishes-parse last-finishes) list-size)))
    (dashboard-ddnet--insert-pairs "DDNet last finishes:" pairs)))

(defun dashboard-ddnet--insert-player-favorite_partners ()
  ""
  )

;;; Code
(provide 'dashboard-ddnet)

;;; dashboard-ddnet.el ends here
