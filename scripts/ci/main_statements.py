#!/usr/bin/env python3
"""Fail Main state when a statement that main had at its previous saved build has changed.

    scripts/ci/main_statements.py [--accept] PREVIOUS NEW

PREVIOUS and NEW are signature dumps (scripts/signatures.sh --all): the one saved with the
previous build of main and the one just made. Every declaration of PREVIOUS must be in NEW with
the same statement, apart from names beginning `_private.`, as in the pull request check
(verdict.statement_changes); new declarations are fine. With PREVIOUS missing or empty nothing
can be compared, and that fails too, so that a long enough stop cannot pass unseen.

The pull request check compares a pull request with the commit of main it was checked against,
which may be older than main's tip (#6414); this catches, within one build of main, a statement
that changed through what was merged meanwhile. A run that fails here uploads no saved build, so
the next run compares with the same previous build and fails again, and Auto-merge merges
nothing while it is red. When statements were changed on purpose (an integrator's change, a
toolchain or Mathlib update), check the list in the run's summary and run Main state with
`accept_changed_statements` (prompts/integrator.md).

Exit status: 0 if nothing changed or `--accept`, 1 otherwise.
"""
import os
import sys
from pathlib import Path

import verdict


def main(argv):
    accept = "--accept" in argv
    paths = [a for a in argv if a != "--accept"]
    if len(paths) != 2:
        raise SystemExit(__doc__.split("\n\n")[1])
    previous, new = (Path(p) for p in paths)
    old_text = previous.read_text() if previous.is_file() else ""
    if not old_text.strip():
        lines = ["No signatures of a previous saved build of main to compare with."]
        failed = True
    else:
        changed, removed, _private, _added, _bad = verdict.statement_changes(old_text, new.read_text())
        lines = []
        if changed:
            lines.append("Changed since the previous saved build: " + ", ".join(changed))
        if removed:
            lines.append("Removed since the previous saved build: " + ", ".join(removed))
        failed = bool(lines)
    if failed and accept:
        lines.append("Accepted (accept_changed_statements).")
    elif failed:
        lines.append("If this was intended, run Main state with accept_changed_statements (prompts/integrator.md).")
    else:
        lines.append("No existing statement changed since the previous saved build.")
    for line in lines:
        print(line)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a") as out:
            out.write("".join(f"{line}\n\n" for line in lines))
    return 1 if failed and not accept else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
