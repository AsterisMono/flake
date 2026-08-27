{
  flake.modules.nixos.installer =
    { modulesPath, pkgs, ... }:
    {
      imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
      ];

      environment.systemPackages = with pkgs; [
        _1password-cli
        age
        bat
        duf
        dust
        eza
        fish
        fzf
        git
        jq
        just
        lazygit
        nh
        nix-output-monitor
        nixd
        nixfmt
        nixos-anywhere
        nixos-rebuild-ng
        ripgrep
        sops
        ssh-to-age
        starship
      ];

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          starship init fish | source
        '';
        shellInit = ''
          function fish_greeting
            echo "NixOS installer"
            echo ""
            echo "  1. Connect to the network: nmtui"
            echo "  2. Enter this flake's checkout"
            echo "  3. Authenticate to the NixOS vault: op-login"
            echo "  4. Review available workflows: just"
            echo ""
            echo "Common recipes:"
            echo "  just generate-luks-password <machine>"
            echo "  just bootstrap <machine> <disk>"
            echo "  just install <machine> <target>"
            echo ""
          end

          function op-login --description "Authenticate with the NixOS vault service account"
            set -l token
            read --silent --prompt-str "1Password service account token: " token
            echo

            if test -z "$token"
              echo "No token provided."
              return 1
            end

            set -gx OP_SERVICE_ACCOUNT_TOKEN "$token"
            set -e token

            if op user get --me >/dev/null
              echo "Authenticated to 1Password; use the NixOS vault."
            else
              set -e OP_SERVICE_ACCOUNT_TOKEN
              echo "Authentication failed; the token was cleared."
              return 1
            end
          end
        '';
        shellAliases = {
          l = "eza -l";
          ll = "eza -al";
          ls = "eza -l";
          tree = "eza --tree";
        };
      };

      users.users.nixos.shell = pkgs.fish;
    };
}
