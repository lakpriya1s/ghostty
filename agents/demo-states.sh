#!/bin/sh
# Cycle this tab through every OSC 7501 state so you can see the faces.
# Switch to another tab during "done" and "blocked" to get notifications.

report() {
  printf '\033]7501;state=%s:app=claude-code%s:msg=%s\033\\' \
    "$1" "$2" "$(printf '%s' "$3" | base64 | tr -d '\n')"
  echo "$1: $3"
  sleep "${DELAY:-4}"
}

report idle "" "Ready"
report working "" "Edit: src/auth/session.ts"
report blocked ":kind=permission" "Claude needs your permission to use Bash"
report working "" "Bash: Run the test suite"
report done "" "Finished"
report error "" "API error: overloaded"
printf '\033]7501;state=clear\033\\'
echo "cleared"
