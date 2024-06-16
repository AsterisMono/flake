{ pkgs, nvimConfig, ... }:
let
  lspServers = with pkgs;[
    lua-language-server
    nil
    nodejs_20
  ];
in
{
  home.packages = lspServers;

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
      background_opacity = "0.7";
    };
    font = {
      name = "FiraCode Nerd Font Mono Ret";
    };
  };
  
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
    shellInit = "set -g fish_greeting";
    interactiveShellInit = ''
      set SHELL ${pkgs.fish}/fish
      set EDITOR nvim
      set PAGER bat

      zoxide init fish | source
      starship init fish | source
      atuin init fish --disable-up-arrow | source
    '';
    shellAliases = {
      ".." = "cd ../";
      "n" = "nvim";
      "ls" = "eza -l";
      "l" = "eza -l";
      "ll" = "eza -al";
      "cat" = "bat";
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
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.bat.enable = true;
}
