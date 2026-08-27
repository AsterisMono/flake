---
name: auto-follow
description: Maintain explicit follows for Nix flake inputs in this repository and deduplicate nixpkgs, flake-parts, and nix-systems nodes in flake.lock. Use when adding, updating, or auditing flake inputs or their lock graph.
---

# Auto-follow flake inputs

Keep shared foundational inputs explicit and make dependent inputs follow them.

## Required policy

- Every input that exposes a `nixpkgs` input must set `inputs.nixpkgs.follows = "nixpkgs"`, unless the user specifically requests a different source or no follow for that input.
- Every input that exposes a `flake-parts` input must set `inputs.flake-parts.follows = "flake-parts"`.
- Every input that exposes the `nix-systems/default` input, normally named `systems`, must set `inputs.systems.follows = "systems"`.
- Declare the corresponding shared root input before following it. In this repository, keep shared foundational declarations in `modules/default.nix`.
- Do not add overrides for inputs an upstream flake does not expose. Use `flake.lock` to identify actual dependency edges and names.

The nixpkgs exception is task-specific: do not preserve an old exception after the user asks to return that input to the default policy. The `flake-parts` and `systems` follows have no policy exception; if an upstream input exposes either dependency, follow the shared root.

## Workflow

1. Scan every `flake-file.inputs` declaration and inspect `flake.lock` as a dependency graph. Identify parents with `nixpkgs`, `flake-parts`, or `systems` edges, including suffixed duplicate nodes such as `flake-parts_2` or `systems_2`.
2. Add follows beside the feature-owned `flake-file.inputs.<name>` declaration. Preserve intentionally different nixpkgs policy only when explicitly requested. Do not edit generated `flake.nix` directly.
3. Format changed Nix files with `nixfmt`, then run `nix run .#write-flake` to regenerate `flake.nix`.
4. Update `flake.lock` without blanket dependency upgrades. Confirm that existing locked revisions remain unchanged and redundant nodes are removed.
5. Verify the lock graph has one shared node for each followed dependency, except for a nixpkgs input the user explicitly asked to keep independent. Run `git diff --check` and the repository's proportionate Nix checks.

Preserve unrelated work and follow the repository's operational-safety and validation rules throughout.
