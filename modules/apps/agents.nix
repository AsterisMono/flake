{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
    wrapper-manager.url = "github:viperML/wrapper-manager";
  };

  flake.modules.aspects.agents.imports = with inputs.self.modules.aspects; [
    herdr
  ];

  flake.modules.homeManager.agents =
    { pkgs, ... }:
    let
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      programs = {
        herdr = {
          enable = true;
          plugins.reviewr = pkgs.selfPackages.herdr-reviewr;
          settings = {
            onboarding = false;
            session.resume_agents_on_restore = true;
            keys.command = [
              {
                key = "alt+r";
                type = "plugin_action";
                command = "persiyanov.reviewr.toggle";
              }
            ];
            theme.name = "terminal";
            ui.toast.delivery = "system";
          };
        };
      };

      home.packages =
        with llmAgents;
        [
          codex
          cursor-agent
          opencode
        ]
        ++ (with pkgs; [
          bubblewrap
          jq
          python3
        ]);
    };
}
