#!/usr/bin/env bash
# Generate a launchd-driven `claude -p` loop (wrapper + plist). Does not install anything.
set -eu
name=""; dir=""; minutes=""; pfile=""; out="."; prefix="com.example"; allowed=""; unsafe=0
while [ $# -gt 0 ]; do case "$1" in
  --name) name="$2"; shift 2;; --dir) dir="$2"; shift 2;; --minutes) minutes="$2"; shift 2;;
  --prompt-file) pfile="$2"; shift 2;; --out) out="$2"; shift 2;; --label-prefix) prefix="$2"; shift 2;; --allowed-tools) allowed="$2"; shift 2;; --unsafe-skip-permissions) unsafe=1; shift;;
  *) echo "unknown arg $1" >&2; exit 2;; esac; done
[ -n "$name" ] && [ -n "$dir" ] && [ -n "$minutes" ] && [ -f "$pfile" ] || { echo "usage: make-loop.sh --name N --dir D --minutes 7,37 --prompt-file F [--out O] [--label-prefix com.you] [--allowed-tools \"Read Bash(git status:*)\"] [--unsafe-skip-permissions]" >&2; exit 2; }
# values are written into a shell script and an XML plist: refuse anything that could break out of either
case "$dir" in *[\"\$\`\\\<\>\&\'\;]*|*$'\n'*) echo "dir contains a character that is unsafe in a script/plist" >&2; exit 2;; esac
case "$dir" in /*) ;; *) echo "--dir must be an absolute path (launchd does not expand ~ or relative paths)" >&2; exit 2;; esac
case "$prefix" in *[!a-zA-Z0-9.-]*) echo "label prefix must be [A-Za-z0-9.-]" >&2; exit 2;; esac
case "$allowed" in *[\"\$\`\\]*|*$'\n'*) echo "allowed-tools contains an unsafe character" >&2; exit 2;; esac
grep -qx 'PROMPT_EOF' "$pfile" && { echo "prompt file must not contain a line that is exactly PROMPT_EOF" >&2; exit 2; }
case "$name" in *[!a-zA-Z0-9_-]*) echo "name must be [A-Za-z0-9_-]" >&2; exit 2;; esac
[[ "$minutes" =~ ^[0-9]+(,[0-9]+)*$ ]] || { echo "minutes must be comma-separated integers" >&2; exit 2; }
for m in ${minutes//,/ }; do case "$m" in ''|*[!0-9]*) echo "bad minute: $m" >&2; exit 2;; esac; [ "$m" -le 59 ] || { echo "minute > 59" >&2; exit 2; }; done
mkdir -p "$out"; outabs="$(cd "$out" && pwd)"
case "$outabs" in *[\"\$\`\\\<\>\&\'\;]*|*$'\n'*) echo "output path contains a character that is unsafe in a script/plist" >&2; exit 2;; esac
label="$prefix.$name-loop"
sh="$out/$name-loop.sh"; plist="$out/$label.plist"
[ ! -e "$sh" ] && [ ! -L "$sh" ] && [ ! -e "$plist" ] && [ ! -L "$plist" ] || { echo "output already exists; refusing overwrite" >&2; exit 2; }
set -C
{
  echo '#!/bin/zsh'
  echo 'set -u'
  echo 'export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"'
  echo "PROJECT_DIR=\"$dir\""
  echo "LOG=\"\$HOME/.claude/$name-loop.log\""
  echo 'cd "$PROJECT_DIR" || exit 1'
  echo 'mkdir -p "$HOME/.claude" || exit 1'
  echo 'echo "===== $(date "+%Y-%m-%d %H:%M:%S %Z") tick =====" >> "$LOG"'
  echo "PROMPT=\$(cat <<'PROMPT_EOF'"
  cat "$pfile"
  printf '\n'
  echo 'PROMPT_EOF'
  echo ')'
  flags='--add-dir "$PROJECT_DIR"'
  [ -n "$allowed" ] && flags="$flags --allowedTools \"$allowed\""
  [ $unsafe = 1 ] && flags="$flags --dangerously-skip-permissions" && echo "WARNING: --unsafe-skip-permissions gives the unattended agent unrestricted power" >&2
  echo "claude -p \"\$PROMPT\" $flags >> \"\$LOG\" 2>&1"
  echo 'rc=$?'
  echo 'echo "----- tick done (exit $rc) -----" >> "$LOG"'
  echo 'exit "$rc"'
} > "$sh"
chmod +x "$sh"
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  echo '<plist version="1.0"><dict>'
  echo "  <key>Label</key><string>$label</string>"
  echo "  <key>ProgramArguments</key><array><string>/bin/zsh</string><string>$outabs/$name-loop.sh</string></array>"
  echo "  <key>WorkingDirectory</key><string>$dir</string>"
  echo '  <key>StartCalendarInterval</key><array>'
  for m in ${minutes//,/ }; do echo "    <dict><key>Minute</key><integer>$m</integer></dict>"; done
  echo '  </array>'
  echo '  <key>RunAtLoad</key><false/>'
  echo "  <key>StandardOutPath</key><string>/tmp/$name-loop.out.log</string>"
  echo "  <key>StandardErrorPath</key><string>/tmp/$name-loop.err.log</string>"
  echo '</dict></plist>'
} > "$plist"
echo "wrote $sh"; echo "wrote $plist"
