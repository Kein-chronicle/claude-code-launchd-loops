# claude-code-launchd-loops

**Generate a macOS launchd job that runs Claude Code headless on a schedule, from one command.**

[![test](https://github.com/Kein-chronicle/claude-code-launchd-loops/actions/workflows/test.yml/badge.svg)](https://github.com/Kein-chronicle/claude-code-launchd-loops/actions/workflows/test.yml) ![license](https://img.shields.io/badge/license-MIT-blue.svg)

## Why

Session-scoped schedules die with the session. A launchd agent keeps an autonomous loop running across restarts. This script writes the wrapper script and the plist for it and refuses invalid minutes.

> **Status: beta (scheduler runtime untested).** macOS only. Tests cover generation and validity, not a real scheduled agent run.

## Install

**As a Claude Code skill** (Claude uses it when the task matches the skill description):

```sh
git clone https://github.com/Kein-chronicle/claude-code-launchd-loops.git ~/.claude/skills/scheduled-claude-loops
```

For a single project, clone into `<project>/.claude/skills/scheduled-claude-loops` instead, then start a new Claude Code session.

**As plain scripts:**

```sh
git clone https://github.com/Kein-chronicle/claude-code-launchd-loops.git
cd claude-code-launchd-loops
```

**Requires:** bash, macOS (plutil, zsh).

## Quick start

Generate and validate a job:

```console
$ bash examples/demo.sh
# Generate a launchd job that runs Claude Code headless at minutes 7 and 37 of every hour
$ scripts/make-loop.sh --name demo --dir /path/to/your/project --minutes 7,37 --prompt-file .demo-tmp/prompt.txt --out .demo-tmp/out
wrote .demo-tmp/out/demo-loop.sh
wrote .demo-tmp/out/com.example.demo-loop.plist
[exit 0]

com.example.demo-loop.plist
demo-loop.sh

# The generated plist, validated:
.demo-tmp/out/com.example.demo-loop.plist: OK

# Minutes outside 0-59 are refused:
$ scripts/make-loop.sh --name demo --dir /tmp --minutes 75 --prompt-file .demo-tmp/prompt.txt --out .demo-tmp/o2
[exit 2]

minute > 59
```

The output above is real: it is produced by the files in `examples/`.

## Use it on your own files

```sh
scripts/make-loop.sh --name nightly --dir "$HOME/Projects/my-app" --minutes 7,37 --prompt-file prompt.txt --out ./out --allowed-tools 'Read Bash(git status:*)'
# review ./out, then: launchctl bootstrap gui/$(id -u) ./out/com.example.nightly-loop.plist   (use --label-prefix com.you for your own label)
```

Sample inputs for every file format are in `examples/` and `tests/`; the details are in [SKILL.md](SKILL.md).

## What it checks

- `make-loop.sh --name N --dir PROJECT --minutes 7,37 --prompt-file P --out OUT` writes `N-loop.sh` and `com.example.N-loop.plist`.
- Permissions are not skipped by default: grant tools with `--allowed-tools`; `--unsafe-skip-permissions` is an explicit opt-in that prints a warning.
- Directory, label prefix and tool list are rejected if they contain shell or XML metacharacters, and so is a prompt file with a bare `PROMPT_EOF` line.
- Rejects minutes outside 0-59, a relative `--dir`, and metacharacters in paths; the plist is `plutil`-valid and the wrapper parses under `zsh -n`.
- Use `--label-prefix com.you` for the launchd label. You review the files, then load them yourself with `launchctl bootstrap gui/$(id -u) <plist>`.

## Limits

- macOS only.
- Tests cover generation and validity, not a real scheduled agent run.
- The default label prefix is `com.example`: pass `--label-prefix`.

## Related projects

These solve neighbouring problems; use them when they fit better.

- **Claude Code `/loop` and scheduled tasks**: built-in and session-scoped
- **cron**: no per-user GUI session environment on macOS

## More from the same collection

Small, tested tools that grew out of running AI agents and game/app pipelines for months:

- [**claude-code-memory-lint**](https://github.com/Kein-chronicle/claude-code-memory-lint): Lint a Claude Code memory folder: orphan files, missing files, oversized index lines, and the index lines that are silently cut at load.
- [**claude-code-session-cost**](https://github.com/Kein-chronicle/claude-code-session-cost): Estimate what a Claude Code project cost from its session logs, sub-agents included, with both cache-TTL price assumptions shown.
- [**pidfile-process-watchdog**](https://github.com/Kein-chronicle/pidfile-process-watchdog): A small process watchdog with an honest state machine: pid and working-directory identity, restart grace, flap warnings, and giving up.

## Development

```sh
bash tests/test.sh
```

The tests include inputs that are supposed to be rejected, so a green run also shows the checks can fail. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

If this saved you a debugging session, a star helps other people find it. Bug reports and failing test cases are even better.

<sub>Keywords: claude-code, claude-skills, agent-skills, launchd, macos, automation, scheduling, cron</sub>
