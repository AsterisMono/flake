# Repository Guidelines

## Project Structure & Module Organization
- `nixosConfigurations/` per-host system definitions; matching hardware files live in `hardwares/`.
- `nixosModules/`, `darwinModules/`, `homeModules/` hold reusable modules; `overlays/` and `packages/` define custom packages and overlays.
- `templates/` provide starter flakes and dev shells; `scripts/` and the root `Justfile` expose helper commands.
- `assets/` contains wallpapers and other static files; `secrets/` stores SOPS-encrypted materials (keep them encrypted).

## Build, Test, and Development Commands
- `nix develop` enters the dev shell with `nixfmt-rfc-style`, `statix`, `just`, and deploy tooling preloaded.
- `just build` / `just deploy` / `just boot` / `just dryrun` run the corresponding `nixos-rebuild … --flake .` flows with verbose logs.
- `just darwin-bootstrap` runs `nix run nix-darwin -- switch --flake .` for macOS; `just darwin-deploy` uses `nh darwin switch .`.
- `nix flake check --print-build-logs` runs the flake’s checks (includes pre-commit hooks).
- `just install <host> <target>` or `just bootstrap <host> <disk>` guide remote installs via `nixos-anywhere`/`disko`.

## Coding Style & Naming Conventions
- Prefer Nix style formatted by `nixfmt-rfc-style`; run `nixfmt-rfc-style **/*.nix` before committing.
- Keep indentation at 2 spaces; align attribute sets and lists for readability.
- Use descriptive host/module filenames (`nixosConfigurations/ivy.nix`, `nixosModules/services/tailscale.nix`).
- Run `statix check` (also covered by the pre-commit hook) to catch common Nix anti-patterns.

## Testing Guidelines
- Primary check: `nix flake check --keep-going` to validate formatting, lint, and module evaluation.
- For NixOS builds, use `just build` for local closure validation; `just dryrun` to confirm activation plans without switching.
- Document any host-specific test steps in commit/PR notes (e.g., service restarts, hardware-sensitive changes).

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit style: `feat(scope): summary`, `fix(scope): …`, `chore(scope): …`; keep scope meaningful (`home/vscode`, `secrets/mihomo`, etc.).
- Keep messages in present tense and <72 characters in the subject.
- For PRs, include: purpose, affected hosts/modules, testing done (`nix flake check`, `just build`), and screenshots/logs for UI-facing or service changes.
- Link related issues or DeepWiki notes when available; call out any secrets changes or manual steps.

## Secrets & Security Notes
- Secrets in `secrets/` are encrypted with SOPS (age); ensure your key lives at `~/.config/sops/age/keys.txt`.
- Edit secrets with `sops secrets/<file>` and re-encrypt before commit; do not commit decrypted files.
- Use `just updatekeys` after adding/removing recipients; avoid embedding secrets directly in modules—reference `config.sops.secrets.*` paths instead.
