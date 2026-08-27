{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
    inputs.systems.follows = "systems";
  };

  flake.modules.aspects.agents.imports = [ inputs.self.modules.aspects.pi-agent ];

  flake.modules.nixos.agents = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  };

  flake.modules.homeManager.agents =
    { pkgs, ... }:
    {
      programs.pi-agent = {
        enable = true;
        package = pkgs.llm-agents.pi;
        vendoredNpmPackages = {
          "npm:pi-mcp-adapter@2.29.0".hash = "sha256-OrdOu1g0OeyrcdjOSNTcj1Alv2xNTOAECZPwQBZOgL8=";
          "npm:pi-web-access@0.25.0".hash = "sha256-nvaGGOUKKKVyX2aSXqSI4CJOCCa8EKXHUkwo9PGSKEw=";
          "npm:pi-subagents@0.58.0".hash = "sha256-RWSRVZ8piZhwBJFstt2d7CLCdMBvMrY8d7a/UhcJLyw=";
          "npm:@narumitw/pi-usage@0.54.0".hash = "sha256-7wFMNCnVi6ynJyjcNxoqfTAK+j5xD/PPhSdCD5Fns8Q=";
        };
      };

      home.packages = with pkgs.llm-agents; [
        codex
        herdr
      ];
    };
}
