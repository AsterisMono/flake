{
  lib,
  system,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  sshAuthSock =
    if (system == "aarch64-darwin") then
      "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "${config.home.homeDirectory}/.1password/agent.sock";
  extraPackages = with unstablePkgs; [
    any-nix-shell
    fastfetch
    nix-output-monitor # https://github.com/maralorn/nix-output-monitor
    dust
    duf
    cachix
    asciinema
    tailspin
  ];
in
{
  home.packages = extraPackages;

  # Command-line Apps
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Noa Virellia";
        email = "noa@requiem.garden";
        signingKey = ''
          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOz0CMmkGSXv4H77rmrmvadltAlwAZeVimxGoUAfArs Noa Virellia
        '';
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      commit.gpgsign = true;
      gpg.format = "ssh";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = lib.optionals (system == "aarch64-darwin") [ "~/.orbstack/ssh/config" ];
    matchBlocks = {
      knot = {
        host = "knot-rgarden";
        hostname = "knot.requiem.garden";
        user = "git";
        port = 2222;
      };
    };
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableTransience = true;
  };

  home.file."${config.xdg.configHome}/starship.toml".source =
    lib.mkForce ./externalConfigs/starship.toml;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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
      any-nix-shell fish --info-right | source

      if set -q FISH_FORK_PWD_HINT
        if test (string match -r '^/' $FISH_FORK_PWD_HINT)
          cd $FISH_FORK_PWD_HINT
        end
      end

      if test -x /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv | source
      end

      export SSH_AUTH_SOCK="${sshAuthSock}"
    '';
    shellAliases = {
      ".." = "cd ../";
      "n" = "nvim";
      "ne" = "neovide --fork";
      "ls" = "eza -l";
      "l" = "eza -l";
      "ll" = "eza -al";
      "tree" = "eza --tree";
      "gg" = "lazygit";
      "rec" = "asciinema rec";
      "co" = "codium .";
      "ze" = "zed .";
      "icat" = "kitten icat";
      "issh" = "kitten ssh";
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
      oc = {
        body = ''
          set base_name (basename (pwd))
              set path_hash (echo (pwd) | md5 | cut -c1-4)
              set session_name "$base_name-$path_hash"

              # Find available port starting from 4096
              function __oc_find_port
                  set port 4096
                  while test $port -lt 5096
                      if not lsof -i :$port >/dev/null 2>&1
                          echo $port
                          return 0
                      end
                      set port (math $port + 1)
                  end
                  echo 4096
              end

              set oc_port (__oc_find_port)
              set -x OPENCODE_PORT $oc_port

              if set -q TMUX
                  # Already inside tmux - just run with port
                  opencode --port $oc_port $argv
              else
                  # Create tmux session and run opencode
                  set oc_cmd "OPENCODE_PORT=$oc_port opencode --port $oc_port $argv; exec fish"
                  if tmux has-session -t "$session_name" 2>/dev/null
                      tmux new-window -t "$session_name" -c (pwd) "$oc_cmd"
                      tmux attach-session -t "$session_name"
                  else
                      tmux new-session -s "$session_name" -c (pwd) "$oc_cmd"
                  end
              end

              functions -e __oc_find_port
        '';
      };
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      git.commit.signOff = true;
    };
  };

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

  # Lumen
  sops.secrets.lumen_openrouter_api_key = { };
  sops.templates."lumen.config.json" = {
    content = ''
      {
        "api_key": "${config.sops.placeholder.lumen_openrouter_api_key}",
        "model": "x-ai/grok-code-fast-1",
        "provider": "openrouter"
      }
    '';
    path = "${config.home.homeDirectory}/.config/lumen/lumen.config.json";
  };

  # OpenCode
  sops.secrets.context7_api_key = { };
  sops.templates."opencode.json" = {
    content = ''
      {
        "$schema": "https://opencode.ai/config.json",
        "mcp": {
          "context7": {
            "type": "remote",
            "url": "https://mcp.context7.com/mcp",
            "headers": {
              "CONTEXT7_API_KEY": "${config.sops.placeholder.context7_api_key}"
            }
          }
        },
        "plugin": [
          "opencode-gemini-auth@latest",
          "oh-my-opencode@latest"
        ]
      }
    '';
  };
}
