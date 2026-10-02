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
    herdr
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
        sopsFile = config.constants.resources.getSecretPath "agent-providers.yaml";
        path = config.constants.resources.userSecretPaths.deepseek_api_key;
        owner = config.constants.nvirellia.username;
        group = config.users.users.${config.constants.nvirellia.username}.group;
        mode = "0400";
      };

      sops.secrets.openrouter_management_key = {
        format = "yaml";
        key = "openrouter_management_key";
        sopsFile = config.constants.resources.getSecretPath "agent-providers.yaml";
        path = config.constants.resources.userSecretPaths.openrouter_management_key;
        owner = config.constants.nvirellia.username;
        group = config.users.users.${config.constants.nvirellia.username}.group;
        mode = "0400";
      };

      sops.secrets.opencode_api_key = {
        format = "yaml";
        key = "opencode_api_key";
        sopsFile = config.constants.resources.getSecretPath "agent-providers.yaml";
        path = config.constants.resources.userSecretPaths.opencode_api_key;
        owner = config.constants.nvirellia.username;
        group = config.users.users.${config.constants.nvirellia.username}.group;
        mode = "0400";
      };
    };

  flake.modules.homeManager.agents =
    {
      pkgs,
      ...
    }:
    let
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      # Keep the server exports in the runtime closure until llm-agents PR #10061 lands.
      paseoDesktop = llmAgents.paseo-desktop.overrideAttrs (oldAttrs: {
        installPhase =
          builtins.replaceStrings
            [ ''"packages/desktop/dist/preload.js",'' ]
            [
              ''
                "packages/desktop/dist/preload.js",
                "packages/server/dist/server/server/exports.js",''
            ]
            oldAttrs.installPhase;
      });
    in
    {
      programs = {
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

      home.packages =
        (with llmAgents; [
          llmAgents."grok-bot"
          codex
          opencode
          pi
          paseoDesktop
          omp
        ])
        ++ (with pkgs; [
          bubblewrap
          jq
          python3
          selfPackages.deepseek-harness-desktop
        ]);
    };
}
