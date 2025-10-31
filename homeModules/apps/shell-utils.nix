{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  extraPackages = with unstablePkgs; [
    any-nix-shell
    fastfetch
    nix-output-monitor # https://github.com/maralorn/nix-output-monitor
    dust
    duf
    cachix
    asciinema
    bluetuith
  ];
in
{
  home.packages = extraPackages;

  # Command-line Apps
  programs.git = {
    enable = true;
    userName = "Noa Virellia";
    userEmail = "noa@requiem.garden";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingKey = ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOz0CMmkGSXv4H77rmrmvadltAlwAZeVimxGoUAfArs Noa Virellia
      '';
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
  };

  xdg.configFile."starship.toml".source = lib.mkForce ./externalConfigs/starship.toml;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  sops.secrets.gemini_api_key = { };
  sops.secrets.github_fish_ai_pat = { };

  programs.fish = {
    enable = true;
    plugins = map (x: { inherit (x) name src; }) (
      with pkgs.fishPlugins;
      [
        plugin-git
        fzf-fish
        puffer
      ]
    );
    shellInit = "set -g fish_greeting";
    interactiveShellInit = ''
      set EDITOR nvim

      any-nix-shell fish --info-right | source

      if set -q FISH_FORK_PWD_HINT
        if test (string match -r '^/' $FISH_FORK_PWD_HINT)
          cd $FISH_FORK_PWD_HINT
        end
      end

      export GEMINI_API_KEY=$(cat ${config.sops.secrets.gemini_api_key.path})
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
      "rec" = "asciinema rec";
      "code" = "codium .";
      "icat" = "kitten icat";
      "ssh" = "kitten ssh";
    };
    functions = {
      fish_title = {
        body = "echo $(pwd)";
      };
      pb = {
        body = ''
          if test (count $argv) -ne 1
              echo "Usage: pb <filename>"
              return 1
          end
          set file $argv[1]
          curl -F "file=@$file" https://0x0.st
        '';
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
    daemon.enable = true;
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

  programs.btop.enable = true;

  programs.jq.enable = true;

  programs.ripgrep.enable = true;

  programs.fd = {
    enable = true;
    ignores = [
      ".git/"
      "node_modules/"
    ];
  };

  programs.tealdeer.enable = true;

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
  };

  xdg.configFile."zellij/config.kdl".source = ./externalConfigs/zellij-config.kdl;
}
