---
name: configure-secrets
description: Add or change sops-nix secret consumers and their document access rules in this flake, including Home Manager consumers. Use for secret integration; new-host enrollment and installation belong to init-machine and install-machine.
---

# Configure secret consumers

Wire consumers to files provisioned by NixOS activation. Follow the repository's confidentiality and authorization rules; changing a consumer does not by itself authorize payload edits or key rewrites. Consult [upstream sops-nix documentation](https://raw.githubusercontent.com/Mic92/sops-nix/refs/heads/master/README.md) when introducing a capability not covered here.

## Declare and connect the secret

1. Put `sops.secrets.<name>` in the NixOS contribution of the consuming feature, even if the consumer runs through Home Manager. Keep [shared sops setup](../../../modules/secrets/default.nix) limited to integration and key discovery.
2. Set `sopsFile = config.constants.resources.getSecretPath "<document>"` and specify any non-default `format`. Use normal key extraction for YAML or JSON values; set `key = ""` only for consumers that need the entire document.
3. Set `owner`, `group`, and `mode` for the consumer with the minimum necessary access. For `hashedPasswordFile`, set `neededForUsers = true` so the secret exists before user creation.
4. Have NixOS consumers read `config.sops.secrets.<name>.path`. For Home Manager, define the runtime path in [the shared resources](../../../modules/constants/resources.nix) under `constants.resources.userSecretPaths`, assign that same path to the NixOS secret's `path`, and have the Home Manager consumer read it. Do not provision secrets through a Home Manager sops module or copy decryption keys into the user's home.
5. When generating configuration that embeds secrets, use `sops.templates` and placeholders, then consume the rendered template's `.path`. Never read secret contents during evaluation. Add `restartUnits` or `reloadUnits` when a running service must observe a secret change.

## Match documents to their readers

Identify which machines' NixOS activation reads each document, including secrets used by Home Manager. An imported sops module alone does not make a machine a reader.

Host recipients derive from SSH Ed25519 public keys and decrypt at activation through `sops.age.sshKeyPaths`. The maintainer recipient permits editing encrypted documents. Give each document its own disjoint creation rule in `.sops.yaml`, listing only its reader hosts and the maintainer when it must stay editable. Do not use catch-alls: sops uses only the first matching rule, and a host can decrypt the whole matched document. A document without a matching rule needs one before encryption.

For a new host, use [init-machine](../init-machine/SKILL.md) to collect and enroll its identity from the current installer boot.

When an authorized recipient change requires rewriting ciphertext, update the affected documents with `sops updatekeys`. Inspect the recipe before using the repository-wide `just updatekeys` convenience command. A document that omits the maintainer must first be re-keyed on a host that already decrypts it, using `just rewrap-secret <document> --add-age <recipient>` and, when retiring a recipient, `--rm-age <recipient>`. That recipe needs the checkout and privileged access to the host key. Stop if no authorized decrypting host is available; recreating a document from plaintext is a separate, explicitly authorized task.

## Verify the integration

Check the declaration, runtime path, permissions, service lifecycle, and reader set without printing secret values. After an authorized key rewrite, inspect only the expected ciphertext and recipient changes; stop if plaintext or unexpected file changes appear. Format changed Nix files and evaluate the affected configuration. Activation and remote verification still require authorization; report anything that remains unverified.
