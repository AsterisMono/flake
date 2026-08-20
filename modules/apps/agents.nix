{ inputs, ... }:
{
  flake-file.inputs.llm-agents = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
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
