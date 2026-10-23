#!/bin/sh
# Install (or remove) the Ghostty status hook for Claude Code.
#
# Usage:
#   install.sh [--uninstall] [CLAUDE_CONFIG_DIR ...]
#
# With no folders, uses $CLAUDE_CONFIG_DIR, or ~/.claude. Run it once for
# each Claude account folder you use. The settings file is backed up to
# settings.json.bak before it is changed, and installing twice is safe.

set -eu

uninstall=0
if [ "${1:-}" = "--uninstall" ]; then
  uninstall=1
  shift
fi

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

[ "$#" -gt 0 ] || set -- "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

for dir in "$@"; do
  settings="$dir/settings.json"
  mkdir -p "$dir"
  [ -f "$settings" ] || echo '{}' >"$settings"
  cp "$settings" "$settings.bak"

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
                 "PostToolUse", "Notification", "Stop", "SessionEnd"];

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
        | add("SessionEnd"; null)
      end
    | if .hooks == {} then del(.hooks) else . end
  ' "$settings.bak" >"$settings"

  if [ "$uninstall" -eq 1 ]; then
    echo "Removed the Ghostty status hook from $settings"
  else
    echo "Installed the Ghostty status hook in $settings"
  fi
done
