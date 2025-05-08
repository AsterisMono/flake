{ pkgs, unstablePkgs, ... }:
let
  extraPackages = with pkgs; [
    nodejs_20
    any-nix-shell
    fastfetch
    devenv
    tldr
    nix-output-monitor # https://github.com/maralorn/nix-output-monitor
    corepack
    dust
    duf
    kubectl

    # Language servers
    nixd
    typescript # tsserver
    vscode-langservers-extracted
  ];
in
{
  home.packages = extraPackages;

  # Command-line Apps
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
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
      "tree" = "eza --tree";
      "gg" = "lazygit";
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
    package = unstablePkgs.neovim-unwrapped;
  };

  # xdg.configFile.nvim.source = flake.inputs.nvim-config;

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

  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      themes = {
        rose-pine-dawn = {
          bg = "#dfdad9";
          fg = "#575279";
          red = "#b4637a";
          green = "#286983";
          blue = "#56949f";
          yellow = "#ea9d34";
          magenta = "#907aa9";
          orange = "#fe640b";
          cyan = "#d7827e";
          black = "#f2e9e1";
          white = "#575279";
        };
      };
      theme = "rose-pine-dawn";
      plugins = {
        "autolock location=\"https://github.com/fresh2dev/zellij-autolock/releases/latest/download/zellij-autolock.wasm\"" =
          {
            is_enabled = true;
            triggers = "nvim|vim|zoxide|atuin";
          };
      };
      load_plugins = {
        autolock = { };
      };
    };
  };
}
