# Repository guidance

## Purpose and language

This repository is personal NixOS infrastructure. Optimize changes for safe operation of the managed machines, not for turning the repository into a reusable framework.

- A **host** is an actual physical or virtual machine.
- A **machine** is the repository composition assigned to a host and materialized as a NixOS configuration.
- A **NixOS configuration** is the operational output for a machine, exported through `flake.nixosConfigurations`.
- An **aspect** is reusable policy with an optional NixOS contribution, optional Home Manager contribution, or both.
- A **role** is an aspect that composes policy for a machine purpose. Every machine must import the `base` role; layer more specific roles on top.

Keep machine definition files focused on identity, hardware facts, disk selection, and composition of roles and aspects. Do not put host-specific details in reusable aspects.

## Dendritic architecture

This flake follows the [dendritic pattern](https://raw.githubusercontent.com/mightyiam/dendritic/refs/heads/master/README.md). Nearly every Nix file under `modules/` is a top-level flake-parts module for one cohesive feature. A feature may define lower-level NixOS, Home Manager, or generic modules as option values; its path names the feature rather than determining the expression type.

The summary here is sufficient for routine changes. Read the upstream dendritic documentation before changing the repository architecture, introducing a module pattern, changing how values cross module boundaries, or adding module-level `enable` options. Do not fetch it for ordinary value edits inside an established module.

- Export reusable lower-level modules through `flake.modules.nixos.<feature>`, `flake.modules.homeManager.<feature>`, or `flake.modules.generic.<feature>`.
- Compose native modules through `flake.modules.aspects.<feature>`. Native NixOS and Home Manager modules with the same name are included automatically; declare an aspect directly to add dependencies or other contributions.
- Define machines through `machines.<name>` as `aspects`-class submodules. Import aspects there, assign disk layouts through `diskoConfig`, and keep detected hardware facts in `hardware`; reserve `nixosModule` and `homeModule` for manual interventions. `flake.nixosConfigurations.<name>` is generated from the machine definition.
- Keep definitions for multiple configuration classes together when they implement the same feature. Do not split a feature solely because it affects both NixOS and Home Manager.
- Importing a project module should normally enable its feature. Do not add a project-level `enable` option unless the module genuinely must be imported while inactive.
- Let `import-tree` discover top-level modules. Do not introduce manual top-level import lists for files it already discovers.
- Never introduce `specialArgs` or `extraSpecialArgs`. Declare shared constants, functions, packages, and lower-level modules as top-level option values, then consume them through the module configuration or `inputs.self`.
- Declare a feature-owned flake input with `flake-file.inputs` beside that feature. Keep only shared foundational inputs in `modules/default.nix`.
- `flake.nix` is generated. Never edit it directly. Change the relevant `flake-file` declarations and run `nix run .#write-flake`.

## Repository map

- `modules/machines/`: machine definitions; hardware facts, disk selection, and aspect composition belong here.
- `modules/roles/`: reusable aspect bundles for machine purposes. `base` is mandatory for every machine.
- `modules/services/`: reusable service integrations and the secrets consumed by those services.
- `modules/system/`: operating-system policy such as boot, storage, locale, and Nix behavior.
- `modules/users/`: user accounts and their corresponding Home Manager entry points.
- `modules/apps/`: user-facing application configuration, generally exposed as Home Manager modules.
- `modules/constants/`: typed shared identity, resource, and other cross-feature values.
- `modules/secrets/`: shared sops-nix integration plus encrypted secret documents.

If this taxonomy stops fitting a new concern, propose a new folder and explain the boundary it would represent. Obtain approval before creating it.

## Secrets and sops-nix

This repository uses [sops-nix](https://raw.githubusercontent.com/Mic92/sops-nix/refs/heads/master/README.md) for activation-time secret provisioning. Encrypted secret documents may be committed and copied to the Nix store; decrypted values must exist only at runtime. Routine work should follow the local patterns below. Consult upstream documentation when introducing a sops-nix capability not covered here.

The age recipient model has two purposes:

- A maintainer recipient permits editing encrypted documents.
- A host recipient, derived from that host's SSH Ed25519 public key, permits NixOS activation to decrypt them through `sops.age.sshKeyPaths`.

Home Manager uses the maintainer's age key file. Its secrets are provisioned by the `sops-nix` user service beneath the user's runtime directory rather than the system `/run/secrets` hierarchy. A user service consuming them must order itself after `sops-nix.service`.

Follow these patterns:

- Treat `modules/secrets/`, `.sops.yaml`, password hashes, key material, and personal identity constants as sensitive. Do not decrypt, print, rotate, or edit secret payloads unless the task explicitly requires it.
- Never create a plaintext secret file. Edit encrypted documents with `sops`.
- Declare each `sops.secrets.<name>` beside the service or feature that consumes it. Keep `modules/secrets/default.nix` limited to shared sops-nix setup and key discovery.
- Set `sopsFile` and any non-default `format` explicitly. Use the shared secret-path helper rather than duplicating repository paths.
- Consume `config.sops.secrets.<name>.path`. Never read secret contents during Nix evaluation; sops-nix decrypts only during activation.
- Use normal key extraction for a value from YAML or JSON. Set `key = ""` only when the consumer requires the whole decrypted document.
- Use `sops.templates` and placeholders when a generated configuration must interpolate secrets; consume the rendered template's `.path`.
- Add `restartUnits` or `reloadUnits` when a running service must observe a changed secret.
- Set `owner`, `group`, and `mode` no more permissively than the consumer requires.
- For a password supplied through `hashedPasswordFile`, declare its secret with `neededForUsers = true` so it is available before user creation.
- When recipients change, update the affected encrypted documents with `sops updatekeys`; `just updatekeys` is the repository-wide convenience recipe. This rewrite requires explicit authorization.

## Compatibility and dependencies

- Do not bump `system.stateVersion` or `home.stateVersion` during a routine package or input update. Change either only for an explicitly requested, reviewed compatibility migration.
- Keep the NixOS and Home Manager release lines aligned. Do not move one independently to unstable or another release unless the task explicitly includes that migration.
- Keep dependency updates targeted. Do not run a blanket `nix flake update` unless explicitly requested. When an input changes, regenerate `flake.nix`, update only the relevant lock node where practical, and include the resulting `flake.lock` change.

## NixOS reference

Use the `nixos` MCP as the primary reference for NixOS and Home Manager options, packages, and related documentation. Consult upstream documentation when the MCP does not cover the required capability or when repository guidance explicitly requires it.

## Validation

Use the development shell (`nix develop`) for the repository's versions of `nixfmt`, `statix`, and related tools. Normally the shell should already be activated; if not (missing tools), ask the user to acticvate the nix shell first.

Whenever adding a new file, stage it with `git add` so Nix can see it in the flake source. If Nix reports that it cannot find a module or file and you have confirmed that the path exists, run `git add` for that module or file before retrying.

Before completing a change:

1. Format changed Nix files with `nixfmt`.
2. Run `nix flake check`.
3. If a NixOS configuration was added or changed, build only that configuration with `nix build .#nixosConfigurations.<name>.config.system.build.toplevel`.

Do not build every NixOS configuration locally for a shared-module change; exhaustive configuration builds belong to CI. Preserve the `nixos-configurations-import-base` check. Encode new objective repository-wide invariants as flake checks when practical, but leave subjective formatting and lint rules to `nixfmt` and `statix`.

## Operational safety

Bare `just` is informational and lists recipes. Even so, inspect a recipe before invoking it.

Do not run remote, privileged, machine-mutating, disk, deployment, garbage-collection, or key-rewrite recipes without explicit authorization. This includes `deploy`, `boot`, `dryrun`, `install`, `bootstrap`, `rdeploy`, `generate-hardware-config`, `gc`, `scan-age-key`, and `updatekeys`. Prefer the non-switching Nix build command in the validation section when only verification is required.

Preserve unrelated work in a dirty worktree. Do not create commits unless requested. When a commit is requested, use a Conventional Commit message such as `type(scope): description`, matching the configured `convco` hook.
