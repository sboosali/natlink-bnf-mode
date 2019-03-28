;;; natlink-bnf-mode.el --- Major mode for Natlink (EBNF) grammars -*- lexical-binding: t; -*-

;;==============================================;;

;; Copyright (C) 2019 Sam Boosalis
;; Copyright (C) 2019 Serghei Iakovlev

;; Author: Sam Boosalis <samboosalis@gmail.com>
;; Maintainer: Sam Boosalis
;; Version: 0.1.0
;; URL: https://github.com/sboosali/natlink-bnf-mode
;; Keywords: languages
;; Package-Requires: ((cl-lib "0.5") (pkg-info "0.4") (emacs "24.3"))

;; This file is not part of GNU Emacs.

;;----------------------------------------------;;

;;; License

;; This file is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;==============================================;;

;;; Commentary:

;;   GNU Emacs major mode for editing BNF grammars.  Currently this mode
;; provides basic syntax and font-locking for "*.bnf" files.
;;
;; Usage:  Put this file in your Emacs Lisp path (eg. site-lisp) and add to
;; your .emacs file:
;;
;;   (require 'natlink-bnf-mode)
;;
;; Bugs: Bug tracking is currently handled using the GitHub issue tracker at
;; https://github.com/sboosali/natlink-bnf-mode/issues
;;
;; History: History is tracked in the Git repository rather than in this file.
;; See https://github.com/sboosali/natlink-bnf-mode/blob/master/CHANGELOG.org

;;==============================================;;

;;; Code:


;;; Compatibility

;; Work around emacs bug#18845, cc-mode expects cl to be loaded
;; while natlink-bnf-mode only uses cl-lib (without compatibility aliases)
(eval-and-compile
  (if (and (= emacs-major-version 24) (>= emacs-minor-version 4))
      (require 'cl)))


;;; Requirements

;; Tell the byte compiler about autoloaded functions from packages
(declare-function pkg-info-version-info "pkg-info" (package))

(eval-when-compile
  (require 'rx))

(require 'cl-lib)
(require 'pkg-info)


;;; Customization

;;;###autoload
(defgroup bnf nil
  "Major mode for editing BNF grammars."
  :tag "BNF"
  :prefix "natlink-bnf-"
  :group 'languages
  :link '(url-link :tag "GitHub Page" "https://github.com/sboosali/natlink-bnf-mode")
  :link '(emacs-commentary-link :tag "Commentary" "natlink-bnf-mode"))

(defcustom natlink-bnf-mode-hook nil
  "List of functions to call when entering BNF Mode."
  :tag "Hook"
  :type 'hook
  :group 'bnf)


;;; Version information

(defun natlink-bnf-mode-version (&optional show-version)
  "Display string describing the version of BNF Mode.

If called interactively or if SHOW-VERSION is non-nil, show the
version in the echo area and the messages buffer.

The returned string includes both, the version from package.el
and the library version, if both are present and different.

If the version number could not be determined, signal an error
if called interactively or if SHOW-VERSION is non-nil, otherwise
just return nil."
  (interactive (list t))
  (let ((version (pkg-info-version-info 'natlink-bnf-mode)))
    (when show-version
      (message "BNF Mode version: %s" version))
    version))

;;==============================================;;


;;; Specialized rx

(eval-when-compile

  ;;--------------------------------------------;;

  (defvar natlink-bnf-symbols

    '( ";"
       "="
       "<"
       ">"
       "+"
       "["
       "]"
       "{"
       "}"
       "|"
      )

    "Symbols in the Natlink BNF.")

  ;;--------------------------------------------;;

  (defvar natlink-bnf-keywords

    '( "imported"
       "exported"
      )

    "Keywords in the Natlink BNF.")

  ;;--------------------------------------------;;

  (defconst natlink-bnf-rx-constituents

    `(
      ;; rulename
      (rulename . ,(rx (and
                        symbol-start
                        letter
                        (0+ (or "-" alnum))
                        symbol-end)))
      )

    "Additional special sexps for `natlink-bnf-rx'.")

  ;;--------------------------------------------;;

  (defmacro natlink-bnf-rx (&rest sexps)

     "NATLINK-BNF-specific replacement for `rx'.

In addition to the standard forms of `rx', the following forms
are available:

`rulename'
      Any valid rule name.  The name of a rule is simply the
      name itself, that is, a sequence of characters, beginning
      with an alphabetic character, and followed by a combination
      of alphabetics, digits, and hyphens (dashes).

      For more see: https://tools.ietf.org/html/rfc5234#section-2.1

See `rx' documentation for more information about REGEXPS param."

     (let ((rx-constituents (append natlink-bnf-rx-constituents rx-constituents)))
       (cond ((null sexps)
              (error "No regexp"))
             ((cdr sexps)
              (rx-to-string `(and ,@sexps) t))
             (t
              (rx-to-string (car sexps) t)))))

  ;;--------------------------------------------;;

  ())

;;==============================================;;


;;; Font Locking

(defvar natlink-bnf-font-lock-keywords
  `(

    ;; Terminals: quoted or unquoted
    (,(natlink-bnf-rx (and 
                   "\""
                   (group terminal)
                   "\""))
     font-lock-string-face)
    
    ;; LHS nonterminals
    (,(natlink-bnf-rx (and line-start
                   "<"
                   (group rulename)
                   ">"))
     1 font-lock-function-name-face)

    ;; other nonterminals
    (,(natlink-bnf-rx (and "<"
                   (group rulename)
                   ">"))
     1 font-lock-builtin-face)
    ;; "may expand into" symbol
    (,(natlink-bnf-rx (and (0+ space)
                   symbol-start
                   (group "=")
                   symbol-end
                   (0+ space)))
     1 font-lock-constant-face)
    ;; Alternatives
    (,(natlink-bnf-rx (and (0+ space)
                   symbol-start
                   (group "|")
                   symbol-end
                   (0+ space)))
     1 font-lock-keyword-face)

    (,(rx "<" (group (or "dgndictation" "dgnletters" "dgnwords")) ">") 1 font-lock-builtin-face)

    )

  "Font lock keywords for BNF Mode.")

  ;; '(
  ;;   ("^#.*"      . 'font-lock-comment-face)       ;; comments at start of line
  ;;   ("^<.*?>"    . 'font-lock-function-name-face) ;; LHS nonterminals
  ;;   ("<.*?>"     . 'font-lock-variable-name-face) ;; other nonterminals
  ;;   ("{.*?}"     . 'font-lock-variable-name-face) ;;
  ;;   ("="         . 'font-lock-constant-face)      ;; "goes-to" symbol
  ;;   (";"         . 'font-lock-constant-face)      ;; statement delimiter
  ;;   ("\|"        . 'font-lock-keyword-face)       ;; "OR" symbol
  ;;   ("\+"        . 'font-lock-keyword-face)       ;; 
  ;;   ("\["        . 'font-lock-keyword-face)       ;; 
  ;;   ("\]"        . 'font-lock-keyword-face)       ;; 
  ;;  )


;;; Initialization

(defvar natlink-bnf-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Give CR the same syntax as newline
    (modify-syntax-entry ?\^m "> b" table)
    ;; Characters used to delimit string constants
    (modify-syntax-entry ?\"  "\""  table)
    ;; Comments setup
    (modify-syntax-entry ?#   "<"   table)
    (modify-syntax-entry ?\n  ">"   table)
    ;; Treat ::= as sequence of symbols
    (modify-syntax-entry ?\:  "_"   table)
    (modify-syntax-entry ?\=  "_"   table)
    ;; Treat | as a symbol
    (modify-syntax-entry ?\|  "_"   table)
    ;; Group angle brackets
    (modify-syntax-entry ?\<  "(>"  table)
    (modify-syntax-entry ?\>  ")<"  table)
    table)
  "Syntax table in use in `natlink-bnf-mode' buffers.")

;;;###autoload
(define-derived-mode natlink-bnf-mode prog-mode "BNF"
  "A major mode for editing BNF grammars."
  :syntax-table natlink-bnf-mode-syntax-table
  :group 'natlink-bnf-mode
  ;; Comment setup
  (setq-local comment-use-syntax t)
  (setq-local comment-auto-fill-only-comments t)
  (setq-local comment-start "# ")
  (setq-local comment-end "")
  (setq-local font-lock-keyword-face 'php-keyword)
  ;; Font locking
  (setq font-lock-defaults '(
                             ;; Keywords
                             natlink-bnf-font-lock-keywords
                             ;; keywords-only
                             nil
                             ;; Regarding RFC-5234
                             ;; The names <rulename>, <Rulename>, <RULENAME>,
                             ;; and <rUlENamE> all refer to the same rule.
                             t
                             )))

;; Invoke natlink-bnf-mode when appropriate

;;;###autoload
(add-to-list 'auto-mode-alist
             '("\\.natlink.bnf\\'" . natlink-bnf-mode
               "\\.natlink\\'"     . natlink-bnf-mode))

(provide 'natlink-bnf-mode)

;; Local Variables:
;; End:

;;; natlink-bnf-mode.el ends here
