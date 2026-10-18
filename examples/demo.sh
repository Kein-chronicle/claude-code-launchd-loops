#!/usr/bin/env bash
cd "$(dirname "$0")/.."
run() { printf '$ %s\n' "$*"; "$@"; printf '[exit %s]\n\n' "$?"; }
tmp=.demo-tmp; rm -rf "$tmp"; mkdir "$tmp"; trap 'rm -rf "$tmp"' EXIT
echo "Summarize new commits and report." > "$tmp/prompt.txt"
echo "# Generate a launchd job that runs Claude Code headless at minutes 7 and 37 of every hour"
run scripts/make-loop.sh --name demo --dir /path/to/your/project --minutes 7,37 --prompt-file "$tmp/prompt.txt" --out "$tmp/out"
ls "$tmp/out"
echo
echo "# The generated plist, validated:"
plutil -lint "$tmp/out/com.example.demo-loop.plist"
echo
echo "# Minutes outside 0-59 are refused:"
run scripts/make-loop.sh --name demo --dir /tmp --minutes 75 --prompt-file "$tmp/prompt.txt" --out "$tmp/o2"
