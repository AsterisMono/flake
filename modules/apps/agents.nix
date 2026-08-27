{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
    inputs.systems.follows = "systems";
  };

  flake.modules.nixos.agents = {
    nixpkgs.overlays = [ inputs.llm-agents.overlays.shared-nixpkgs ];
  };

  flake.modules.homeManager.agents =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.llm-agents.codex ];
    };
}
