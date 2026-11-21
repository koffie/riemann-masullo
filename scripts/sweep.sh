#!/usr/bin/env bash
# Close out one library file with a single agent (a "sweeper"): it takes every open, unclaimed
# proof issue of that file at once, works through them in one worktree, and hands in one pull
# request that closes the ones it proved. Single provers leave a file's hard tail behind; a
# sweeper has the whole file, more time and a stronger model.
#
#   scripts/sweep.sh RiemannMasullo/<Chapter>/<File>.lean [--model M] [--effort E] [--dry-run]
#
# What it does:
#   1. lists the file's open proof issues (by the `<!-- sorry: path::name -->` marker);
#   2. opens a `sweep` issue with that list and what project members wrote on those issues,
#      and marks the unclaimed ones `claimed`, so that nobody else works in the file meanwhile;
#   3. runs `scripts/agent.sh sweeper <that issue>` (prompt: prompts/sweeper.md), which builds,
#      checks that no statement changed, and opens the pull request;
#   4. releases the issues the pull request does not close.
# Issues that someone else has claimed are left alone and named to the agent as such.
set -euo pipefail
file=${1:?usage: sweep.sh RiemannMasullo/<Chapter>/<File>.lean [--model M] [--effort E] [--dry-run]}
shift
model=gpt-6.2-astra; effort=xhigh; dry=0
while [ $# -gt 0 ]; do
  case $1 in
    --model) model=$2; shift 2 ;;
    --effort) effort=$2; shift 2 ;;
    --dry-run) dry=1; shift ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done
main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
cd "$main"
[ -f "$file" ] || { echo "no such file: $file" >&2; exit 2; }
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

# The plan: which issues, and the text of the sweep issue. Only text written by the owner,
# members or collaborators is quoted, as everywhere else that feeds an agent's prompt.
python3 - "$file" "$work" <<'EOF'
import json, re, subprocess, sys
path, work = sys.argv[1], sys.argv[2]
MEMBER = ("OWNER", "MEMBER", "COLLABORATOR")


def api(url, jq):
    out = subprocess.run(["gh", "api", "--paginate", url, "--jq", jq], capture_output=True, text=True)
    if out.returncode:
        sys.exit(out.stderr)
    return [json.loads(line) for line in out.stdout.splitlines() if line.strip()]


issues = api("repos/{owner}/{repo}/issues?state=open&labels=proof&per_page=100",
             ".[] | select(.pull_request | not) | {number, body, labels: [.labels[].name]} | tojson")
lines = open(path).read().splitlines()
mine, others = [], []
for issue in sorted(issues, key=lambda i: i["number"]):
    m = re.search(r"<!-- sorry: (\S+?)::(\S+) -->", issue["body"] or "")
    if not m or m.group(1) != path:
        continue
    name = m.group(2)
    at = next((k + 1 for k, text in enumerate(lines)
               if re.match(rf"\s*(?:\w+\s+)*(?:theorem|lemma|def|instance|abbrev)\s+{re.escape(name)}\b", text)), None)
    if at is None:
        continue                                  # already proved or renamed on this checkout
    row = dict(number=issue["number"], name=name, line=at)
    (others if {"claimed", "stuck", "blocked"} & set(issue["labels"]) else mine).append(row)
if not mine:
    sys.exit(f"{path}: no open, unclaimed proof issue")

body = [f"Close out `{path}`: prove every remaining `sorry` listed here, in one pull request. "
        "The rules are in `prompts/sweeper.md`.", "",
        "| Issue | Declaration | Line |", "|---|---|---|"]
body += [f"| #{r['number']} | `{r['name']}` | {r['line']} |" for r in mine]
if others:
    body += ["", "Claimed by someone else, or set aside: leave these declarations alone.", ""]
    body += [f"- #{r['number']} `{r['name']}`" for r in others]
notes = []
for r in mine:
    comments = api(f"repos/{{owner}}/{{repo}}/issues/{r['number']}/comments?per_page=100",
                   ".[] | {body, association: .author_association} | tojson")
    kept = [c["body"].strip() for c in comments if c["association"] in MEMBER and len(c["body"]) > 300
            and not re.match(r"\s*(claim|releas)", c["body"], re.I)]
    if kept:
        notes += [f"### #{r['number']} `{r['name']}`", ""] + [text[:4000] for text in kept[-2:]] + [""]
if notes:
    body += ["", "## What earlier attempts reported", ""] + notes
open(f"{work}/body.md", "w").write("\n".join(body) + "\n")
open(f"{work}/mine.txt", "w").write("".join(f"{r['number']}\n" for r in mine))
print(f"{path}: {len(mine)} to prove" + (f", {len(others)} left to others" if others else ""))
EOF

if [ $dry = 1 ]; then cat "$work/body.md"; exit 0; fi

chapter=$(sed -nE 's#^RiemannMasullo/(Ch[0-9]+|App[A-E])_.*#\1#p' <<<"$file" | tr '[:upper:]' '[:lower:]' | sed 's/^app\(.\)/app\U\1/')
args=(--title "Sweep: close out \`${file#RiemannMasullo/}\`" --body-file "$work/body.md" --label sweep)
[ -z "$chapter" ] || args+=(--label "$chapter")
n=$(gh issue create "${args[@]}" | sed -n 's#.*/issues/\([0-9]*\)$#\1#p')
[ -n "$n" ] || { echo "could not open the sweep issue" >&2; exit 1; }
echo "sweep issue #$n"
while read -r i; do
  gh issue edit "$i" --add-label claimed >/dev/null 2>&1 || true
  gh issue comment "$i" --body "Claimed by a sweeper agent that is closing out the whole file in one pull request (#$n)." >/dev/null
done <"$work/mine.txt"

scripts/agent.sh sweeper "$n" --model "$model" --effort "$effort" </dev/null || true

# Release what the pull request does not close.
closes=$(gh pr list --head "sweeper/$n" --state all --json body --jq '.[0].body // ""' |
  grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)[: ]+#[0-9]+' | grep -oE '[0-9]+$' | sort -u || true)
kept=0; released=0
while read -r i; do
  if grep -qx "$i" <<<"$closes"; then kept=$((kept + 1)); continue; fi
  gh issue edit "$i" --remove-label claimed >/dev/null 2>&1 || true
  gh issue comment "$i" --body "The sweeper did not prove this one in its pass; what it tried and what blocked it is on #$n. Free to take." >/dev/null
  released=$((released + 1))
done <"$work/mine.txt"
echo "sweep #$n of $file: $kept proved in the pull request, $released released"
