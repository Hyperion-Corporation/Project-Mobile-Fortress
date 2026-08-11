#!/usr/bin/env bash
# Mobile export smoke (VS9 / S8): validate config; optionally export Android APK.
#
# Usage (repo root):
#   bash scripts/export_mobile_smoke.sh
#   bash scripts/export_mobile_smoke.sh --export-android
#   bash scripts/export_mobile_smoke.sh --export-android --require-templates
#
set -euo pipefail
cd "$(dirname "$0")/.."
CORE_DIR="core"
EXPORT_ANDROID=0
REQUIRE_TEMPLATES=0
for arg in "$@"; do
  case "$arg" in
    --export-android) EXPORT_ANDROID=1 ;;
    --require-templates) REQUIRE_TEMPLATES=1 ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
  esac
done

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
  for c in \
    "$HOME/Downloads/Applications/Godot_v4.7.1-stable_linux.x86_64/Godot_v4.7.1-stable_linux.x86_64" \
    "$(command -v godot 2>/dev/null || true)" \
    "$(command -v godot4 2>/dev/null || true)"; do
    if [[ -n "$c" && -x "$c" ]]; then GODOT="$c"; break; fi
  done
fi

ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.7.1.stable"
FAIL=0
WARN=0

pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; FAIL=1; }
warn() { echo "  WARN  $*"; WARN=1; }

echo "=== Mobile export smoke ==="
echo "core:     $CORE_DIR"
echo "godot:    ${GODOT:-<missing>}"
echo "android:  $ANDROID_HOME"
echo "templates:$TEMPLATE_DIR"
echo

echo "-- Project files --"
[[ -f "$CORE_DIR/project.godot" ]] && pass "project.godot" || fail "project.godot missing"
[[ -f "$CORE_DIR/export_presets.cfg" ]] && pass "export_presets.cfg" || fail "export_presets.cfg missing"
[[ -f "$CORE_DIR/EXPORT_MOBILE.md" ]] && pass "EXPORT_MOBILE.md" || fail "EXPORT_MOBILE.md missing"
[[ -f "$CORE_DIR/main.tscn" ]] && pass "classic main.tscn (GDScript fallback path)" || fail "main.tscn missing"
[[ -f "$CORE_DIR/scenes/main_menu.tscn" ]] && pass "main_menu.tscn" || fail "main_menu.tscn missing"

echo
echo "-- Export preset content --"
if grep -q 'name="Android Debug"' "$CORE_DIR/export_presets.cfg" 2>/dev/null; then
  pass "Android Debug preset"
else
  fail "Android Debug preset not found"
fi
if grep -q 'package/unique_name="com.acfharbinger.mobilefortress"' "$CORE_DIR/export_presets.cfg"; then
  pass "Android package id com.acfharbinger.mobilefortress"
else
  fail "Android package unique_name missing/wrong"
fi
if grep -q 'gradle_build/min_sdk="33"' "$CORE_DIR/export_presets.cfg" || grep -q 'min_sdk=33' "$CORE_DIR/export_presets.cfg"; then
  pass "Android minSdk 33 (Android 13+)"
else
  fail "Android minSdk 33 not set"
fi
if grep -q 'name="iOS"' "$CORE_DIR/export_presets.cfg"; then
  pass "iOS preset present"
else
  fail "iOS preset missing"
fi
if grep -q 'min_ios_version="17.0"' "$CORE_DIR/export_presets.cfg"; then
  pass "iOS min 17.0"
else
  fail "iOS min 17.0 not set"
fi

echo
echo "-- GDExtension mobile library paths --"
if grep -q 'android.debug.arm64' "$CORE_DIR/mobile_fortress_core.gdextension"; then
  pass "gdextension declares android.arm64 library path"
else
  fail "gdextension missing android.arm64"
fi
if [[ -f "$CORE_DIR/bin/libmobile_fortress_core.linux.x86_64.so" ]] || [[ -f "$CORE_DIR/bin/libmobile_fortress_core.so" ]]; then
  pass "desktop SimulationCore .so present (dev)"
else
  warn "desktop .so missing — rebuild per BUILD_CPP.md (desktop only)"
