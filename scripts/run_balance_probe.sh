#!/usr/bin/env bash
# T73 (A4/Q10 prep): run the manual scripted balance probe.
#
# Manual analysis only — NEVER wire into CI (results are balance data, not
# pass/fail gates, and runtimes are machine-dependent). Uses a private
# XDG_DATA_HOME so parallel Godot runs don't share user://.
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-$(mktemp -d)/xdg}"
godot --path game --headless --script res://tests/balance_probe.gd
