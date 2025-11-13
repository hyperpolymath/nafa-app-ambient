# === NAFA - Neurodiverse App for Adventurers ===
# Primary control plane for all development and CI/CD tasks.
# Uses Oil shell, as requested.

# --- Configuration ---

# Set Oil as the default shell for all recipes.
set shell := ["oil", "-n", "-c"]

# Define all asdf-managed tools.
# nodejs is for ReScript, Elm, and Tauri's JS side.
# rust is for Tauri, Nickel, and Kotlin/Native (if needed).
ASDF_TOOLS := "elixir nodejs rust elm kotlin"

# Define global dependencies installed via npm/cargo.
NPM_GLOBALS := "rescript"
CARGO_GLOBALS := "tauri-cli nickel-lang-cli"

# --- Aliases & Helpers ---

# Alias for the main setup task.
alias s := setup

# Alias for running the full development stack.
alias r := run

# Alias for running all checks (lint, format, types).
alias c := check

# Alias for running all tests (unit, integration).
alias t := test

# Alias for building all project artifacts.
alias b := build

# --- Recipes ---

# Default recipe: Show available commands (this help text).
default:
  @just --list

### --------------------------------------------------
### 🛠️ SETUP & BOOTSTRAP
### --------------------------------------------------

# [s] Bootstraps the complete development environment.
setup: setup:scripts setup:asdf setup:tools setup:deps config
  @echo "✅ Environment is ready. Use 'just run' to start."

