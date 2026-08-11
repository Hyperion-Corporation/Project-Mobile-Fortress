#!/usr/bin/env bash
# Install Godot 4.7.1 export templates for this machine (~1.2 GB download).
set -euo pipefail

VERSION="${GODOT_TEMPLATE_VERSION:-4.7.1.stable}"
URL="${GODOT_TEMPLATE_URL:-https://github.com/godotengine/godot-builds/releases/download/4.7.1-stable/Godot_v4.7.1-stable_export_templates.tpz}"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VERSION}"
CACHE="${TMPDIR:-/tmp}/godot_export_templates_${VERSION}.tpz"

if [[ -d "$DEST" ]] && [[ -f "$DEST/version.txt" || -f "$DEST/android_debug.apk" || -f "$DEST/android_source.zip" ]]; then
  echo "Templates already present: $DEST"
  ls "$DEST" | head -20
  exit 0
fi

mkdir -p "$(dirname "$DEST")"
echo "Downloading $URL ..."
curl -fL --progress-bar -o "$CACHE" "$URL"
echo "Extracting to $DEST ..."
rm -rf "$DEST"
mkdir -p "$DEST"
# .tpz is a zip
unzip -q "$CACHE" -d "${DEST}.extract"
# Archives usually contain templates/* 
if [[ -d "${DEST}.extract/templates" ]]; then
  mv "${DEST}.extract/templates"/* "$DEST/" || true
  rmdir "${DEST}.extract/templates" 2>/dev/null || true
  rmdir "${DEST}.extract" 2>/dev/null || true
else
  # flat extract
  shopt -s dotglob
  mv "${DEST}.extract"/* "$DEST/" 2>/dev/null || true
  rmdir "${DEST}.extract" 2>/dev/null || true
fi
echo "Installed templates:"
ls "$DEST" | head -30
echo "Done. Godot expects: $DEST"
