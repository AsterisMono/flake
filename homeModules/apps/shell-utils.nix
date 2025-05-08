{
  config,
  pkgs,
  lib,
  system,
  ...
}:
let
  extraPackages = with pkgs; [
    any-nix-shell
    fastfetch
    tldr
    nix-output-monitor # https://github.com/maralorn/nix-output-monitor
    dust
    duf
    cachix
  ];
in
{
  home.packages = extraPackages;

  # Command-line Apps
  programs.git = {
    enable = true;
    userName = "Noa Virellia";
    userEmail = "cmiki@amono.me";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fish = {
    enable = true;
    plugins =
      with pkgs.fishPlugins;
      map (x: { inherit (x) name src; }) [
        plugin-git
        fzf-fish
      ];
    shellInit = "set -g fish_greeting";
    interactiveShellInit =
      ''
        set EDITOR nvim

        any-nix-shell fish --info-right | source

        if set -q FISH_FORK_PWD_HINT
          if test (string match -r '^/' $FISH_FORK_PWD_HINT)
            cd $FISH_FORK_PWD_HINT
          end
        end
      ''
      + lib.optionalString (system == "aarch64-darwin") ''
        export SSH_AUTH_SOCK=${config.home.homeDirectory}/.bitwarden-ssh-agent.sock
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
    settings = {
      auto_sync = true;
      update_check = false;
      style = "compact";
      prefers_reduced_motion = true;
      sync.records = true;
    };
  };

  sops.secrets.atuin_key = {
    path = "${config.home.homeDirectory}/.local/share/atuin/key";
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

  programs.ripgrep.enable = true;

  programs.fd = {
    enable = true;
    ignores = [
      ".git/"
      "node_modules/"
    ];
  };

  # Cachix
  sops.secrets.cachix_auth_token = { };
  sops.templates."cachix.dhall" = {
    content = ''
      { authToken =
          "${config.sops.placeholder.cachix_auth_token}"
      , hostname = "https://cachix.org"
      , binaryCaches = [] : List { name : Text, secretKey : Text }
      }
    '';
    path = "${config.home.homeDirectory}/.config/cachix/cachix.dhall";
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
