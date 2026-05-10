# Emacs Dashboard DDNet integration

[![build-then-test](https://github.com/theobori/dashboard-ddnet/actions/workflows/build-then-test.yml/badge.svg)](https://github.com/theobori/dashboard-ddnet/actions/workflows/build-then-test.yml)

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

dashboard-ddnet is a KISS Emacs package which contains functions that have been added to `dashboard-item-generators`. These functions are used by dashboard to insert Dashboard section containing DDNet player statistics when specified.

## Getting started

To use the project you need [Emacs](https://www.gnu.org/software/emacs/) with a version higher or equal than `30.1`, [dashboard](https://github.com/emacs-dashboard/dashboard), [request](https://github.com/tkf/emacs-request), [curl](https://github.com/curl/curl) for the request package and [GNU Make](https://www.gnu.org/software/make/) if you want to build and install it manually.

## Installation

Below are instructions for installing the package manually or using [straight.el](https://github.com/radian-software/straight.el).

### Manual

To install it manually, download the code from this [GitHub repository](https://github.com/theobori/dashboard-ddnet) and then load it. To do this, you can use the following command lines.

```bash
make install
```

Then you can evaluate the following ELisp expression.

```emacs-lisp
(add-to-list 'load-path (file-name-concat user-emacs-directory "manual-packages" "dashboard-ddnet"))
```

### Straight

If you're using [straight.el](https://github.com/radian-software/straight.el) you can use the code snippet below.

```emacs-lisp
(use-package dashboard-ddnet
:straight (dashboard-ddnet :type git :host github :repo "theobori/dashboard-ddnet")
:custom
  (dashboard-ddnet-player-name "brainless tee"))
```

## Usage

For using it, you can insert cons in `dashboard-items` like below.

```emacs-lisp
(setq dashboard-items '((ddnet-player-general-informations . 5)
	                    (ddnet-player-last-finishes . 5)
						(ddnet-player-favorite-partners . 5)
			            (ddnet-player-last-activity . 5)))
```

By default, cache TTL is set to 5 minutes, feel free to update the `dashboard-ddnet--cache-ttl` variable to the value you want.

## Overview

Here's a little preview of what it might look like.

![Screenshot](/assets/dashboard-ddnet-screenshot.png)

## Contribute

If you want to help the project, you can follow the guidelines in [CONTRIBUTING.md](./CONTRIBUTING.md).
