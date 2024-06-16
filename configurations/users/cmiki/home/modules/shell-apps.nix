{ pkgs, nvimConfig, ... }:
let
  lspServers = with pkgs;[
    lua-language-server
    nil
  ];
in
{
  home.packages = lspServers;
  
  # Command-line Apps
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
    shellInit = "set fish_greeting \"\"";
    shellAliases = {
      ".." = "cd ../";
      "c" = "clear";
      "n" = "nvim";
    };
  };

  programs.lazygit.enable = true;

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
    };
  };

  # Replace command-not-found with nix-index
  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  # Modern unix series
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
  }

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  }

  programs.bat.enable = true;

  xdg.configFile.nvim.source = nvimConfig;
}
