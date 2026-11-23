"""Checking a pull request against the newest saved build of main instead of main's tip (#6414):
which commit base_state.py chooses, and how verdict.py applies the pull request to it."""
import os
import subprocess
import json
import tempfile
import types
import unittest
from pathlib import Path

import base_state
import verdict

A = "RiemannMasullo/AppA/Sec1.lean"
B = "RiemannMasullo/AppB/Sec2.lean"
PROOF_BEFORE = "theorem t : True := by\n  sorry\n"
PROOF_AFTER = "theorem t : True := by\n  trivial\n"


class Repo(unittest.TestCase):
    """main: saved -> other -> tip; a pull request on A, branched from `saved` or from `tip`."""

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        self.env = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@invalid", GIT_COMMITTER_NAME="t",
                        GIT_COMMITTER_EMAIL="t@invalid", GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1")
        self.git("init", "-q", "-b", "main")
        self.saved = self.commit({A: PROOF_BEFORE, B: PROOF_BEFORE, "README.md": "x\n"})

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.dir, env=self.env, check=True,
                              capture_output=True, text=True).stdout.strip()

    def commit(self, files):
        for path, text in files.items():
            target = self.dir / path
            target.parent.mkdir(parents=True, exist_ok=True)
            if text is None:
                target.unlink()
            else:
                target.write_text(text)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "c")
        return self.git("rev-parse", "HEAD")

    def branch(self, start, files):
        """A commit on top of `start` that is not on main; main's checkout is left as it was."""
        here = self.git("rev-parse", "HEAD")
        self.git("checkout", "-q", "--detach", start)
        sha = self.commit(files)
        self.git("checkout", "-q", "--detach", here)
        return sha

    def merge_main_into(self, head, main):
        here = self.git("rev-parse", "HEAD")
        self.git("checkout", "-q", "--detach", head)
        self.git("merge", "-q", "--no-edit", main)
        sha = self.git("rev-parse", "HEAD")
        self.git("checkout", "-q", "--detach", here)
        return sha


class Choose(Repo):
    def choose(self, main, head, saved):
        return base_state.choose(self.dir, main, head, saved)[0]

    def test_saved_build_when_main_changed_other_library_files(self):
        tip = self.commit({B: PROOF_AFTER, "README.md": "y\n"})
        head = self.branch(self.saved, {A: PROOF_AFTER})
        self.assertEqual(self.choose(tip, head, [self.saved]), self.saved)

    def test_saved_build_when_the_pull_request_merged_main_since(self):
        tip = self.commit({B: PROOF_AFTER})
        head = self.merge_main_into(self.branch(self.saved, {A: PROOF_AFTER}), tip)
        self.assertEqual(self.choose(tip, head, [self.saved]), self.saved)

    def test_tip_when_main_changed_a_file_of_the_pull_request(self):
        tip = self.commit({A: PROOF_BEFORE + "\n"})
        head = self.branch(tip, {A: PROOF_AFTER + "\n"})
        self.assertEqual(self.choose(tip, head, [self.saved]), tip)

    def test_tip_when_main_changed_what_every_check_uses(self):
        for path in ("lakefile.toml", "scripts/ci/verdict.py", "scripts/ci/command_keywords.txt",
                     "RiemannMasullo/External/X.lean", "Main.lean"):
            tip = self.commit({path: "changed " + path})
            head = self.branch(self.saved, {A: PROOF_AFTER})
            self.assertEqual(self.choose(tip, head, [self.saved]), tip, path)
            self.saved = tip

    def test_newest_commit_with_a_build_whatever_the_upload_order(self):
        middle = self.commit({B: PROOF_AFTER})
        tip = self.commit({"README.md": "y\n"})
        head = self.branch(self.saved, {A: PROOF_AFTER})
        # a build from scratch of `saved` uploaded after the incremental one of `middle`
        self.assertEqual(self.choose(tip, head, [self.saved, middle]), middle)
        self.assertEqual(self.choose(tip, head, [middle, self.saved]), middle)

    def test_tip_without_a_usable_build(self):
        tip = self.commit({B: PROOF_AFTER})
        other = self.branch(self.saved, {"README.md": "elsewhere\n"})     # not a commit of main
        head = self.branch(self.saved, {A: PROOF_AFTER})
        self.assertEqual(self.choose(tip, head, []), tip)
        self.assertEqual(self.choose(tip, head, [other]), tip)
        self.assertEqual(self.choose(tip, head, [tip]), tip)


