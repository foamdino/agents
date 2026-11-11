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

if printf '%s' "$cmd" | grep -Eq "${start}(make|cmake)([[:space:]]|$)"; then
	top=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)
	if [ -f "$cwd/nob.c" ] || { [ -n "$top" ] && [ -f "$top/nob.c" ]; }; then
		deny "this project builds with nob (./nob, ./nob test), not make/cmake."
	fi
fi
