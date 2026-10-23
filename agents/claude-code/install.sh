#!/bin/sh
# Install (or remove) the Ghostty status hook for Claude Code.
#
# Usage:
#   install.sh [--uninstall] [--all | CLAUDE_CONFIG_DIR ...]
#
# With no folders, uses $CLAUDE_CONFIG_DIR, or ~/.claude. --all uses every
# ~/.claude* folder that holds a Claude config, one per account. Before the
# first change, the settings file is copied to settings.json.before-ghostty
# (never overwritten later). Installing twice is safe.

set -eu

uninstall=0
all=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --uninstall) uninstall=1 ;;
    --all) all=1 ;;
    *) break ;;
  esac
  shift
done

if ! command -v jq >/dev/null 2>&1; then
  echo "install.sh needs jq (brew install jq)" >&2
  exit 1
fi

src_dir=$(cd "$(dirname "$0")" && pwd)
hook_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/agents/claude-code"
hook="$hook_dir/ghostty-agent-status"

if [ "$uninstall" -eq 0 ]; then
  mkdir -p "$hook_dir"
  cp "$src_dir/ghostty-agent-status" "$hook"
  chmod +x "$hook"
fi

if [ "$all" -eq 1 ]; then
  set --
  for dir in "$HOME"/.claude "$HOME"/.claude-*; do
    [ -d "$dir" ] || continue
    if [ -e "$dir/settings.json" ] || [ -e "$dir/.claude.json" ] || [ -d "$dir/projects" ]; then
      set -- "$@" "$dir"
    fi
  done
  if [ "$#" -eq 0 ]; then
    echo "No Claude config folders found in $HOME" >&2
    exit 1
  fi
fi

[ "$#" -gt 0 ] || set -- "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

for dir in "$@"; do
  settings="$dir/settings.json"
  mkdir -p "$dir"
  [ -f "$settings" ] || echo '{}' >"$settings"
  [ -e "$settings.before-ghostty" ] || cp "$settings" "$settings.before-ghostty"
  tmp="$settings.ghostty-tmp"

  jq --arg cmd "$hook" --argjson uninstall "$uninstall" '
    # Drop any hook entries we added before.
    def strip(ev):
      if .hooks[ev] then
        .hooks[ev] |= map(select(
          (.hooks // []) | all(.command // "" | contains("ghostty-agent-status") | not)))
        | if .hooks[ev] == [] then del(.hooks[ev]) else . end
      else . end;

    def add(ev; matcher):
      .hooks[ev] = (.hooks[ev] // []) + [
        (if matcher then {matcher: matcher} else {} end)
        + {hooks: [{type: "command", command: $cmd, timeout: 5}]}
      ];

    def events: ["SessionStart", "UserPromptSubmit", "PreToolUse",
                 "PostToolUse", "Notification", "Stop", "StopFailure",
                 "SessionEnd"];

    .hooks //= {}
    | reduce events[] as $ev (.; strip($ev))
    | if $uninstall == 1 then .
      else
        add("SessionStart"; null)
        | add("UserPromptSubmit"; null)
        | add("PreToolUse"; "*")
        | add("PostToolUse"; "*")
        | add("Notification"; null)
        | add("Stop"; null)
        | add("StopFailure"; null)
        | add("SessionEnd"; null)
      end
    | if .hooks == {} then del(.hooks) else . end
  ' "$settings" >"$tmp"
  mv "$tmp" "$settings"

  if [ "$uninstall" -eq 1 ]; then
    echo "Removed the Ghostty status hook from $settings"
  else
    echo "Installed the Ghostty status hook in $settings"
  fi
done
