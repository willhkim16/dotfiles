#!/bin/bash
# Claude Code's Notification hook: a desktop notification that, when clicked, brings the
# terminal window this session runs in to the front.
#
# Wayland doesn't let an app raise another app's window, but a KWin script can. The window is
# found by process: the hook's ancestors are claude, its shell, then the terminal (Alacritty),
# and KWin knows each window's pid, so the nearest ancestor that owns a window is the one.

input=$(cat)
msg=$(python3 -c 'import json,sys; d=json.loads(sys.argv[1] or "{}"); print(d.get("message") or "Waiting for you")' "$input" 2>/dev/null)
dir=$(python3 -c 'import json,sys,os; d=json.loads(sys.argv[1] or "{}"); print(os.path.basename(d.get("cwd") or ""))' "$input" 2>/dev/null)
icon=$(ls -d "$HOME"/.vscode/extensions/anthropic.claude-code-*/resources/claude-logo.png 2>/dev/null | sort -V | tail -n 1)

# This process's ancestors, nearest first.
pids=()
p=$PPID
while [ "$p" -gt 1 ] 2>/dev/null; do
  pids+=("$p")
  p=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null) || break
done
pid_list=$(IFS=,; echo "${pids[*]}")

# The notification waits for a click, so it runs detached: the hook returns at once.
setsid bash -c '
  act=$(notify-send -a "Claude Code" -i "$1" -A default=Show "Claude Code${2:+ · $2}" "$3")
  [ "$act" = default ] || exit 0
  name="claude-focus-$$"
  js=$(mktemp --suffix=.js)
  cat > "$js" <<EOF
const pids = [$4];
const wins = workspace.windowList();
for (const pid of pids) {
  const w = wins.find((w) => w.pid === pid && w.normalWindow);
  if (w) { w.minimized = false; workspace.activeWindow = w; break; }
}
EOF
  id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$js" "$name")
  qdbus6 org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script.run
  sleep 1
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$name"
  rm -f "$js"
' _ "$icon" "$dir" "$msg" "$pid_list" </dev/null >/dev/null 2>&1 &

exit 0
