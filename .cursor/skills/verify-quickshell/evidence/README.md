# Verification evidence

Proof artifacts for `verify-quickshell` land in a subdirectory named by the run id:

`.cursor/skills/verify-quickshell/evidence/<run-id>/<feature-id>/`

`<run-id>` is the `run:` value printed by `verify-quickshell doctor`. Cleanup stops only the headless Sway and Quickshell whose command lines contain this run's scratch paths, deletes that scratch directory, and leaves this tree in place.

Everything except this README and `.gitignore` is ignored by git. Do not force-add screenshots, command transcripts, or store paths.