# Helper: Ensure setup scripts are executable.
setup:scripts:
  @chmod +x scripts/*.oil scripts/*.nu scripts/*.sh

# Installs asdf and all plugins defined in .tool-versions.
setup:asdf: .tool-versions
  @echo "Installing asdf plugins: {{ASDF_TOOLS}}..."
  @scripts/setup.oil

# Installs global CLI tools (ReScript, Tauri, Nickel) via npm/cargo.
setup:tools:
  @echo "Installing global npm/cargo tools..."
  @npm install -g {{NPM_GLOBALS}}
  @cargo install {{CARGO_GLOBALS}}

# Installs all project-specific dependencies.
setup:deps:
  @echo "Installing project dependencies..."
  @just deps:backend deps:ui deps:logic deps:mobile

# Installs Elixir backend dependencies (and configures Bandit).
deps:backend: elixir-backend/mix.exs
  @echo "Backend: Installing Mix dependencies..."
  @cd elixir-backend && mix deps.get
  @echo "Backend: Ensuring Bandit is the web adapter..."
  @sed -i 's/adapter: Phoenix.Endpoint.Cowboy2Adapter/adapter: Bandit.PhoenixAdapter/' elixir-backend/config/config.exs

# Installs Elm UI dependencies.
deps:ui: elm-ui/elm.json
  @echo "UI: Installing Elm dependencies..."
  @cd elm-ui && elm-tooling install

# Installs ReScript logic dependencies (via npm).
deps:logic: rescript-logic/package.json
  @echo "Logic: Installing ReScript npm dependencies..."
  @cd rescript-logic && npm install

# Installs Kotlin Multiplatform dependencies (via Gradle).
deps:mobile: kotlin-modules/build.gradle.kts
  @echo "Mobile: Installing Gradle dependencies..."
  @cd kotlin-modules && ./gradlew dependencies

### --------------------------------------------------
### ⚙️ CONFIGURATION
### --------------------------------------------------

# Generates all environment configs from Nickel.
config:
  @echo "Generating configuration from Nickel rituals..."
  @mkdir -p config/
  @nickel export nickel-rituals/main.ncl --format json > config/development.json
  @nickel export nickel-rituals/main.ncl --format json --override 'env="production"' > config/production.json
  @echo "✅ Configs generated in config/"

### --------------------------------------------------
### 🏁 RUN & DEVELOP
### --------------------------------------------------

# [r] Runs the entire application stack concurrently.
run:
  @echo "Starting NAFA stack (Backend, UI, Logic, Tauri)..."
  # This requires a concurrent runner, e.g., 'overmind' or 'systemd'.
  # For simplicity, we'll run the main Phoenix server which hosts assets.
  @cd elixir-backend && mix phx.server

# Run the Tauri splash/host app in development mode.
run:tauri:
  @cd tauri-shell && cargo tauri dev

# Run the Elixir (Phoenix+Bandit) backend.
run:backend:
  @cd elixir-backend && mix phx.server

# Run the Elm UI in development mode (e.g., with elm-live).
run:ui:
  @cd elm-ui && elm-live src/Main.elm --open -- --output=../elixir-backend/priv/static/assets/elm.js

# Run the ReScript logic compiler in watch mode.
run:logic:
  @cd rescript-logic && npx rescript build -w

### --------------------------------------------------
### ✅ CHECK, LINT, FORMAT
### --------------------------------------------------

# [c] Runs all formatters, linters, and type-checkers.
check: format lint typecheck

# Formats all codebases.
format:
  @echo "Formatting all code..."
  @cd elixir-backend && mix format
  @cd elm-ui && elm-format src/ --yes
  @cd rescript-logic && npx rescript format -all
  @cd tauri-shell && cargo fmt

# Lints all codebases.
lint:
  @cd elixir-backend && mix credo
  # Add other linters (e.g., elm-review) here.

# Type-checks all relevant codebases.
typecheck:
  @cd elixir-backend && mix dialyzer
  @cd elm-ui && elm make src/Main.elm --output=/dev/null
  # ReScript is type-checked at compile time.

### --------------------------------------------------
### 🧪 TEST
### --------------------------------------------------

# [t] Runs all tests (unit, integration, e2e).
test: test:backend test:logic test:ui test:mobile

test:backend:
  @cd elixir-backend && mix test

test:logic:
  @cd rescript-logic && npm test

test:ui:
  @cd elm-ui && elm-test

test:mobile:
  @cd kotlin-modules && ./gradlew check

### --------------------------------------------------
### 📦 BUILD & COMPILE
### --------------------------------------------------

# [b] Creates a full production build of all artifacts.
build: clean build:logic build:ui build:backend:assets build:tauri

# Builds the ReScript logic (JS output).
build:logic:
  @cd rescript-logic && npx rescript build

# Builds the Elm UI (JS output).
build:ui:
  @cd elm-ui && elm make src/Main.elm --optimize --output=../elixir-backend/priv/static/assets/elm.js

# Builds the Tauri native splash host.
build:tauri:
  @cd tauri-shell && cargo tauri build

# Builds and digests static assets for the Phoenix backend.
build:backend:assets:
  @cd elixir-backend && mix phx.digest

### --------------------------------------------------
### 🚀 DEPLOY & PACKAGE
### --------------------------------------------------

# Deploys the application (default: build and push Podman container).
deploy: package:podman:push

# Builds the production Podman container.
package:podman:build:
  @echo "Building production container with Podman..."
  @podman build -t nafa-app:latest -f Containerfile .

# Pushes the container to the GitLab registry.
package:podman:push: package:podman:build
  @echo "Pushing container to GitLab registry..."
  @podman push nafa-app:latest $CI_REGISTRY_IMAGE/nafa-app:latest

### --------------------------------------------------
### 🧹 CLEANUP
### --------------------------------------------------

# Cleans all build artifacts and temporary files.
clean:
  @echo "Cleaning project..."
  @cd elixir-backend && mix phx.digest.clean --all
  @cd elixir-backend && rm -rf _build deps
  @cd rescript-logic && npx rescript clean
  @cd rescript-logic && rm -rf node_modules
  @cd elm-ui && rm -rf elm-stuff
  @cd tauri-shell && cargo clean
  @cd kotlin-modules && ./gradlew clean
  @rm -rf config/*.json

# Full environment scrub (use with caution).
clean:all: clean
  @echo "Running robot-repo-cleaner..."
  @salt-call --local state.apply robot-repo-cleaner

### --------------------------------------------------
### 🤖 CI/CD TASKS
### --------------------------------------------------

# Special setup task for CI runners.
ci:setup: setup:scripts setup:asdf setup:tools

# CI-specific test run that generates coverage reports.
ci:test:
  @echo "Running CI tests with coverage..."
  @cd elixir-backend && mix test --cover
  # Add other coverage commands

# CI-specific build.
ci:build