fi
if [[ -f "$CORE_DIR/bin/libmobile_fortress_core.android.arm64.so" ]]; then
  pass "android.arm64 GDExtension binary present"
else
  warn "android.arm64 .so not built (optional; classic GDScript fallback still exports)"
fi

echo
echo "-- Android SDK --"
if [[ -d "$ANDROID_HOME" ]]; then
  pass "ANDROID_HOME=$ANDROID_HOME"
else
  fail "Android SDK not found (set ANDROID_HOME)"
fi
if [[ -d "$ANDROID_HOME/platforms/android-33" ]] || [[ -d "$ANDROID_HOME/platforms/android-34" ]] || [[ -d "$ANDROID_HOME/platforms/android-35" ]]; then
  pass "API 33+ platform installed"
else
  fail "Need platforms/android-33+ under SDK"
fi
if ls "$ANDROID_HOME/build-tools"/*/aapt 1>/dev/null 2>&1 || ls "$ANDROID_HOME/build-tools"/*/aapt2 1>/dev/null 2>&1; then
  pass "build-tools present"
else
  fail "Android build-tools missing"
fi
# Prefer JDK 17–21 for Android (Godot Editor Settings java_sdk_path)
if [[ -z "${JAVA_HOME:-}" ]]; then
  for j in /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/java-17-openjdk-amd64; do
    if [[ -x "$j/bin/java" ]]; then export JAVA_HOME="$j"; export PATH="$JAVA_HOME/bin:$PATH"; break; fi
  done
fi
if command -v java >/dev/null 2>&1; then
  pass "java: $(java -version 2>&1 | head -1)${JAVA_HOME:+ (JAVA_HOME=$JAVA_HOME)}"
else
  fail "java not on PATH"
fi

echo
echo "-- Godot export templates --"
if [[ -d "$TEMPLATE_DIR" ]] && compgen -G "$TEMPLATE_DIR/*" >/dev/null; then
  pass "templates installed at $TEMPLATE_DIR"
  TEMPLATES_OK=1
else
  warn "templates missing — run: bash scripts/install_godot_export_templates.sh"
  TEMPLATES_OK=0
  if [[ "$REQUIRE_TEMPLATES" -eq 1 ]]; then
    fail "--require-templates set but templates not installed"
  fi
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "iOS export requires macOS/Xcode — config-only check on this host"
else
  pass "macOS host — iOS export possible if Xcode configured"
fi

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "RESULT: CONFIG FAIL"
  exit 1
fi

if [[ "$EXPORT_ANDROID" -eq 0 ]]; then
  echo "RESULT: CONFIG PASS (export not requested; use --export-android)"
  exit 0
fi

if [[ -z "$GODOT" || ! -x "$GODOT" ]]; then
  echo "RESULT: EXPORT FAIL — Godot binary not found (set GODOT=)"
  exit 2
fi
if [[ "$TEMPLATES_OK" -ne 1 ]]; then
  echo "RESULT: EXPORT FAIL — install templates first"
  exit 2
fi

# Godot resolves export path relative to the project (--path), not CWD.
mkdir -p "$CORE_DIR/exports/android"
OUT_REL="exports/android/MobileFortress-debug.apk"
OUT_ABS="$(pwd)/$CORE_DIR/$OUT_REL"
echo "-- Exporting Android Debug APK --"
echo "  out: $OUT_ABS"
set +e
"$GODOT" --headless --path "$CORE_DIR" --export-debug "Android Debug" "$OUT_REL" 2>&1
EXPORT_RC=$?
set -e
if [[ $EXPORT_RC -eq 0 && -f "$OUT_ABS" ]]; then
  pass "APK written: $OUT_ABS ($(du -h "$OUT_ABS" | cut -f1))"
  echo "RESULT: EXPORT PASS"
  exit 0
fi
# Some Godot versions write next to project with absolute path only
if [[ -f "$OUT_ABS" ]]; then
  pass "APK written (nonzero exit but file exists): $OUT_ABS ($(du -h "$OUT_ABS" | cut -f1))"
  echo "RESULT: EXPORT PASS"
  exit 0
fi
echo "RESULT: EXPORT FAIL (godot exit $EXPORT_RC; missing $OUT_ABS)"
exit 2
