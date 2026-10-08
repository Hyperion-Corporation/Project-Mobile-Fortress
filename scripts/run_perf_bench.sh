#!/usr/bin/env bash
# T44 (P7): run the headless SimulationCore tick-budget benchmark.
#
# Manual gate only — NEVER wire into CI (timing is machine-dependent).
# Uses a private XDG_DATA_HOME so parallel Godot runs don't share user://.
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-$(mktemp -d)/xdg}"
godot --path game --headless --script res://tests/perf_budget_bench.gd
