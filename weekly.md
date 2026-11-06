# Weekly review

Purpose: once a week, show the user what they did across every project, find one change that
would carry over to another project, and give each quiet project a nudge. Different from the
retro (`retro.md`, which improves the agent setup) and from vault capture (`vault.md`, which
records one unit of work): this looks across the week and across projects.

Run by the `/weekly` skill. A SessionStart hook (`hooks/weekly-due.sh`) reminds when the newest
review is more than 7 days old. **Propose only:** never edit a project, its TODO or its docs.
The only file written is the review note.

## 1. Gather
- Facts: `~/.config/agents/tools/weekly-facts.sh --author foamdino@gmail.com ~/projects/* ~/side/* ~/.config/agents`.
  It reports status (active / warm / dormant), the user's commits on all branches, files
  changed this week (uncommitted, or any file in a non-git project such as t2), and plan files.
  Squash-merged PRs show a commit twice (with and without `(#123)`); count it once.
- Agent notes from the window: `rg --files ~/thoughts/agent | rg '/20[0-9-]{8} '`, keeping
  those whose date is on or after the `since` line. Read them: they hold the decisions, fixes
  and ideas that commits don't show.
- The user's own notes changed in the window (read-only; never `-g`, see `vault.md`):
  `rg --files -0 ~/thoughts | xargs -0 sh -c 'find "$@" -prune -newermt "$0"' <since> | rg -v '/agent/'`.
- Previous review: the newest `~/thoughts/agent/* weekly review.md`. Don't repeat its headline
  suggestion unless something changed; say if it was picked up.
- Drill into a commit or file only when a theme or suggestion needs it (`git show --stat`).

## 2. Write the note
Path: `~/thoughts/agent/YYYY-MM-DD weekly review.md` (run date). If a review for this date exists,
update it. It counts as this session's vault note, so don't write a second one.

```markdown
---
type: review
date: 2026-11-06
since: 2026-10-30
projects: [t2, agent-setup]      # every active project
components: []                   # shared code that came up
session: <session id>
agent: claude-opus-5-5
tags: [agent, type/review, weekly-review]
---
# Weekly review 2026-W45
```

Sections, in this order:

### At a glance
One line of counts: commits, projects touched, notes written, decisions made.

### What I did
The point of this section is to show the week's real size, so it must be complete. Group by
**theme, not repo**: a theme can span repos and note-only work (a design decision with no code is
still work done). Per theme: a bold title, 2–4 lines on what changed and why, the projects, and
links to the agent notes behind it. Include work with no commit (uncommitted files, non-git
projects).

### Try this next week
**One** suggestion: a change made this week in project A that would be a small, useful step for
project B. Requirements:
- Name the source: project, commit hash or note, and what the change does.
- Show it fits the target: read the target's code and cite `path:line` where it would go. If you
  can't find the spot, it isn't the pick.
- Size it (S/M) and give the first concrete step.
- Prefer shared components (the `components:` field across notes; `arena.h` in muze and t2), then
  side → main transfers, then main → side.

### Side ↔ main
Which side projects fed into main projects this week, or the reverse, with evidence (the same
component or pattern on both sides, code ported, a note naming both). "None this week" is valid.

### Projects
- **Active**, then **Warm**: names only, one line each.
- **Dormant**: for each, quiet since (`last`) and one **next chunk**, a step small enough for one
  session. Source it from the project's plan files and docs first; failing that, from something
  that worked in another project this week (say which). Repos whose `last` is `never` (checked out,
  never committed to) go on one line by name, with no next chunk.

### Seeds
1–3 loose ideas the week suggests: a new approach, a tool, a new project. Speculation is fine
here; label it as such. Omit the section if nothing comes to mind.

### Open
Agent notes from the window still tagged `open`, one line each with a link. Omit if none.

## Rules
- Links only to notes that exist (`vault.md` → Rules). No secrets, hostnames or customer data.
- Projects in `~/projects` are THG work: name repos, never hosts or findings.
- Finish by telling the user, in 2–3 lines, the path of the note and the headline suggestion.
