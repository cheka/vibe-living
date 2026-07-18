# Local Harness

The Harness executes the real lifecycle Hook against synthetic session metadata in an isolated temporary directory. It explicitly disables daemon and UI startup, so it is safe for local checks and CI.

The behavioral contract lives in [`docs/specs/harness.md`](../docs/specs/harness.md).

```bash
make harness
python3 harness/run.py --verbose
python3 harness/run.py --keep --verbose
```

Use `--keep` only while debugging; the printed temporary directory can be inspected after the run and removed manually when finished.
