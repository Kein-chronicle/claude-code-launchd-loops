#!/usr/bin/env bash
set -u; here="$(cd "$(dirname "$0")" && pwd)"; d="$(mktemp -d)"; bad=0
echo "Summarize new commits and report." > "$d/p.txt"
"$here/../scripts/make-loop.sh" --name demo --dir /tmp/proj --minutes 7,37 --prompt-file "$d/p.txt" --out "$d/out" >/dev/null
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; bad=1; fi; }
ok "wrapper is executable" "[ -x $d/out/demo-loop.sh ]"
ok "wrapper parses (zsh -n)" "zsh -n $d/out/demo-loop.sh"
ok "plist is valid" "plutil -lint $d/out/com.example.demo-loop.plist >/dev/null"
ok "two Minute entries" "[ \$(grep -c '<key>Minute</key>' $d/out/com.example.demo-loop.plist) = 2 ]"
ok "prompt embedded" "grep -q 'Summarize new commits' $d/out/demo-loop.sh"
"$here/../scripts/make-loop.sh" --name demo --dir /tmp --minutes 75 --prompt-file "$d/p.txt" --out "$d/o2" >/dev/null 2>&1; rc=$?
ok "minute > 59 rejected with exit 2" "[ $rc = 2 ]"
ok "default wrapper does not skip permissions" "! grep -q dangerously $d/out/demo-loop.sh"
"$here/../scripts/make-loop.sh" --name u --dir /tmp --minutes 7 --prompt-file "$d/p.txt" --out "$d/o3" --unsafe-skip-permissions >/dev/null 2>&1
ok "unsafe flag is explicit opt-in" "grep -q dangerously $d/o3/u-loop.sh"
"$here/../scripts/make-loop.sh" --name a --dir /tmp --minutes 7 --prompt-file "$d/p.txt" --out "$d/o4" --allowed-tools "Read Bash(git status:*)" >/dev/null 2>&1
ok "allowed tools are passed through" "grep -qF 'allowedTools \"Read Bash(git status:*)\"' $d/o4/a-loop.sh"
"$here/../scripts/make-loop.sh" --name e --dir '/tmp/x"; touch /tmp/pwned; echo "' --minutes 7 --prompt-file "$d/p.txt" --out "$d/o5" >/dev/null 2>&1; rc=$?
ok "directory with shell metacharacters is rejected" "[ $rc != 0 ] && [ ! -e $d/o5 ]"
printf 'hi\nPROMPT_EOF\ntouch /tmp/pwned2\n' > "$d/evil.txt"
"$here/../scripts/make-loop.sh" --name e2 --dir /tmp --minutes 7 --prompt-file "$d/evil.txt" --out "$d/o6" >/dev/null 2>&1; rc=$?
ok "prompt that closes the heredoc is rejected" "[ $rc != 0 ]"
"$here/../scripts/make-loop.sh" --name e3 --dir '/tmp/a<b' --minutes 7 --prompt-file "$d/p.txt" --out "$d/o7" >/dev/null 2>&1; rc=$?
ok "XML metacharacter in dir is rejected" "[ $rc != 0 ]"
mkdir -p "$d/a&b"; "$here/../scripts/make-loop.sh" --name o --dir /tmp --minutes 7 --prompt-file "$d/p.txt" --out "$d/a&b" >/dev/null 2>&1; rc=$?
ok "output path with an XML metacharacter is rejected" "[ $rc = 2 ]"
"$here/../scripts/make-loop.sh" --name r --dir relative/dir --minutes 7 --prompt-file "$d/p.txt" --out "$d/o8" >/dev/null 2>&1; rc=$?
ok "relative --dir is rejected" "[ $rc = 2 ]"
python3 "$here/test_runtime.py" || bad=1
rm -rf "$d"; exit $bad
