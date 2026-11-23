"""A pull request fails when it adds a plain `import` to a section file that has an import file
`X_Imports.lean`: the line belongs in the import file (#6263)."""
import unittest

from verdict import imports_bypassing_import_file, plain_imports

SEC = "RiemannMasullo/Ch05_ThetaZSpaces/Sec3b.lean"
IMP = "RiemannMasullo/Ch05_ThetaZSpaces/Sec3b_Imports.lean"
OLD = """module

public import RiemannMasullo.Ch05_ThetaZSpaces.Sec3a
import RiemannMasullo.Ch05_ThetaZSpaces.Sec3b_Imports
import all RiemannMasullo.AppD_SchwartzBruhat.Sec1b  -- a comment

/-! # Title -/

theorem t : True := trivial
"""


def check(new, old=OLD, files=(IMP,), path=SEC):
    return imports_bypassing_import_file([(path, old, new)], lambda p: p in files)


class ImportFileTest(unittest.TestCase):
    def test_header(self):
        self.assertEqual(plain_imports(OLD), {"RiemannMasullo.Ch05_ThetaZSpaces.Sec3b_Imports"})

    def test_proof_only_passes(self):
        self.assertEqual(check(OLD.replace("trivial", "by trivial")), [])

    def test_new_plain_import_fails(self):
        new = OLD.replace("import all", "import Mathlib.Analysis.Meromorphic.RCLike\nimport all")
        reasons = check(new)
        self.assertEqual(len(reasons), 1)
        self.assertIn("`import Mathlib.Analysis.Meromorphic.RCLike`", reasons[0])
        self.assertIn(IMP, reasons[0])

    def test_new_import_with_comment_fails(self):
        self.assertEqual(len(check(OLD.replace("\n\n/-!", "\nimport Mathlib.A  -- why\n\n/-!"))), 1)

    def test_no_import_file_passes(self):
        new = OLD.replace("import all", "import Mathlib.A\nimport all")
        self.assertEqual(check(new, files=()), [])

    def test_import_file_itself_passes(self):
        self.assertEqual(check("module\n\npublic import Mathlib.A\nimport Mathlib.B\n",
                               old="module\n", path=IMP, files=(IMP, IMP[:-5] + "_Imports.lean")), [])

    def test_public_import_and_import_all_pass(self):
        # statements need `public import`; `import all` is refused by its own check
        new = OLD.replace("import all", "public import Mathlib.A\nimport all Mathlib.B\nimport all")
        self.assertEqual(check(new), [])

    def test_moved_line_passes(self):
        new = OLD.replace("import RiemannMasullo.Ch05_ThetaZSpaces.Sec3b_Imports\n", "").replace(
            "-- a comment\n", "-- a comment\nimport RiemannMasullo.Ch05_ThetaZSpaces.Sec3b_Imports\n")
        self.assertEqual(check(new), [])

    def test_import_in_the_body_is_not_read(self):
        self.assertEqual(check(OLD + "\n-- import Mathlib.A\n/-- import Mathlib.B -/\n"), [])


if __name__ == "__main__":
    unittest.main()
