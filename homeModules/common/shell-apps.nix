{ pkgs, flake, ... }:
let
  extraPackages = with pkgs;[
    lua-language-server
    nodejs_20
    any-nix-shell
    fastfetch
    devenv
    tldr
    nixd
    nix-output-monitor # https://github.com/maralorn/nix-output-monitor
    corepack
    dust
    duf
  ];
in
{
  home.packages = extraPackages;

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
        inherit (pkgs.fishPlugins.plugin-git) src;
      }
    ];
    shellInit = "set -g fish_greeting";
    interactiveShellInit = ''
      set EDITOR nvim
      set PAGER bat

      any-nix-shell fish --info-right | source

      if set -q FISH_FORK_PWD_HINT
        if test (string match -r '^/' $FISH_FORK_PWD_HINT)
          cd $FISH_FORK_PWD_HINT
        end
      end
    '';
    shellAliases = {
      ".." = "cd ../";
      "n" = "nvim";
      "ls" = "eza -l";
      "l" = "eza -l";
      "ll" = "eza -al";
      "cat" = "bat";
      "icat" = "kitten icat";
      "tree" = "eza --tree";
    };
    functions = {
      fish_title = {
        body = "echo $(pwd)";
      };
    };
  };

  programs.lazygit.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "https";
    };
  };

  # Replace command-not-found with nix-index and comma
  programs.nix-index-database.comma.enable = true;
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

  xdg.configFile.nvim.source = flake.inputs.nvim-config;

  # Modern unix series
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [
      "--disable-up-arrow"
    ];
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

  programs.btop = {
    enable = true;
    settings = {
      theme_background = false;
    };
  };

  programs.jq.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.ripgrep.enable = true;

  programs.fd = {
    enable = true;
    ignores = [
      ".git/"
      "node_modules/"
    ];
  };
}
