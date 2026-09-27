# Verification evidence

Proof artifacts for `verify-flake` land in a subdirectory named by the run id:

`.cursor/skills/verify-flake/evidence/<run-id>/<feature-id>/`

`<run-id>` is the `run:` value printed by `verify-flake doctor`. Cleanup deletes the scratch directory for that run and leaves this tree in place.

Everything except this README and `.gitignore` is ignored by git. Do not force-add screenshots, command transcripts, or store paths.
