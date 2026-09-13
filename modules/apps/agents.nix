{
  inputs,
  ...
}:
let
  piSettings = {
    defaultProvider = "deepseek";
    defaultModel = "deepseek-v4-flash";
  };

  piVendoredNpmPackages = {
    "npm:@ff-labs/pi-fff@0.10.6".hash = "sha256-tuXOO4CbFMXF5ww/NNXvesjPWc6geXJJegQ0YRKlGIU=";
    "npm:@juicesharp/rpiv-todo@2.10.1".hash = "sha256-HJkGPtV9l2tcyFC3ypOpsg+zK30xORBwK/ZAwyQEiXU=";
    "npm:@narumitw/pi-goal@0.54.4".hash = "sha256-u2OIvisWyr70CIDh7Be51eg5PdFN99Pb8vbbDGcAwqQ=";
    "npm:pi-ask-user@0.15.0".hash = "sha256-/U+aH1DCYQAccUUgm24B5vPpxDNQu62zOFPG8av7ykc=";
    "npm:pi-mcp-adapter@2.32.1".hash = "sha256-0TOiEcPV6Ytvhairm8XEB3QvVRuT0Xo/2/dtOeDSHGQ=";
    "npm:pi-web-access@0.29.0".hash = "sha256-0+1o91vuRym/g8jXPfLELWvmsEQE/rbrCV4dxlZ8LAg=";
  };

  herdrSkill = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr/7b675f42af35508eab66ac42fe1598628597a893/skills/herdr/SKILL.md";
    sha256 = "sha256-I3rSqy2BI+K7N5VtOkHu0UHy0ip8NuQVt4dsA5dnkJk=";
  };
in
{
  flake-file.inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  flake.modules.aspects.agents.imports = with inputs.self.modules.aspects; [
    herdr
    pi-agent
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

        pi-agent = {
          enable = true;
          package = llmAgents.pi;
          settings = piSettings;
          skills.herdr = herdrSkill;
          vendoredNpmPackages = piVendoredNpmPackages;
        };
      };

      home.packages =
        with llmAgents;
        [
          codex
          cursor-agent
          opencode
          dsh
        ]
        ++ (with pkgs; [
          bubblewrap
          jq
          python3
        ]);
    };
}
