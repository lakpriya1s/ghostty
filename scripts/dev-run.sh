#!/bin/sh
# Build the macOS dev app and restart it.
#
#   scripts/dev-run.sh          rebuild the core if needed, build the app, restart it
#   scripts/dev-run.sh --core   always rebuild the core first
#   scripts/dev-run.sh --no-build   just restart the last build
#
# The core (src/, include/) is rebuilt only when a file there is newer than
# macos/GhosttyKit.xcframework. Logs go to $LOG_DIR (default: /tmp).
#
# Runs macos/build/Debug/Ghostty.app. Never zig-out/Ghostty.app: a plain
# `zig build` copies over it in place and macOS refuses to launch it
# (see scope/tasks/07-dev-build.md).

set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
APP="$ROOT/macos/build/Debug/Ghostty.app"
KIT="$ROOT/macos/GhosttyKit.xcframework"
LOG_DIR=${LOG_DIR:-/tmp}

core=auto
build=yes
for arg in "$@"; do
  case "$arg" in
    --core) core=yes ;;
    --no-build) build=no ;;
    -h | --help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [ "$build" = yes ]; then
  if [ "$core" = auto ]; then
    core=no
    if [ ! -d "$KIT" ] ||
      [ -n "$(find "$ROOT/src" "$ROOT/include" -newer "$KIT/Info.plist" -type f -print -quit)" ]; then
      core=yes
    fi
  fi

  if [ "$core" = yes ]; then
    echo "==> zig build -Demit-macos-app=false (log: $LOG_DIR/ghostty-core.log)"
    (cd "$ROOT" && zig build -Demit-macos-app=false) >"$LOG_DIR/ghostty-core.log" 2>&1 || {
      tail -40 "$LOG_DIR/ghostty-core.log"
      exit 1
    }
    # xcodebuild only relinks when the framework looks newer.
    touch "$KIT/Info.plist"
  fi

  echo "==> xcodebuild Debug (log: $LOG_DIR/ghostty-xcode.log)"
  (cd "$ROOT/macos" && xcodebuild -target Ghostty -configuration Debug) \
    >"$LOG_DIR/ghostty-xcode.log" 2>&1 || {
    grep -E "error:|BUILD FAILED" "$LOG_DIR/ghostty-xcode.log" | head -40
    exit 1
  }
fi

[ -d "$APP" ] || { echo "no build at $APP" >&2; exit 1; }

# Quit the running dev copy, and wait for it, or `open` just focuses it.
if pgrep -f "$APP/Contents/MacOS/" >/dev/null; then
  echo "==> quitting the running dev copy"
  osascript -e "tell application \"$APP\" to quit" >/dev/null 2>&1 || true
  i=0
  while pgrep -f "$APP/Contents/MacOS/" >/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge 50 ]; then
      pkill -f "$APP/Contents/MacOS/" || true
      break
    fi
    sleep 0.1
  done
fi

echo "==> open $APP"
open "$APP"
