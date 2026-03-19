# Codex Session Zsh Plugin

A lightweight Oh My Zsh plugin for managing Codex CLI sessions per
directory and git branch.

------------------------------------------------------------------------

## ✨ Features

- 🔄 Auto resume Codex sessions per directory + branch
- 🌿 Git branch--aware sessions
- 🔍 Fuzzy session switching with `fzf`
- 📂 Auto `cd` into session directory
- 🧹 Cleanup stale sessions
- ⚡ Simple aliases for fast usage

------------------------------------------------------------------------

## 📦 Installation

### Oh My Zsh

``` bash
git clone https://github.com/shubhindia/codex-session \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/codex-session
```

Add to your `.zshrc`:

``` bash
plugins=(git codex-session)
```

Reload:

``` bash
source ~/.zshrc
```

------------------------------------------------------------------------

## 🚀 Usage

``` bash
cx     # Start or resume session
cxf    # Fuzzy switch sessions (auto cd + resume)
cxc    # Cleanup stale sessions
```

------------------------------------------------------------------------

## 🔧 Requirements

- `codex` CLI
- `fzf` (for session switching)
- `git` (optional, for branch-aware sessions)

------------------------------------------------------------------------

## 🧠 How it works

- Stores session IDs in `~/.codex_sessions`
- Keys sessions by directory + git branch
- Automatically resumes the correct session
- Uses `codex resume --last` for reliable session tracking

------------------------------------------------------------------------

## 🧹 Cleanup

``` bash
cxc
```

Removes stale or invalid sessions.

------------------------------------------------------------------------

## 📌 Notes

- Sessions are scoped per directory and branch
- Works across multiple repos and terminals
- No repo pollution (everything stored in home directory)

------------------------------------------------------------------------
