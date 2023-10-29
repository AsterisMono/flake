{ config, pkgs, nvimConfig, ... }:

{
  # Desktop Apps
  home.packages = with pkgs;[
    google-chrome
  # firefox
  # telegram-desktop
  # amono-nur.sqlitestudio
    lua-language-server
  ];

  # Command-line Apps
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  programs.fish = {
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

  programs.kitty = {
    enable = true;
    shellIntegration = {
      enableFishIntegration = true; 
      mode = "no-cursor";
    };
    theme = "Afterglow";
    settings = {
      cursor_shape = "block";
      cursor_blink_interval = 0;
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

  xdg.configFile.nvim.source = nvimConfig;
}
