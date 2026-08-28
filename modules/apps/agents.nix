{
  inputs,
  lib,
  config,
  ...
}:
let
  herdrSettings = {
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

  piSettings = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-sol";
  };

  piVendoredNpmPackages = {
    "npm:@ff-labs/pi-fff@0.10.5".hash = "sha256-KfilZVZohnisnbQ8XO7+50TQzSaIrw6DpLxA5XRIi+w=";
    "npm:@narumitw/pi-goal@0.54.3".hash = "sha256-1P7I+bvcWgynbZ+kkam9sIRgWMGTdFO4K/o/hqbzWaM=";
    "npm:pi-mcp-adapter@2.29.0".hash = "sha256-OrdOu1g0OeyrcdjOSNTcj1Alv2xNTOAECZPwQBZOgL8=";
    "npm:pi-web-access@0.25.0".hash = "sha256-nvaGGOUKKKVyX2aSXqSI4CJOCCa8EKXHUkwo9PGSKEw=";
    "npm:pi-subagents@0.58.0".hash = "sha256-RWSRVZ8piZhwBJFstt2d7CLCdMBvMrY8d7a/UhcJLyw=";
    "npm:@narumitw/pi-usage@0.54.0".hash = "sha256-7wFMNCnVi6ynJyjcNxoqfTAK+j5xD/PPhSdCD5Fns8Q=";
  };

  inherit (config.npmHelpers) mkVendoredSettings;

  herdrSkill = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/herdrdev/herdr/7b675f42af35508eab66ac42fe1598628597a893/skills/herdr/SKILL.md";
    sha256 = "sha256-I3rSqy2BI+K7N5VtOkHu0UHy0ip8NuQVt4dsA5dnkJk=";
  };
in
{
  flake-file.inputs = {
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.systems.follows = "systems";
    };
    wrapper-manager.url = "github:viperML/wrapper-manager";
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
          settings = herdrSettings;
        };

        pi-agent = {
          enable = true;
          package = pkgs.llm-agents.pi;
          settings = piSettings;
          skills.herdr = herdrSkill;
          vendoredNpmPackages = piVendoredNpmPackages;
        };
      };

      home.packages = with pkgs.llm-agents; [
        codex
      ];
    };

  perSystem =
    {
      inputs',
      system,
      config,
      ...
    }:
    let
      pkgs = inputs'.nixpkgs.legacyPackages.extend inputs.llm-agents.overlays.shared-nixpkgs;
      jsonFormat = pkgs.formats.json { };
      tomlFormat = pkgs.formats.toml { };
      herdrPkg = pkgs.llm-agents.herdr;
      piPkg = pkgs.llm-agents.pi;
      inherit (mkVendoredSettings pkgs piSettings piVendoredNpmPackages) effectiveSettings;
      piSettingsFile = jsonFormat.generate "pi-settings.json" effectiveSettings;
      herdrConfigFile = tomlFormat.generate "herdr-config.toml" herdrSettings;
      piSetup = pkgs.writeText "pi-agent-setup" ''
        dir="''${XDG_STATE_HOME:-''${HOME}/.local/state}/iris-pi"
        mkdir -p "$dir/skills/herdr"
        cp -f ${piSettingsFile} "$dir/settings.json"
        cp -f ${herdrSkill} "$dir/skills/herdr/SKILL.md"
        export PI_CODING_AGENT_DIR="$dir"
      '';
      herdrPluginSetup = pkgs.writeShellScript "herdr-link-plugins" ''
        ${lib.getExe herdrPkg} plugin link ${lib.escapeShellArg "${config.packages.herdr-reviewr}"} --enabled >/dev/null 2>&1 || true
      '';
      wrappers =
        (inputs.wrapper-manager.lib {
          inherit pkgs;
          modules = [
            (
              { config, ... }:
              {
                wrapperType = "shell";

                wrappers.pi = {
                  basePackage = piPkg;
                  wrapFlags = [
                    "--run"
                    "source ${piSetup}"
                  ];
                };

                wrappers.herdr = {
                  basePackage = herdrPkg;
                  pathAdd = [ config.wrappers.pi.wrapped ];
                  env.HERDR_CONFIG_PATH = {
                    value = herdrConfigFile;
                    force = true;
                  };
                  wrapFlags = [
                    "--run"
                    "${herdrPluginSetup}"
                  ];
                };
              }
            )
          ];
        }).config.build.packages;
    in
    {
      packages = {
        inherit (wrappers) herdr pi;
      };
    };
}
