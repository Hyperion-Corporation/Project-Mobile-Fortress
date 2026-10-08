"""Exercise the smoke gate in a temporary repo with a controllable Godot stub."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


RUNNER = Path(__file__).resolve().parents[1] / "run_godot_smokes.sh"


class SmokeRunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        (self.root / "game/tests").mkdir(parents=True)
        self.runner = self.root / "scripts/run_godot_smokes.sh"
        shutil.copy2(RUNNER, self.runner)
        for name in ("alpha", "beta"):
            (self.root / f"game/tests/{name}_smoke.gd").touch()
        self.godot = self.root / "fake-godot"
        self.godot.write_text('''#!/usr/bin/env bash
case " $* " in
  *" --version "*) echo fake; exit 0 ;;
  *" --import "*)
    if [[ -f "$0.imported" && -n ${IMPORT_RETRY_RC:-} ]]; then
      exit "$IMPORT_RETRY_RC"
    fi
    touch "$0.imported"
    printf '%s\\n' "${IMPORT_TEXT:-}"; exit "${IMPORT_RC:-0}" ;;
esac
if [[ ${HANG:-0} == 1 ]]; then
  trap '' TERM
  while :; do sleep 1; done
fi
printf '%b\\n' "${SMOKE_TEXT:-PASS}"
exit "${SMOKE_RC:-0}"
''')
        self.godot.chmod(0o755)

    def run_gate(self, *args, **overrides):
        env = dict(os.environ, GODOT=str(self.godot),
                   SMOKE_LOG=str(self.root / "smokes.log"), SMOKE_TIMEOUT="10")
        env.update(overrides)
        return subprocess.run([str(self.runner), *args], env=env, cwd="/tmp",
                              text=True, capture_output=True, timeout=20)

    def test_discovers_new_smoke(self):
        (self.root / "game/tests/new_smoke.gd").touch()
        result = self.run_gate()
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("3 passed, 0 failed", result.stdout)
        self.assertIn("new_smoke", result.stdout)

    def test_subset_aliases(self):
        for name in ("alpha", "alpha_smoke", "alpha_smoke.gd"):
            with self.subTest(name=name):
                result = self.run_gate(name)
                self.assertEqual(result.returncode, 0, result.stdout)
                self.assertIn("1 selected (2 discovered)", result.stdout)

    def test_unknown_name(self):
        self.assertEqual(self.run_gate("unknown").returncode, 2)

    def test_nonzero_smoke(self):
        result = self.run_gate(SMOKE_RC="7")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("0 passed, 2 failed", result.stdout)

    def test_failure_text_at_zero_exit(self):
        for text in ("SCRIPT ERROR: broken", "Parse Error: broken", "Smoke: FAIL (1)",
                     r"\033[31mFAIL\033[0m"):
            with self.subTest(text=text):
                result = self.run_gate(SMOKE_TEXT=text)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("exit=0 but matched:", result.stdout)

    def test_fail_word_boundary(self):
        result = self.run_gate(SMOKE_TEXT="FAILURE_COUNT=0")
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_import_failure_cannot_be_masked_by_passing_smokes(self):
        for rc in ("1", "124", "134"):
            with self.subTest(rc=rc):
                result = self.run_gate(IMPORT_RC=rc)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("2 passed, 0 failed", result.stdout)
                self.assertIn("Import failed", result.stdout)

    def test_import_error_text_at_zero_exit(self):
        result = self.run_gate(IMPORT_TEXT="SCRIPT ERROR: broken")
        self.assertEqual(result.returncode, 1, result.stdout)

    def test_abort_retry_must_succeed(self):
        result = self.run_gate(IMPORT_RC="134", IMPORT_RETRY_RC="0")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("retrying once", result.stdout)

    def test_abort_retry_preserves_first_attempt_errors(self):
        result = self.run_gate(IMPORT_RC="134", IMPORT_RETRY_RC="0",
                               IMPORT_TEXT="SCRIPT ERROR: broken")
        self.assertEqual(result.returncode, 1, result.stdout)

    def test_timeout_kills_smoke_ignoring_term(self):
        result = self.run_gate("alpha", HANG="1", SMOKE_TIMEOUT="0.1")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("timeout after 0.1s", result.stdout)

    def test_log_retains_failure_output(self):
        result = self.run_gate("alpha", SMOKE_TEXT="FAIL distinctive diagnostic")
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("FAIL distinctive diagnostic", (self.root / "smokes.log").read_text())


if __name__ == "__main__":
    unittest.main()
