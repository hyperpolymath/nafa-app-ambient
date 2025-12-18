;; SPDX-License-Identifier: MIT OR AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2024-2025 hyperpolymath
;; nafa-app-ambient - Guix Package Definition
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages base))

(define-public nafa_app_ambient
  (package
    (name "nafa-app-ambient")
    (version "0.1.0")
    (source (local-file "." "nafa-app-ambient-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system gnu-build-system)
    (synopsis "Journey planning app for neurodiverse adventurers")
    (description "NAFA (Neurodiverse App for Adventurers) is a journey planning
app designed to help neurodiverse adventurers navigate public transport and
sensory-rich environments with calm, confidence, and symbolic clarity.")
    (home-page "https://github.com/hyperpolymath/nafa-app-ambient")
    ;; Dual licensed: user chooses MIT or AGPL-3.0+
    (license (list license:expat license:agpl3+))))

;; Return package for guix shell
nafa_app_ambient