class ApplyToSavedBase(Repo):
    """verdict.Check with `--base` the saved build and `--main` the tip."""

    def check(self, base, head, main):
        self.git("checkout", "-q", "--detach", base)
        return verdict.Check(self.dir, base, head, main)

    def candidate(self, check):
        return check.git("merge-tree", "--write-tree", "--no-messages", "--merge-base", check.merge_base,
                         check.base, check.head).stdout.strip()

    def test_only_the_pull_requests_own_change_is_applied(self):
        tip = self.commit({B: PROOF_AFTER, "README.md": "y\n"})
        head = self.merge_main_into(self.branch(self.saved, {A: PROOF_AFTER}), tip)
        check = self.check(self.saved, head, tip)
        self.assertEqual([e["path"] for e in check.changed_files()], [A])
        check.merge(self.candidate(check))
        self.assertEqual((self.dir / A).read_text(), PROOF_AFTER)
        self.assertEqual((self.dir / B).read_text(), PROOF_BEFORE)       # the saved base's, not the tip's
        self.assertEqual((self.dir / "README.md").read_text(), "x\n")

    def test_same_as_before_when_base_is_the_tip(self):
        tip = self.commit({B: PROOF_AFTER})
        head = self.branch(self.saved, {A: PROOF_AFTER})
        check = self.check(tip, head, None)
        self.assertEqual([e["path"] for e in check.changed_files()], [A])
        self.assertEqual(check.merge_base, self.saved)
        check.merge(self.candidate(check))
        self.assertEqual((self.dir / A).read_text(), PROOF_AFTER)
        self.assertEqual((self.dir / B).read_text(), PROOF_AFTER)

    def test_refused_when_main_changed_the_file_after_the_base(self):
        tip = self.commit({A: PROOF_BEFORE + "\n"})
        head = self.merge_main_into(self.branch(self.saved, {B: PROOF_AFTER}), tip)
        head = self.branch(head, {A: PROOF_AFTER + "\n"})
        with self.assertRaises(verdict.Stop) as stopped:
            self.check(self.saved, head, tip).changed_files()
        self.assertEqual(stopped.exception.verdict, "error")

    def test_refused_when_the_base_is_not_main(self):
        tip = self.commit({B: PROOF_AFTER})
        other = self.branch(self.saved, {"README.md": "elsewhere\n"})
        head = self.branch(self.saved, {A: PROOF_AFTER})
        with self.assertRaises(verdict.Stop) as stopped:
            self.check(other, head, tip).changed_files()
        self.assertEqual(stopped.exception.verdict, "error")

    def test_proof_review_sees_only_the_pull_requests_change(self):
        tip = self.commit({B: PROOF_AFTER, "RiemannMasullo/AppB/New.lean": "def x := 1\n"})
        head = self.merge_main_into(self.branch(self.saved, {A: PROOF_AFTER}), tip)
        check = self.check(self.saved, head, tip)
        held = check.held_back(check.changed_files())
        self.assertEqual([r for r in held if "proof_review" in r], [])


class Report(unittest.TestCase):
    def test_summary_names_the_saved_base_and_main(self):
        with tempfile.TemporaryDirectory() as out:
            args = types.SimpleNamespace(out=out, pr=1, head="a" * 40, base="b" * 40, main="c" * 40, behind="23")
            verdict.report(args, "merge", [], "")
            data = json.loads((Path(out) / "verdict.json").read_text())
            self.assertEqual((data["schema"], data["base_sha"], data["main_sha"]), (1, "b" * 40, "c" * 40))
            summary = (Path(out) / "summary.md").read_text()
            self.assertIn("`bbbbbbbbbbbb`", summary)
            self.assertIn("`cccccccccccc`, 23 commits further", summary)


if __name__ == "__main__":
    unittest.main()
