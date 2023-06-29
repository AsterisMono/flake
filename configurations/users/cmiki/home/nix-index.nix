{ ... }:

{
  # Replace command-not-found with nix-index
  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
}
