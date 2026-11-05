# Vault notes

Purpose: keep a linked record of the work in the Obsidian vault at `~/thoughts`, so later
tasks can find what was decided, fixed or proposed before, in any project. Different from the
retro (`retro.md`), which improves the agent setup: this records the work itself.

The user's notes are at the vault's top level and in its project folders. **Agents write only
in `~/thoughts/agent/`, and never edit anything outside it.** Never open or quote a credential
note (Secrets Rule in `AGENTS.md`); `~/thoughts/.ignore` keeps them out of `rg`, but **only
without `-g`/`--glob`**: an explicit glob overrides ignore files. Filter rg output with a pipe
(`rg --files ~/thoughts | rg '\.md$'`), never with `-g`.

## Recall (before non-trivial work)
- Search the vault for the project and for the components you'll touch:
  `rg -il '<project>|<component>' ~/thoughts` (e.g. `muze|arena`). Read what matches,
  agent notes and the user's own (meeting notes, ideas, project notes).
- A note that clashes with the task (a meeting decision, an earlier fix, an open proposal)
  → report it and ask before going on (Contradictions rule).
- Work in `~/projects/<repo>`: also run
  `~/.config/agents/tools/estate-card.sh ~/thg-src/estate/db/out-all.db <repo>`. If the
  task changes an API, message, client library or deploy, its "depends-on-this" repos and
  owners are a clash like the notes above: report them and ask. The card is a snapshot
  (its `scan` line); notes may name repos and counts, never hosts or findings.
- A proposal for the same component in another project ("high-water mark for `arena.h`" in
  t2 while working on muze) → mention it.

## Capture (when a unit of work is finished)
A unit is finished when its task is done and nothing is waiting on the user's answer or
approval. If the unit isn't finished, stop without a note.

Worth a note:
- a decision and its reason, with the options considered and their prior art;
- a fix and its root cause;
- an idea or proposal for later, especially one that applies to code shared across projects;
- a clash found with the user's notes, and how it was settled.

Not worth a note: restating the diff, routine edits, anything already in the repo's docs.
"Nothing worth noting" is a valid outcome: say so in one line and write nothing.

Rules:
- One note per session and topic. If a note with this `session` already covers the topic,
  update it instead of writing a second one.
- Link only to notes that exist: check with `rg --files ~/thoughts | rg -i '<name>'`.
  Link to the user's notes by name (`[[Order flow notes]]`, `[[Muze/Similar projects]]`)
  and to other agent notes (`[[2026-11-03 arena high-water mark]]`). Link to the section
  when one fits: `[[Order flow notes#Retries]]`.
- If the topic has a common short name, add it as `aliases: [arena]` in the frontmatter so
  Obsidian's link suggestions find the note.
- No secrets, hostnames or customer data: describe the pattern, not the data.
- Then tell the user in one line which note was written or updated.

## Note format
Path: `~/thoughts/agent/YYYY-MM-DD <topic>.md`. Topic is a few words, no project prefix.

```markdown
---
type: fix            # fix | feature | decision | idea | investigation | review
date: 2026-11-04
projects: [muze, t2]           # every project it applies to
components: [arena.h]          # shared code, modules, services; [] if none
repos: [~/side/muze]
session: <session id>
agent: claude-opus-5-5         # or local:<model>
tags: [agent, type/fix, project/muze, component/arena]
---
# <Title>

<One or two sentences: what and why.>

## Details
What changed or was found, with `path:line` and function names.

## Decision
Options considered, the pick, the reason, prior art. Omit if none.

## Related
- [[Muze/Similar projects]] — why it's related
- [[2026-11-03 arena high-water mark]] — why it's related

## Open
Questions or follow-ups. Add the tag `open` while any remain. Omit if none.
```

Tags are lowercase, `/`-nested, hyphens for spaces: `project/order-processing`,
`component/arena`. Reuse existing tags: `rg -o 'project/[a-z0-9-]+|component/[a-z0-9-]+'
~/thoughts/agent | sort -u`.

`~/thoughts/agent/Agent notes.base` is an Obsidian Bases view over these notes; don't edit it.
