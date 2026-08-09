# Mobile Fortress - Root Justfile
# https://github.com/casey/just
# Entry point. All recipes delegate to sub-modules via `mod`.
# Invoke sub-module recipes directly with dot notation: just build::debug
# Or use the root shorthands defined below.
#
# Android's app module (android/app/) is built via the root Gradle wrapper
# directly (./gradlew), never a bare `gradle`, so the pinned wrapper version
# (see gradle/wrapper/gradle-wrapper.properties) is what actually runs — the
# Gradle root lives at the repo root (settings.gradle.kts, build.gradle.kts)
# alongside package.json's npm workspaces, with :app mapped to android/app/.
# iOS (ios/) is built via `xcodebuild` and requires a macOS host — see
# .devcontainer/README.md; iOS recipes will fail on the Linux devcontainer.

set shell := ["bash", "-c"]

red := '\033[0;31m'
green := '\033[0;32m'
yellow := '\033[0;33m'
blue := '\033[0;34m'
purple := '\033[0;35m'
cyan := '\033[0;36m'
bold := '\033[1m'
reset := '\033[0m'

# --- Submodules ---

mod agent 'tools/agent/justfile'
mod build 'tools/build'
mod ci 'tools/ci'
mod docs 'tools/docs'
mod helper 'tools/helper'
mod infra 'tools/infra'
mod reducer 'tools/reducer'
mod test 'tools/test'
mod validation 'tools/validation'

# --- Default target ---

default: help

# --- Help ---

# Print available commands
help: helper::_print_header
    @echo -e "{{bold}}Build — Android (android/){{reset}}"
    @echo "  just apk                    Assemble the debug APK (see tools/build/justfile)"
    @echo "  just assemble-release       Assemble a signed release App Bundle (.aab)"
    @echo "  just install                Install the debug build on a connected device/emulator"
    @echo ""
    @echo -e "{{bold}}Build — iOS (ios/, macOS host only){{reset}}"
    @echo "  just ios-build               Build MyGame for the iOS Simulator"
    @echo "  just ios-archive             Archive a Release build (unsigned .xcarchive)"
    @echo ""
    @echo -e "{{bold}}Test{{reset}}"
    @echo "  just unit-test               Run Android unit tests (JVM, fast)"
    @echo "  just test-instrumented       Run Android instrumented tests on a connected device/emulator"
    @echo "  just ios-test                 Run the iOS XCTest suite on a simulator"
    @echo ""
    @echo -e "{{bold}}Lint / Format{{reset}}"
    @echo "  just lint-check              ktlint + Android Lint (see tools/validation/justfile)"
    @echo "  just format                 Auto-fix ktlint formatting issues"
    @echo "  just ios-check                Analyze the iOS sources (xcodebuild analyze)"
    @echo ""
    @echo -e "{{bold}}CI / Maintenance{{reset}}"
    @echo "  just check                  Full local Android pre-PR gate: lint -> unit tests -> debug build"
    @echo "  just check-ios               Full local iOS pre-PR gate: analyze -> test"
    @echo "  just pre-commit              Run pre-commit hooks against all files"
    @echo "  just clean                   Remove all Android (Gradle) build outputs"
    @echo "  just clean-ios                Remove all iOS (Xcode) build outputs"
    @echo ""
    @echo -e "{{bold}}Docs{{reset}}"
    @echo "  just build-docs              Build the MkDocs documentation site"
    @echo ""
    @echo -e "{{bold}}Optional backend (infra/){{reset}}"
    @echo "  just docker-up               Start the optional backend stack locally"
    @echo "  just docker-down             Stop the optional backend stack"
    @echo ""
    @echo "Run 'just <module>::' with no recipe to list that module's recipes, e.g. 'just build::'"

# --- Shorthands ---
# Note: none of these share a name with a `mod` above (just forbids that);
# use the module directly (e.g. `just build::debug`) for anything not listed here.

# Assemble the debug APK (android/)
apk: helper::_print_header
    just build::debug

# Assemble a signed release App Bundle (.aab) for the Play Store (android/)
assemble-release: helper::_print_header
    just build::release

# Install the debug build on a connected device/emulator (android/)
install: helper::_print_header
    just build::install

# Build MyGame for the iOS Simulator (ios/, macOS host only)
ios-build: helper::_print_header
    just build::ios-build

# Archive a Release build of MyGame — unsigned .xcarchive (ios/, macOS host only)
ios-archive: helper::_print_header
    just build::ios-archive

# Run unit tests (JVM, fast) (android/)
unit-test: helper::_print_header
    just test::unit

# Run instrumented tests on a connected device/emulator (android/)
test-instrumented: helper::_print_header
    just test::instrumented

# Run the iOS XCTest suite on a simulator (ios/, macOS host only)
ios-test: helper::_print_header
    just test::ios

# Run ktlint + Android Lint (android/)
lint-check: helper::_print_header
    just validation::check

# Auto-fix ktlint formatting issues (android/)
format: helper::_print_header
    just validation::fix

# Analyze the iOS sources via xcodebuild analyze (ios/, macOS host only)
ios-check: helper::_print_header
    just validation::ios-check

# Full local Android pre-PR gate: lint, unit tests, debug build
check: helper::_print_header
    just ci::pr-gate

# Full local iOS pre-PR gate: analyze, test (ios/, macOS host only)
check-ios: helper::_print_header
    just ci::pr-gate-ios

# Run pre-commit hooks against all files
pre-commit: helper::_print_header
    just ci::pre-commit

# Clean all Android (Gradle) build outputs
clean: helper::_print_header
    just reducer::clean

# Clean all iOS (Xcode) build outputs (ios/, macOS host only)
clean-ios: helper::_print_header
    just reducer::clean-ios

# Build the MkDocs documentation site
build-docs: helper::_print_header
    just docs::build

# Start the optional backend stack locally
docker-up: helper::_print_header
    just infra::docker-up

# Stop the optional backend stack
docker-down: helper::_print_header
    just infra::docker-down
