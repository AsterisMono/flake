# Noa's NixOS Flake

A modular and reproducible personal setup for both NixOS and Darwin systems.

## Useful outputs

```nix
# A utility function for bundling multiple module files into a single module
lib.bundleModules
```

## Usage

Interactive exploration:

```bash
just explore
```

To bootstrap a fresh darwin system, run:

```bash
just darwin-bootstrap
```