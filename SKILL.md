---
name: scheduled-claude-loops
description: Run a recurring autonomous Claude Code job reliably on macOS using launchd instead of in-session cron. Use when the user wants "do X every N minutes/hours" for days, when session cron fires get dropped, or when you need a generator for the shell wrapper + LaunchAgent plist + load/verify/stop commands.
---

# scheduled-claude-loops

**Why not session cron:** an in-session scheduler only fires when the session is idle waiting for input. If
the session is handling a channel event, running a tool or compacting, the fire is **dropped**. A loop that
looked healthy (session alive 24/7) ran only a fraction of its ticks.

**Pattern:** launchd `StartCalendarInterval` -> small shell wrapper -> `claude -p "<prompt>"` -> log. One process
per tick, no dependency on an interactive session.

## Generate

```bash
scripts/make-loop.sh --name docs-sweep --dir /path/to/project \
    --minutes 7,37 --prompt-file prompt.txt --out ./out
# writes out/docs-sweep-loop.sh and out/com.example.docs-sweep-loop.plist (does NOT install)
```
Review both files, then:

```bash
cp out/com.example.docs-sweep-loop.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.example.docs-sweep-loop.plist
launchctl print gui/$(id -u)/com.example.docs-sweep-loop | head      # loaded? next fire?
launchctl bootout gui/$(id -u)/com.example.docs-sweep-loop           # stop (files can stay)
```

## Rules

- Schedules: every 30 min = two `Minute` entries (7 and 37); hourly = one; specific time = `Hour` + `Minute`.
- If a session cron already exists for the same job, **delete it** - double firing.
- The wrapper must set `PATH` and `HOME` explicitly: launchd's environment is nearly empty.
- Put reporting (message/notification) *inside* the prompt, so a tick's result is not lost in a log.
- Every tick costs API usage; confirm the user knows the cadence x cost.
- The generated wrapper does **not** skip permissions by default. Grant what the job needs with `--allowed-tools "Read Bash(git status:*)"`.
  `--unsafe-skip-permissions` adds `--dangerously-skip-permissions` (unrestricted power, prints a warning): only for prompts that cannot be steered
  into destructive actions, and keep `--add-dir` limited to the project.
- The generator refuses directories, prefixes and tool lists containing shell or XML metacharacters, and prompt files containing a bare `PROMPT_EOF` line.
- Verify after the first fire: state `running`, child `claude -p` process exists, log shows the tick header.
- Prefer one "scheduler of record" per job. Two things that can both kill/restart the same service will race.
