{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  # This aspect only composes and turns on the agent features; each one keeps its
  # own module.
  flake.modules.aspects.agents.imports = with inputs.self.modules.aspects; [
    codex-wrappers
    herdr
    skills
  ];

  # NixOS provisions the token so the unprivileged Home Manager consumer reads
  # it from a file instead of holding a decryption key of its own.
  flake.modules.nixos.agents =
    { config, ... }:
    {
      nix.settings = {
        extra-substituters = [ "https://cache.numtide.com" ];
        trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };

      sops.secrets.deepseek_api_key = {
        format = "yaml";
        key = "deepseek_api_key";
        sopsFile = config.constants.resources.getSecretPath "deepseek.yaml";
        path = config.constants.resources.userSecretPaths.deepseek_api_key;
        owner = config.constants.nvirellia.username;
        group = config.users.users.${config.constants.nvirellia.username}.group;
        mode = "0400";
      };

      sops.secrets.openrouter_management_key = {
        format = "yaml";
        key = "openrouter_management_key";
        sopsFile = config.constants.resources.getSecretPath "openrouter.yaml";
        path = config.constants.resources.userSecretPaths.openrouter_management_key;
        owner = config.constants.nvirellia.username;
        group = config.users.users.${config.constants.nvirellia.username}.group;
        mode = "0400";
      };

      sops.secrets.opencode_api_key = {
        format = "yaml";
        key = "opencode_api_key";
        sopsFile = config.constants.resources.getSecretPath "opencode.yaml";
        path = config.constants.resources.userSecretPaths.opencode_api_key;
        owner = config.constants.nvirellia.username;
        group = config.users.users.${config.constants.nvirellia.username}.group;
        mode = "0400";
      };
    };

  flake.modules.homeManager.agents =
    {
      lib,
      pkgs,
      ...
    }:
    let
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      # Upstream installs the v2 binary as `opencode2` so it can coexist with
      # v1 `opencode`. Expose it under the plain name as a real command, so
      # every consumer sees it: shells, scripts, and agent runners such as
      # paseo all resolve `opencode` through PATH.
      opencode = pkgs.writeShellScriptBin "opencode" ''
        exec ${lib.getExe llmAgents.opencode2} "$@"
      '';
    in
    {
      programs = {
        codex-wrappers = {
          csh.enable = true;
          ocsh.enable = true;
        };

        herdr = {
          enable = true;
          reviewr.enable = true;
          settings = {
            onboarding = false;
            session.resume_agents_on_restore = true;
            theme.name = "terminal";
            ui.toast.delivery = "system";
          };
        };
      };

      home.packages = [
        opencode
      ]
      ++ [ llmAgents."grok-bot" ]
      ++ (with llmAgents; [
        codex
        cursor-agent
        opencode2
        dsh
        pi
        paseo-desktop
      ])
      ++ (with pkgs; [
        bubblewrap
        jq
        python3
        selfPackages.zed-delta
      ]);
    };
}
