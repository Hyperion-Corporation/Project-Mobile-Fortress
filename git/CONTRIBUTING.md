# Contributing to Mobile Fortress

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![Android](https://img.shields.io/badge/Android-API_24%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![CI](https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/ci.yml/badge.svg)](https://github.com/ACFHarbinger/Project-Mobile-Fortress/actions/workflows/ci.yml)

> **Version**: 2.0
> **Last Updated**: 2026-08-03

Thank you for your interest in contributing to Mobile Fortress! This document covers setup, style, and the PR process.

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Development Setup](#2-development-setup)
3. [Code Style Guidelines](#3-code-style-guidelines)
4. [Git Workflow](#4-git-workflow)
5. [Pull Request Process](#5-pull-request-process)
6. [Testing Requirements](#6-testing-requirements)
7. [Issue Reporting](#7-issue-reporting)

---

## 1. Getting Started

### 1.1 Prerequisites

- **Android**: Android Studio (or JDK 17 + Android SDK cmdline-tools), Android SDK Platform 35 + Build-Tools 35.0.0.
- **iOS**: a native macOS host with Xcode 15+ — there is no Linux/devcontainer path for iOS, see [`.devcontainer/README.md`](../.devcontainer/README.md).
- [`just`](https://github.com/casey/just) as the command runner.
- `pre-commit` (`pip install pre-commit && pre-commit install`).

### 1.2 Clone and bootstrap

```bash
git clone https://github.com/ACFHarbinger/Project-Mobile-Fortress.git
cd Project-Mobile-Fortress
just --list
```

## 2. Development Setup

Two product modules: `android/app/`, a standard Android Studio Gradle module, and `ios/MyGame/`, a standard Xcode project. Raw shared assets and a documented spec live under `core/` — see [`core/README.md`](../core/README.md). See [`docs/DEVELOPMENT.md`](../docs/DEVELOPMENT.md) for full setup on both platforms and [`.devcontainer/devcontainer.json`](../.devcontainer/devcontainer.json) for a one-click containerized **Android** setup.

## 3. Code Style Guidelines

Follow [`.agent/rules/kotlin.md`](../.agent/rules/kotlin.md) / [`.agent/rules/swift.md`](../.agent/rules/swift.md) and the rest of `.agent/rules/`. Formatting/linting is automated via `.pre-commit-config.yaml` — run `pre-commit run --all-files` before pushing.

## 4. Git Workflow

- Branch from `main`: `feature/<short-description>` or `fix/<short-description>`.
- Keep commits focused; write commit messages that explain *why*, not just *what*.
- Rebase onto `main` before opening a PR.

## 5. Pull Request Process

1. Fill out the [PR template](../.github/PULL_REQUEST_TEMPLATE.md) in full, including the platform(s) affected.
2. Ensure CI is green: Android changes need `just lint-check && just unit-test`; iOS changes need `just ios-check && just ios-test` (macOS host).
3. Request review; address feedback with new commits (don't force-push during review).
4. Squash-merge once approved.

## 6. Testing Requirements

Every new Android `engine/` class needs a unit test; every new Android lifecycle/UI-touching change needs an instrumented test. Every new iOS `Engine/`/`Core/` type needs an `ios/Tests/` case. Changes to shared behavior (state machine, level schema) need `core/src/` updated alongside both platforms' implementations. See [`.agent/rules/testing_qa.md`](../.agent/rules/testing_qa.md).

## 7. Issue Reporting

Use the [issue templates](../.github/ISSUE_TEMPLATE/) — they help both humans and coding agents triage faster.
