#!/bin/sh
# PreToolUse hook (Bash): rules from ~/.config/agents/AGENTS.md that must hold
# whatever the agent remembers.
#
# - Dependency Rule: no package installs (brew/pip/pip3/npm/pnpm/yarn/cargo/gem/
#   go/uv install or add, python -m pip install, uv pip install, uv tool install),
#   and system package managers on any platform: pacman/paru/yay -S or -U (not
#   the -Ss/-Si/-Sl/-Sg queries), apt/apt-get/aptitude/yum/dnf/port/snap/flatpak
#   install/reinstall/upgrade, zypper install/in, apk add.
#   The agent asks the user instead.
# - Build System Convention: no make/cmake where the session cwd or its git root
#   has a nob.c.
# - Code Intelligence: no rg/grep for Spring @...Mapping annotations; list a
#   repo's endpoints with ~/.config/agents/tools/endpoints.sh. Passes when the
#   search names a .java file (reading a line endpoints.sh flags as truncated)
#   or the command carries the comment "# not in scan" (repo missing from the
#   estate DB).
# - zsh quoting: no unquoted word starting with "=" ("echo =====" is =cmd
#   expansion and fails the whole command). Quoted strings, [[ ]] and heredoc
#   bodies pass.
# Matches a command at the start of the line or after ; & | ( or sudo, so
# "rg 'pip install'" passes.
# Output: a PreToolUse "deny" decision with the reason; nothing otherwise.

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

deny() {
	jq -nc --arg r "Blocked by ~/.config/agents/hooks/bash-guard.sh: $1" '{hookSpecificOutput: {
	  hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
	exit 0
}

start='(^|[;&|(][[:space:]]*)(sudo[[:space:]]+)?'
if printf '%s' "$cmd" | grep -Eq "${start}((brew|pip3?|npm|pnpm|yarn|cargo|gem|go)[[:space:]]+(install|add|i)([[:space:]]|$)|python3?[[:space:]]+-m[[:space:]]+pip[[:space:]]+install|uv[[:space:]]+(pip|tool)[[:space:]]+install|uv[[:space:]]+add)"; then
	deny "installing packages needs the user's confirmation (Dependency Rule). Tell the user which tool or package would help and the command to install it, and let them run it."
fi

args='[[:space:]]+([^;&|]*[[:space:]])?'
if printf '%s' "$cmd" | grep -Eq "${start}((pacman|paru|yay)${args}(-S[^[:space:]sigl]*|--sync|-U[^[:space:]]*|--upgrade)|(apt|apt-get|aptitude|yum|dnf|port|snap|flatpak)${args}(install|reinstall|upgrade|dist-upgrade|full-upgrade)|zypper${args}(install|in)|apk${args}add)([[:space:]]|$)"; then
	deny "installing packages needs the user's confirmation (Dependency Rule). Tell the user which tool or package would help and the command to install it, and let them run it."
fi

if printf '%s' "$cmd" | grep -Eq "${start}(rg|grep)[[:space:]].*@[^[:space:]]*Mapping" &&
	! printf '%s' "$cmd" | grep -Eq '\.java([[:space:]]|$)|# not in scan'; then
	deny "list REST endpoints with ~/.config/agents/tools/endpoints.sh ~/thg-src/estate/db/current.db <repo> (AGENTS.md Code Intelligence). Grep a single .java file to read a line it flags as truncated; if the repo is not in the scan, add the comment '# not in scan' to the command."
fi

# Drop heredoc bodies (zsh does no =cmd expansion inside them, quoted delimiter
# or not), then quoted strings, then look for a word starting with "=".
# Bodies end at a line equal to their delimiter (leading tabs allowed after
# <<-), in the order the << appeared; <<< is a here-string, not a heredoc.
# A "<<WORD" inside a quoted string is taken as a heredoc too, which can only
# let a command through, never block one.
nobodies=$(printf '%s\n' "$cmd" | awk -v q="'" '
	BEGIN { i = 0; n = 0; re = "<<-?[ \t]*[\"" q "]?[A-Za-z_][A-Za-z0-9_]*[\"" q "]?" }
	i < n {
		line = $0
		if (tabs[i]) sub(/^\t+/, "", line)
		if (line == delim[i]) i++
		next
	}
	{
		print
		s = $0
		gsub(/<<</, "", s)
		while (match(s, re)) {
			tok = substr(s, RSTART + 2, RLENGTH - 2)
			s = substr(s, RSTART + RLENGTH)
			tabs[n] = (substr(tok, 1, 1) == "-")
			gsub("[-\"" q " \t]", "", tok)
			delim[n++] = tok
		}
	}')
unquoted=$(printf '%s' "$nobodies" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
if printf '%s' "$unquoted" | grep -Eq '[[:space:]]=[^[:space:]]' &&
	! printf '%s' "$unquoted" | grep -Fq '[['; then
	deny "the shell is zsh, where an unquoted word starting with '=' (echo =====, [ a == b ]) is =cmd expansion and fails the whole command. Quote it: echo '=====', or use [ a = b ]."
fi

if printf '%s' "$cmd" | grep -Eq "${start}(make|cmake)([[:space:]]|$)"; then
	top=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)
	if [ -f "$cwd/nob.c" ] || { [ -n "$top" ] && [ -f "$top/nob.c" ]; }; then
		deny "this project builds with nob (./nob, ./nob test), not make/cmake."
	fi
fi
