{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
    inputs.systems.follows = "systems";
  };

  flake.modules.aspects.agents.imports = with inputs.self.modules.aspects; [
    herdr
    pi-agent
  ];

  flake.modules.nixos.agents = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  };

  flake.modules.homeManager.agents =
    { pkgs, ... }:
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
            theme.name = "gruvbox";
            ui.toast.delivery = "system";
          };
        };

        pi-agent = {
          enable = true;
          package = pkgs.llm-agents.pi;
          settings = {
            defaultProvider = "openai-codex";
            defaultModel = "gpt-5.6-sol";
          };
          vendoredNpmPackages = {
            "npm:@ff-labs/pi-fff@0.10.5".hash = "sha256-KfilZVZohnisnbQ8XO7+50TQzSaIrw6DpLxA5XRIi+w=";
            "npm:@narumitw/pi-goal@0.54.3".hash = "sha256-1P7I+bvcWgynbZ+kkam9sIRgWMGTdFO4K/o/hqbzWaM=";
            "npm:pi-mcp-adapter@2.29.0".hash = "sha256-OrdOu1g0OeyrcdjOSNTcj1Alv2xNTOAECZPwQBZOgL8=";
            "npm:pi-web-access@0.25.0".hash = "sha256-nvaGGOUKKKVyX2aSXqSI4CJOCCa8EKXHUkwo9PGSKEw=";
            "npm:pi-subagents@0.58.0".hash = "sha256-RWSRVZ8piZhwBJFstt2d7CLCdMBvMrY8d7a/UhcJLyw=";
            "npm:@narumitw/pi-usage@0.54.0".hash = "sha256-7wFMNCnVi6ynJyjcNxoqfTAK+j5xD/PPhSdCD5Fns8Q=";
          };
        };
      };

      home.packages = with pkgs.llm-agents; [
        codex
      ];
    };
}
