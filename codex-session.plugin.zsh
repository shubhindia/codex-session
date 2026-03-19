# ================================
# Codex Session Manager Plugin
# ================================

# ---- Config ----
CODEX_SESSIONS_DIR="${CODEX_SESSIONS_DIR:-$HOME/.codex_sessions}"
CODEX_INDEX_FILE="$CODEX_SESSIONS_DIR/index"

mkdir -p "$CODEX_SESSIONS_DIR"

# ---- Helpers ----

_codex_help() {
	cat <<'EOF' | ${PAGER:-less}
CODEX-SESSION(1)

NAME
    codex-session - directory & branch-aware Codex CLI session manager

SYNOPSIS
    cx        Start or resume a Codex session
    cx list   List all sessions
    cx doctor Diagnose environment
    cxf       Fuzzy find and switch sessions
    cxc       Clean up stale sessions

DESCRIPTION
    codex-session provides persistent Codex CLI sessions scoped to the
    current directory and git branch.

    Sessions are automatically saved and resumed, allowing seamless
    context switching across projects.

COMMANDS
    cx
        Start or resume session for current directory and branch.

    cx list
        List all stored sessions.

    cx doctor
        Show environment diagnostics.

    cxf
        Interactive session switcher using fzf.

    cxc
        Remove stale or invalid sessions.

FILES
    ~/.codex_sessions/
        Stores session metadata and mappings.

REQUIREMENTS
    codex CLI
    fzf (for session switching)
    git (optional)

VERSION
    0.1.0

HOMEPAGE
    https://github.com/shubhindia/codex-session

AUTHOR
    Shubham Gopale

EOF
}

_codex_get_cwd() {
	realpath .
}

_codex_get_branch() {
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		git rev-parse --abbrev-ref HEAD 2>/dev/null
	fi
}

_codex_make_key() {
	local cwd="$1"
	local branch="$2"
	echo -n "$cwd::$branch" | md5sum | awk '{print $1}'
}

_codex_reverse_file() {
	if command -v tac >/dev/null 2>&1; then
		tac "$1"
	else
		tail -r "$1"
	fi
}

_codex_safe_sed_delete() {
	local pattern="$1"
	if sed --version >/dev/null 2>&1; then
		sed -i "\|$pattern|d" "$CODEX_INDEX_FILE"
	else
		sed -i '' "\|$pattern|d" "$CODEX_INDEX_FILE"
	fi
}

_codex_list() {
	if [ ! -f "$CODEX_INDEX_FILE" ]; then
		echo "No sessions found"
		return
	fi

	printf "%-20s %-50s %-15s %s\n" "SESSION" "DIRECTORY" "BRANCH" "CREATED"
	echo "--------------------------------------------------------------------------------"

	_codex_reverse_file "$CODEX_INDEX_FILE" |
		awk -F'|' '{printf "%-20s %-50s %-15s %s\n", $1, $2, $3, $4}'
}

_codex_doctor() {
	echo "Codex Session Doctor"
	echo "--------------------"

	command -v codex >/dev/null && echo "✅ codex CLI found" || echo "❌ codex CLI missing"
	command -v fzf >/dev/null && echo "✅ fzf found" || echo "⚠️ fzf missing (needed for cxf)"
	command -v git >/dev/null && echo "✅ git found" || echo "⚠️ git missing (branch support)"

	echo ""
	echo "Sessions dir: $CODEX_SESSIONS_DIR"
	echo "Index file:   $CODEX_INDEX_FILE"
}

# ---- Main: codexx ----

codexx() {
	# ---- Command handling ----
	case "$1" in
	-h | --help | help)
		_codex_help
		return
		;;
	list)
		_codex_list
		return
		;;
	doctor)
		_codex_doctor
		return
		;;
	esac

	# ---- Dependency check ----
	command -v codex >/dev/null || {
		echo "❌ codex CLI not found"
		return 1
	}

	local cwd=$(_codex_get_cwd)
	local branch=$(_codex_get_branch)

	local key=$(_codex_make_key "$cwd" "$branch")
	local session_file="$CODEX_SESSIONS_DIR/$key"

	# ---- Resume ----
	if [ -f "$session_file" ]; then
		local session_id=$(cat "$session_file")

		echo "🔄 Resuming Codex"
		echo "   dir: $cwd"
		[ -n "$branch" ] && echo "   branch: $branch"
		echo "   session: $session_id"

		if codex resume "$session_id"; then
			return
		else
			echo "⚠️ Session invalid, removing..."
			rm -f "$session_file"
			[ -f "$CODEX_INDEX_FILE" ] && _codex_safe_sed_delete "$session_id"
		fi
	fi

	# ---- Start new ----
	echo "🆕 Starting new Codex session..."
	echo "   dir: $cwd"
	[ -n "$branch" ] && echo "   branch: $branch"

	codex

	local session_id=$(codex resume --last 2>/dev/null | awk '{print $3}' | head -1)

	if [ -n "$session_id" ]; then
		echo "$session_id" >"$session_file"
		echo "$session_id|$cwd|$branch|$(date '+%Y-%m-%d %H:%M:%S')" >>"$CODEX_INDEX_FILE"
		echo "💾 Saved session"
	else
		echo "⚠️ Could not detect session ID"
	fi
}

# ---- Fuzzy picker: codexf ----

codexf() {
	if [ ! -f "$CODEX_INDEX_FILE" ]; then
		echo "No sessions found"
		return
	fi

	local selection=$(_codex_reverse_file "$CODEX_INDEX_FILE" |
		awk -F'|' '{printf "%s|%s|%s|%s\n", $1, $2, $3, $4}' |
		fzf --prompt="Codex Sessions ❯ " --height=40% --border)

	[ -z "$selection" ] && return

	local session_id=$(echo "$selection" | cut -d'|' -f1)
	local target_dir=$(echo "$selection" | cut -d'|' -f2)
	local branch=$(echo "$selection" | cut -d'|' -f3)

	echo "📂 Switching to $target_dir"
	cd "$target_dir" || return

	if [ -n "$branch" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		git checkout "$branch" >/dev/null 2>&1
	fi

	echo "🔄 Resuming session $session_id"
	codex resume "$session_id"
}

# ---- Cleanup: codexc ----

codexc() {
	if [ ! -f "$CODEX_INDEX_FILE" ]; then
		echo "No sessions to clean"
		return
	fi

	echo "🧹 Cleaning stale sessions..."

	while IFS='|' read -r session_id cwd branch ts; do
		if ! codex resume "$session_id" >/dev/null 2>&1; then
			echo "❌ Removing stale: $session_id"

			local key=$(_codex_make_key "$cwd" "$branch")
			rm -f "$CODEX_SESSIONS_DIR/$key"

			_codex_safe_sed_delete "$session_id"
		fi
	done <"$CODEX_INDEX_FILE"

	echo "✅ Cleanup done"
}

# ---- Aliases ----
alias cx="codexx"
alias cxf="codexf"
alias cxc="codexc"
