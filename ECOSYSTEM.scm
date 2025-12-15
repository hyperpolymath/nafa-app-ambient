;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — nafa-app-ambient

(ecosystem
  (version "1.0.0")
  (name "nafa-app-ambient")
  (type "project")
  (purpose "NAFA is a journey planning app designed to help neurodiverse adventurers navigate public transport and sensory-rich environments with calm, confidence, and symbolic clarity.")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "NAFA is a journey planning app designed to help neurodiverse adventurers navigate public transport and sensory-rich environments with calm, confidence, and symbolic clarity.")
  (what-this-is-not "- NOT exempt from RSR compliance"))
