#!/usr/bin/env python3
"""Start a pull request check from the build of main that the Main state workflow saved.

    scripts/ci/base_state.py --work DIR --base SHA --out DIR
    scripts/ci/base_state.py --choose --work DIR --main SHA --head SHA

The first form looks for a `main-state` artifact made for exactly `--base` or, failing that, the
newest one made for an ancestor of it, unpacks its build directory into DIR/.lake/build and, when
it is for exactly `--base`, writes its signatures to `--out`/signatures-SHA.txt. Building main
from scratch gives the same result; this only saves the time.

The second form says which commit of main a pull request is checked against (#6414), and prints
it: the newest commit that has a saved build, if main has changed, since then, neither a file the
pull request changes nor a file that matters to every check (auto_merge.matters_to_everyone);
otherwise `--main` itself, main's tip. Checking against the saved build costs only the pull
request's own part; checking against the tip first rebuilds everything merged since the saved
build, on every runner again. What main merged in between touches none of the pull request's
files, and the checker and the build options are the same at both commits, so the check differs
from one against the tip only by what those merges mean for the pull request's files: the same
risk as main moving between a check and its merge, which scripts/ci/auto_merge.py bounds. DIR is
a checkout with the history of main and the pull request's commit.

Both need GH_TOKEN (read access is enough), GH_REPO and REPO_ID, the numeric id of this
repository.

Only an artifact uploaded by a run on this repository's own `main` branch is used. A pull
request can upload an artifact with any name, but its run belongs to its own branch (and, from a
fork, to another repository), and GitHub records that, not the pull request. The Actions cache
is deliberately not used for this: a pull request can save a cache under any key, and later
runs of the same pull request would restore it in preference to main's.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

from auto_merge import matters_to_everyone

SHA = re.compile(r"[0-9a-f]{40}")
MAX_BYTES = 2 * 1024 ** 3


def saved_builds(repo, repo_id):
    """[(artifact, commit)] of the usable `main-state` artifacts, newest first."""
    listing = json.loads(subprocess.run(
        ["gh", "api", f"repos/{repo}/actions/artifacts?name=main-state&per_page=50"],
        check=True, capture_output=True).stdout)
    found = []
    for artifact in sorted(listing["artifacts"], key=lambda a: a["created_at"], reverse=True):
        run = artifact.get("workflow_run") or {}
        sha = str(run.get("head_sha"))
        if (artifact.get("expired") or run.get("repository_id") != repo_id
                or run.get("head_repository_id") != repo_id or run.get("head_branch") != "main"
                or not SHA.fullmatch(sha) or artifact.get("size_in_bytes", MAX_BYTES + 1) > MAX_BYTES):
            continue
        found.append((artifact, sha))
    return found


def git(work, *args):
    return subprocess.run(["git", "-c", "core.fsmonitor=false", *args], cwd=work, stdin=subprocess.DEVNULL,
                          capture_output=True, text=True)


def is_ancestor(work, older, newer):
    return git(work, "merge-base", "--is-ancestor", older, newer).returncode == 0


def choose(work, main, head, saved):
    """(the commit to check `head` against, why), given the commits with a saved build."""
    best = None
    for sha in saved:
        if is_ancestor(work, sha, main) and (best is None or (sha != best and is_ancestor(work, best, sha))):
            best = sha
    if best is None:
        return main, "no saved build of main to check against: checking against main's tip"
    if best == main:
        return main, "main's tip has a saved build"
    fork = git(work, "merge-base", main, head)
    listed = git(work, "diff", "--name-only", "-z", "--no-renames", fork.stdout.strip(), head)
    moved = git(work, "diff", "--name-only", "-z", "--no-renames", best, main)
    if fork.returncode or listed.returncode or moved.returncode:
        return main, "could not compare the saved build with main's tip: checking against main's tip"
    ours = set(filter(None, listed.stdout.split("\0")))
    for path in filter(None, moved.stdout.split("\0")):
        if path in ours:
            return main, f"main changed {path}, which the pull request changes, after its saved build " \
                         f"{best[:12]}: checking against main's tip"
        if matters_to_everyone(path):
            return main, f"main changed {path}, which affects every check, after its saved build " \
                         f"{best[:12]}: checking against main's tip"
    behind = git(work, "rev-list", "--count", f"{best}..{main}").stdout.strip()
    return best, f"checking against the saved build of main at {best[:12]}, {behind} commits behind main's tip"


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--work", required=True)
    parser.add_argument("--base")
    parser.add_argument("--out")
    parser.add_argument("--choose", action="store_true")
    parser.add_argument("--main")
    parser.add_argument("--head")
    args = parser.parse_args()
    repo, repo_id = os.environ["GH_REPO"], int(os.environ["REPO_ID"])
    work = Path(args.work)

    if args.choose:
        if not (args.main and args.head and SHA.fullmatch(args.main) and SHA.fullmatch(args.head)):
            raise SystemExit("--choose needs --main and --head, full commit ids")
        try:
            saved = [sha for _artifact, sha in saved_builds(repo, repo_id)]
        except (subprocess.CalledProcessError, ValueError, KeyError):
            saved = []
        base, why = choose(work, args.main, args.head, saved)
        print(why, file=sys.stderr)
        print(base)
        return 0

    if not (args.base and args.out):
        raise SystemExit("--base and --out are required")
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    chosen = None
    candidates = saved_builds(repo, repo_id)
    for artifact, sha in sorted(candidates, key=lambda c: c[1] != args.base):   # an exact match first
        if subprocess.run(["git", "merge-base", "--is-ancestor", sha, args.base], cwd=work).returncode == 0:
            chosen = (artifact, sha)
            break
    if not chosen:
        print("no saved state of main to start from; main will be built here")
        return 0
    artifact, sha = chosen
    archive = out / "main-state.zip"
    with open(archive, "wb") as target:
        subprocess.run(["gh", "api", f"repos/{repo}/actions/artifacts/{artifact['id']}/zip"],
                       check=True, stdout=target)
    with zipfile.ZipFile(archive) as bundle:
        for name in ("meta.json", "signatures.txt", "build.tar.zst"):
            with bundle.open(name) as source, open(out / name, "wb") as target:
                shutil.copyfileobj(source, target)
    archive.unlink()
    if json.loads((out / "meta.json").read_text()).get("sha") != sha:
        print("the saved state does not say which commit it is for; ignored")
        return 0
    build = work / ".lake/build"
    shutil.rmtree(build, ignore_errors=True)
    (work / ".lake").mkdir(exist_ok=True)
    subprocess.run(["tar", "-C", str(work / ".lake"), "--no-same-owner", "-I", "zstd", "-xf",
                    str(out / "build.tar.zst")], check=True)
    (out / "build.tar.zst").unlink()
    if sha == args.base:
        (out / "signatures.txt").rename(out / f"signatures-{sha}.txt")
        print(f"starting from the saved build and signatures of main at {sha[:12]}")
    else:
        print(f"starting from the saved build of main at {sha[:12]}, an ancestor of {args.base[:12]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
