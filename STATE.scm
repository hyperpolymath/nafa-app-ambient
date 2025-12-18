;;; STATE.scm - Project Checkpoint
;;; nafa-app-ambient
;;; Format: Guile Scheme S-expressions
;;; Purpose: Preserve AI conversation context across sessions
;;; Reference: https://github.com/hyperpolymath/state.scm

;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

;;;============================================================================
;;; METADATA
;;;============================================================================

(define metadata
  '((version . "0.1.0")
    (schema-version . "1.0")
    (created . "2025-12-15")
    (updated . "2025-12-17")
    (project . "nafa-app-ambient")
    (repo . "github.com/hyperpolymath/nafa-app-ambient")))

;;;============================================================================
;;; PROJECT CONTEXT
;;;============================================================================

(define project-context
  '((name . "nafa-app-ambient")
    (tagline . "NAFA is a journey planning app designed to help neurodiverse adventurers navigate public transport and sensory-rich environments with calm, confidence, and symbolic clarity.")
    (version . "0.1.0")
    (license . "AGPL-3.0-or-later")
    (rsr-compliance . "gold-target")

    (tech-stack
     ((primary . "See repository languages")
      (ci-cd . "GitHub Actions + GitLab CI + Bitbucket Pipelines")
      (security . "CodeQL + OSSF Scorecard")))))

;;;============================================================================
;;; CURRENT POSITION
;;;============================================================================

(define current-position
  '((phase . "v0.1 - Initial Setup and RSR Compliance")
    (overall-completion . 35)

    (components
     ((rsr-compliance
       ((status . "complete")
        (completion . 100)
        (notes . "SHA-pinned actions, SPDX headers, multi-platform CI, flake.nix added")))

      (package-management
       ((status . "complete")
        (completion . 100)
        (notes . "guix.scm (primary) + flake.nix (Nix fallback) both functional")))

      (documentation
       ((status . "foundation")
        (completion . 40)
        (notes . "README, META/ECOSYSTEM/STATE.scm, improved descriptions")))

      (testing
       ((status . "minimal")
        (completion . 10)
        (notes . "CI/CD scaffolding exists, limited test coverage")))

      (frontend
       ((status . "foundation")
        (completion . 30)
        (notes . "Elm types, ports, and main structure defined")))

      (backend
       ((status . "not-started")
        (completion . 0)
        (notes . "Elixir backend directory exists but empty")))

      (core-functionality
       ((status . "in-progress")
        (completion . 20)
        (notes . "UI structure defined, backend implementation pending")))))

    (working-features
     ("RSR-compliant CI/CD pipeline"
      "Multi-platform mirroring (GitHub, GitLab, Bitbucket)"
      "SPDX license headers on all files"
      "SHA-pinned GitHub Actions"
      "Dual package management (Guix primary, Nix fallback)"
      "Elm frontend type system and ports"))))

;;;============================================================================
;;; ROUTE TO MVP
;;;============================================================================

(define route-to-mvp
  '((target-version . "1.0.0")
    (definition . "Stable release with comprehensive documentation and tests")

    (milestones
     ((v0.1.1
       ((name . "Security & Infrastructure Hardening")
        (status . "in-progress")
        (items
         ("SHA-pin all GitHub Actions" . "complete")
         ("Add flake.nix for Nix fallback" . "complete")
         ("Fix Elm source file formatting" . "complete")
         ("Verify guix.scm functionality" . "complete")
         ("Ensure dual license compliance" . "complete"))))

      (v0.2
       ((name . "Core Backend")
        (status . "pending")
        (items
         ("Initialize Elixir/Phoenix backend"
          "Implement GraphHopper routing integration"
          "Create sensory profile API"
          "Add user authentication"
          "Set up database schema"))))

      (v0.3
       ((name . "Frontend Integration")
        (status . "pending")
        (items
         ("Connect Elm frontend to Elixir backend"
          "Implement route planning UI"
          "Add sensory warning displays"
          "Create badge/gamification system"
          "Add mood logging interface"))))

      (v0.5
       ((name . "Feature Complete")
        (status . "pending")
        (items
         ("All planned features implemented"
          "Test coverage > 70%"
          "API stability"
          "Offline support basics"))))

      (v0.8
       ((name . "Beta Release")
        (status . "pending")
        (items
         ("User testing feedback incorporated"
          "Accessibility audit complete"
          "Performance optimization"
          "Documentation complete"))))

      (v1.0
       ((name . "Production Release")
        (status . "pending")
        (items
         ("Comprehensive test coverage > 80%"
          "Security audit passed"
          "User documentation complete"
          "Multi-platform deployment ready"))))))))

;;;============================================================================
;;; BLOCKERS & ISSUES
;;;============================================================================

(define blockers-and-issues
  '((critical
     ())  ;; No critical blockers

    (high-priority
     ())  ;; No high-priority blockers

    (medium-priority
     ((test-coverage
       ((description . "Limited test infrastructure")
        (impact . "Risk of regressions")
        (needed . "Comprehensive test suites")))))

    (low-priority
     ((documentation-gaps
       ((description . "Some documentation areas incomplete")
        (impact . "Harder for new contributors")
        (needed . "Expand documentation")))))))

;;;============================================================================
;;; CRITICAL NEXT ACTIONS
;;;============================================================================

(define critical-next-actions
  '((immediate
     (("Review and update documentation" . medium)
      ("Add initial test coverage" . high)
      ("Verify CI/CD pipeline functionality" . high)))

    (this-week
     (("Implement core features" . high)
      ("Expand test coverage" . medium)))

    (this-month
     (("Reach v0.2 milestone" . high)
      ("Complete documentation" . medium)))))

;;;============================================================================
;;; SESSION HISTORY
;;;============================================================================

(define session-history
  '((snapshots
     ((date . "2025-12-17")
      (session . "scm-security-review")
      (accomplishments
       ("Fixed malformed Elm source files (Types.elm, Ports.elm)"
        "SHA-pinned actions/checkout in security-policy.yml"
        "Added SPDX headers and permissions to security workflow"
        "Created flake.nix for Nix fallback support"
        "Updated guix.scm with dual MIT/AGPL license"
        "Improved package descriptions"
        "Updated roadmap with detailed milestones"))
      (notes . "Security hardening and SCM infrastructure review"))
     ((date . "2025-12-15")
      (session . "initial-state-creation")
      (accomplishments
       ("Added META.scm, ECOSYSTEM.scm, STATE.scm"
        "Established RSR compliance"
        "Created initial project checkpoint"))
      (notes . "First STATE.scm checkpoint created via automated script")))))

;;;============================================================================
;;; HELPER FUNCTIONS (for Guile evaluation)
;;;============================================================================

(define (get-completion-percentage component)
  "Get completion percentage for a component"
  (let ((comp (assoc component (cdr (assoc 'components current-position)))))
    (if comp
        (cdr (assoc 'completion (cdr comp)))
        #f)))

(define (get-blockers priority)
  "Get blockers by priority level"
  (cdr (assoc priority blockers-and-issues)))

(define (get-milestone version)
  "Get milestone details by version"
  (assoc version (cdr (assoc 'milestones route-to-mvp))))

;;;============================================================================
;;; EXPORT SUMMARY
;;;============================================================================

(define state-summary
  '((project . "nafa-app-ambient")
    (version . "0.1.0")
    (overall-completion . 35)
    (current-milestone . "v0.1.1 - Security & Infrastructure Hardening")
    (next-milestone . "v0.2 - Core Backend")
    (critical-blockers . 0)
    (high-priority-issues . 0)
    (updated . "2025-12-17")))

;;; End of STATE.scm
