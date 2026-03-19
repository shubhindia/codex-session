# Codex Session Zsh Plugin

A lightweight Oh My Zsh plugin that manages Codex CLI sessions per directory
and git branch.

------------------------------------------------------------------------

## Features

- Auto resume Codex sessions scoped to directory + branch
- Session listing with readable columns (`cx ls` / `cx list`)
- Fuzzy session switching with `fzf` + inline session preview
- Auto `cd` into session directory (and branch checkout when available)
- Stale session cleanup (`cxc`)
- Built-in help and environment diagnostics (`cx help`, `cx doctor`)

------------------------------------------------------------------------

## Installation

### Oh My Zsh

```bash
git clone https://github.com/shubhindia/codex-session \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/codex-session
```

Add to your `.zshrc`:

```bash
plugins=(git codex-session)
```

Reload shell:

```bash
source ~/.zshrc
```

------------------------------------------------------------------------

## Commands

```bash
cx                 # Start or resume session for current dir/branch
cx ls              # List saved sessions
cx list            # Same as ls
cx doctor          # Check required tools and plugin paths
cx doc             # Same as doctor
cx help            # Show built-in man-style help
cx -h              # Help shortcut
cxf                # Fuzzy picker with preview, then resume selected session
cxc                # Cleanup stale sessions
```

------------------------------------------------------------------------

## Requirements

- `codex` CLI
- `fzf` (required for `cxf`)
- `git` (optional, enables branch-aware behavior)

------------------------------------------------------------------------

## Configuration

By default, sessions are stored in:

```bash
~/.codex_sessions
```

You can override this location:

```bash
export CODEX_SESSIONS_DIR="$HOME/.my_codex_sessions"
```

------------------------------------------------------------------------

## How It Works

- Creates a key from `realpath(current directory) + git branch`
- Stores session IDs in hashed files under `CODEX_SESSIONS_DIR`
- Maintains an index file at `$CODEX_SESSIONS_DIR/index` for listing/fzf
- Resumes existing session with `codex resume <session_id>`
- Saves new session IDs via `codex resume --last`

------------------------------------------------------------------------

## Notes

- Sessions are isolated per directory + branch
- Works across multiple repositories and terminals
- Session metadata stays in your home directory (no repo pollution)

------------------------------------------------------------------------
