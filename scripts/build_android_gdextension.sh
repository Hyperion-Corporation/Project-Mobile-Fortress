#!/usr/bin/env bash
# Cross-compile mobile_fortress_core for Godot android.arm64 (S8 / T72).
#
# Usage (repo root):
#   bash scripts/build_android_gdextension.sh
#
# Resolves the NDK from ANDROID_NDK_HOME, then $ANDROID_HOME/ndk/<newest>,
# then sdk.dir in local.properties. Needs a host flatc (the desktop build
# produces game/build/_deps/flatbuffers-build/flatc). Writes the gitignored
# library game/bin/libmobile_fortress_core.android.arm64.so.
#
# Does not configure or build game/build, and does not copy the desktop .so.
set -euo pipefail
cd "$(dirname "$0")/.."

GAME="game"
BUILD_DIR="$GAME/build-android-arm64"
OUT_NAME="libmobile_fortress_core.android.arm64.so"
OUT="$GAME/bin/$OUT_NAME"
ABI="arm64-v8a"
PLATFORM="android-33"

if [[ -z "${ANDROID_HOME:-}" && -f local.properties ]]; then
  sdk_dir="$(grep -E '^sdk\.dir=' local.properties | head -1 | cut -d= -f2- | tr -d '\r')"
  if [[ -n "$sdk_dir" && -d "$sdk_dir" ]]; then
    ANDROID_HOME="$sdk_dir"
  fi
fi

ndk=""
if [[ -n "${ANDROID_NDK_HOME:-}" && -f "${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" ]]; then
  ndk="$ANDROID_NDK_HOME"
elif [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME}/ndk" ]]; then
  # sdkmanager layout: ndk/<Pkg.Revision>/build/cmake/android.toolchain.cmake.
  # Highest revision wins.
  ndk=""
  while IFS= read -r candidate; do
    ndk="$candidate"
  done < <(find "${ANDROID_HOME}/ndk" -mindepth 4 -maxdepth 4 -name android.toolchain.cmake -path '*/build/cmake/android.toolchain.cmake' -printf '%h\n' \
    | sed 's|/build/cmake$||' | sort -V)
fi

if [[ -z "$ndk" || ! -f "$ndk/build/cmake/android.toolchain.cmake" ]]; then
  echo "No Android NDK found." >&2
  echo "Install one under \${ANDROID_HOME}/ndk/<version> or set ANDROID_NDK_HOME." >&2
  echo "This machine's SDK is ${ANDROID_HOME:-unset} (local.properties sdk.dir)." >&2
  exit 1
fi

ndk_rev="$(grep -E '^Pkg\.Revision' "$ndk/source.properties" | head -1 | cut -d= -f2 | tr -d ' \r' || true)"
ndk_name="$(grep -E '^Pkg\.ReleaseName' "$ndk/source.properties" | head -1 | cut -d= -f2 | tr -d ' \r' || true)"
echo "NDK: ${ndk_name:-unknown} revision ${ndk_rev:-unknown}"
echo "NDK path: $ndk"

host_flatc="${MF_HOST_FLATC:-}"
if [[ -z "$host_flatc" && -x "$GAME/build/_deps/flatbuffers-build/flatc" ]]; then
  host_flatc="$GAME/build/_deps/flatbuffers-build/flatc"
fi
if [[ -z "$host_flatc" ]]; then
  host_flatc="$(command -v flatc || true)"
fi
if [[ -z "$host_flatc" || ! -x "$host_flatc" ]]; then
  echo "Host flatc not found." >&2
  echo "Build the desktop core once (game/BUILD_CPP.md) or set MF_HOST_FLATC." >&2
  exit 1
fi
echo "Host flatc: $host_flatc"

cmake_args=(
  -S "$GAME"
  -B "$BUILD_DIR"
  -DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake"
  -DANDROID_ABI="$ABI"
  -DANDROID_PLATFORM="$PLATFORM"
  -DANDROID_STL=c++_shared
  -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON
  -DCMAKE_BUILD_TYPE=Release
  "-DMF_HOST_FLATC=$host_flatc"
)
# Reuse the desktop FetchContent checkouts when they exist so this does not
# clone godot-cpp again. Absent checkouts fall through to FetchContent.
if [[ -d "$GAME/build/_deps/godot-cpp-src/.git" || -f "$GAME/build/_deps/godot-cpp-src/CMakeLists.txt" ]]; then
  cmake_args+=("-DFETCHCONTENT_SOURCE_DIR_GODOT-CPP=$PWD/$GAME/build/_deps/godot-cpp-src")
fi
if [[ -f "$GAME/build/_deps/entt-src/CMakeLists.txt" ]]; then
  cmake_args+=("-DFETCHCONTENT_SOURCE_DIR_ENTT=$PWD/$GAME/build/_deps/entt-src")
fi
if [[ -f "$GAME/build/_deps/flatbuffers-src/CMakeLists.txt" ]]; then
  cmake_args+=("-DFETCHCONTENT_SOURCE_DIR_FLATBUFFERS=$PWD/$GAME/build/_deps/flatbuffers-src")
fi

cmake "${cmake_args[@]}"
cmake --build "$BUILD_DIR" -j"$(nproc)" --target mobile_fortress_core

built="$(find "$BUILD_DIR" -name 'libmobile_fortress_core.so' -type f | head -1)"
if [[ -z "$built" ]]; then
  echo "Build finished but libmobile_fortress_core.so was not found under $BUILD_DIR" >&2
  exit 1
fi

mkdir -p "$GAME/bin"
cp -f "$built" "$OUT"
echo "Wrote $OUT"
echo "-- file --"
file "$OUT"
echo "-- readelf -h (machine) --"
readelf -h "$OUT" | grep -E 'Class|Machine|OS/ABI|Type'
echo "-- readelf -lW (LOAD align; 0x4000 is 16 KB) --"
readelf -lW "$OUT" | awk 'NR==1 || /^  Type/ || /LOAD/'
echo "-- readelf -d (NEEDED) --"
readelf -d "$OUT" | awk '/NEEDED/ {print}'
