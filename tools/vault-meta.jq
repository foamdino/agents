# vault-meta.jq: check a frontmatter plan, or render one entry's frontmatter.
# Run as: jq -r --arg mode check -f vault-meta.jq PLAN              -> one line per problem
#         jq -r --arg mode render --argjson i N -f vault-meta.jq PLAN -> frontmatter for entry N
# Tags are derived here: project/<p> and component/<c> first, then the entry's own tags.
def slug: type == "string" and test("^[a-z0-9][a-z0-9-]*$");
def tag: type == "string" and test("^[a-z0-9][a-z0-9/-]*$");
def list(f): type == "array" and all(.[]; f);
def fields: ["path", "type", "projects", "components", "tags", "related"];

def problems:
  if type != "array" then "plan: not a JSON array"
  else
    ([.[] | .path? | select(type == "string")] | group_by(.)[] | select(length > 1)
      | "\(.[0]): listed more than once"),
    (to_entries[] | .key as $k | .value as $e
      | if ($e | type) != "object" then "entry \($k): not an object"
        else ($e.path // "entry \($k)") as $p
        | (if ($e.path | type) == "string" and ($e.path | test("\\.md$"))
             and ($e.path | test("^(/|~|agent/)|(^|/)\\.\\.(/|$)") | not) then empty
           else "\($p): path must be a relative .md path outside agent/, without .." end),
          (if $e.type | slug then empty else "\($p): type must be a lowercase slug" end),
          (if $e.projects | list(slug) then empty else "\($p): projects must be a list of slugs" end),
          (if $e.components | list(slug) then empty else "\($p): components must be a list of slugs" end),
          (if $e.tags | list(tag) then empty else "\($p): tags must be a list of lowercase tags" end),
          (if $e.related | list(type == "string" and test("^[^\\[\\]|#]+$") and (test("\\.md$") | not)) then empty
           else "\($p): related must be a list of vault paths without [[ ]], # or .md" end),
          (($e | keys) - fields | .[] | "\($p): unknown field \(.)")
        end)
  end;

def render($e):
  (($e.projects | map("project/" + .)) + ($e.components | map("component/" + .)) + $e.tags)
  | (reduce .[] as $t ([]; if any(.[]; . == $t) then . else . + [$t] end)) as $tags
  | "---",
    "type: \($e.type)",
    "projects: \($e.projects | tojson)",
    "components: \($e.components | tojson)",
    "tags: \($tags | tojson)",
    "related: \($e.related | map("[[\(.)]]") | tojson)",
    "---",
    "";

if $mode == "check" then problems
elif $mode == "render" then render(.[$ARGS.named.i])
else error("mode must be check or render") end
