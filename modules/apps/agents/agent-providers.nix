{
  config,
  inputs,
  lib,
  ...
}:
{
  options.agentProviders.packages = lib.mkOption {
    type = with lib.types; functionTo (listOf package);
    readOnly = true;
    internal = true;
    description = "TUI agent harnesses and runtime tools for a given package set.";
  };

  config = {
    flake.modules.aspects.agent-providers.imports = [ inputs.self.modules.aspects.agent-upstream ];

    agentProviders.packages =
      pkgs:
      let
        llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      in
      (with llmAgents; [
        codex
        cursor-agent
        opencode
        pi
      ])
      ++ (with pkgs; [
        bubblewrap
        jq
        python3
      ]);

    flake.modules.homeManager.agent-providers =
      { pkgs, ... }:
      {
        home.packages = config.agentProviders.packages pkgs;
      };

    # Workstation credentials belong to the agents composition. Other accounts,
    # including the Paseo service account, authenticate providers independently.
    flake.modules.nixos.agents =
      { config, ... }:
      {
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
  };
}
