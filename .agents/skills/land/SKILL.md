---
name: land
description: >-
  Land the requested changes from this NixOS infrastructure repository through a
  GitHub pull request into main. Invoke only when the user has explicitly
  requested landing changes, including through the Land Changes action; do not
  invoke for review, preparation, verification, or skill installation.
metadata:
  delta-action: land
---

# Land changes

This workflow lands the requested changes. The request that invoked this skill
already authorizes the landing operation; do not ask for merge permission again.
Stop for genuine blockers, ambiguous scope, failed verification, or conflicts.

## 1. Establish the change set

Inspect the working tree and recent history before changing Git state:

```bash
git status --short --branch
git diff --stat
git diff
git diff --cached --stat
git diff --cached
git log -5 --oneline --decorate
```

Preserve unrelated work. If staged or unstaged changes do not belong to the
requested change, stop and ask which files belong in the landing. Do not reset,
stash, discard, or stage unrelated work. Confirm that the repository is the
expected checkout and that `origin` is the GitHub remote before publishing.

The repository's contribution guidance requires lowercase imperative commit
subjects in the form `<scope>: <description>` (`AGENTS.md:102`). Use the
smallest focused commit possible and do not create an empty commit.

## 2. Verify locally

Format every changed Nix file with the repository's development-shell formatter
as required by `AGENTS.md:86-94`:

```bash
nixfmt <changed-nix-files>
```

Then run the repository's available checks:

```bash
git diff --check
nix flake check --no-build
```

`nix flake check --no-build` is the repository's direct flake evaluation check;
`Justfile:4-8` defines build operations but no non-mutating test wrapper. Treat
warnings as warnings, but stop on a command failure. Reinspect the diff after
formatting and ensure formatting did not alter unrelated files.

## 3. Commit and publish a topic branch

Fetch the destination before branching:

```bash
git fetch origin main
```

If the current branch is `main`, create a unique topic branch without changing
or discarding the worktree changes:

```bash
git switch -c "delta/land-$(date +%Y%m%d-%H%M%S)"
```

If the current branch is already a topic branch containing the requested work,
keep it. Do not reuse a branch known to contain unrelated commits. Stage only
the reviewed requested files and commit with the repository's convention:

```bash
git add <requested-files>
GIT_EDITOR=true git commit -m '<scope>: <description>'
```

Inspect the commit and confirm no unrelated paths were included:

```bash
git show --stat --oneline HEAD
git status --short
```

Publish to the configured GitHub remote:

```bash
git push --set-upstream origin HEAD
```

A push is preparation, not a successful landing.

## 4. Open and merge the pull request

Create a pull request targeting `main` with a concise title matching the commit
and a body that describes the behavior change and local verification:

```bash
gh pr create --base main --head "$(git branch --show-current)" \
  --title '<scope>: <description>' \
  --body '<summary and verification results>'
```

Record the returned PR URL. Check the PR's required status checks and review
requirements before merging. This repository currently has no checked-in
`.github/workflows` directory, so there are no repository-defined GitHub
Actions checks to wait for; the local `nix flake check --no-build` remains
required. Do not treat missing, pending, or failing required checks as passed.

When all applicable requirements pass, squash-merge the PR without an
interactive prompt:

```bash
gh pr merge <pr-number-or-url> --squash --delete-branch=false
```

If GitHub reports merge conflicts, pause and ask the user how to resolve them.
Do not resolve conflicts automatically in this workflow. If review, branch
protection, authentication, or a required check blocks the merge, report the
blocker and do not claim success.

## 5. Verify the landing

After the merge command succeeds, refresh the destination and verify that the
PR is merged and its resulting commit is reachable from `origin/main`:

```bash
git fetch origin main
gh pr view <pr-number-or-url> --json state,mergedAt,mergeCommit,url
git merge-base --is-ancestor <merge-commit> origin/main
git status --short --branch
```

The landing is successful only when the PR reports `MERGED`, the merge commit
is an ancestor of `origin/main`, and unrelated local work remains intact. A
passing check, commit, push, or open PR alone is not success.

When this workflow runs in a subthread and `report_subthread_status` is
available, report the final outcome to the parent. Use `status: "success"` only
after the destination verification above, with the merged commit and verified
PR URL. Use `status: "failure"` for conflicts, failed checks, blocked
publication, or any other blocker, and state that the change was not landed.
Otherwise report the same outcome directly in the conversation.
