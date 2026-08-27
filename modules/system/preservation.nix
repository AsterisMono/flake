{ inputs, ... }:
{
  flake-file.inputs.preservation.url = "github:nix-community/preservation";

  flake.modules.nixos.preservation =
    { config, lib, ... }:
    let
      inherit (config.constants) nvirellia;
      preserveDirectory = directory: user: {
        inherit directory user;
        group = user;
      };
    in
    {
      imports = [ inputs.preservation.nixosModules.preservation ];

      preservation = {
        enable = true;
        preserveAt."/persistent" = {
          directories = [
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            "/var/lib/systemd/rfkill"
            "/var/lib/systemd/timers"
            "/var/log"
          ]
          ++ lib.optionals config.hardware.bluetooth.enable [ "/var/lib/bluetooth" ]
          ++ lib.optionals config.networking.networkmanager.enable [
            {
              directory = "/etc/NetworkManager/system-connections";
              mode = "0700";
            }
            "/var/lib/NetworkManager"
          ]
          ++ lib.optionals config.services.power-profiles-daemon.enable [
            "/var/lib/power-profiles-daemon"
          ]
          ++ lib.optionals config.services.flatpak.enable [ "/var/lib/flatpak" ]
          ++ lib.mapAttrsToList (
            name: _: preserveDirectory "/var/lib/netbird-${name}" "netbird-${name}"
          ) config.services.netbird.clients
          ++ lib.optionals config.services.sing-box.enable [
            (preserveDirectory "/var/lib/sing-box" "sing-box")
          ]
          ++ lib.optionals config.virtualisation.podman.enable [ "/var/lib/containers" ];

          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
            {
              file = "/var/lib/systemd/random-seed";
              how = "symlink";
              inInitrd = true;
              configureParent = true;
            }
          ]
          ++ lib.optionals config.services.openssh.enable [
            {
              file = "/etc/ssh/ssh_host_ed25519_key";
              how = "symlink";
              configureParent = true;
            }
            {
              file = "/etc/ssh/ssh_host_ed25519_key.pub";
              how = "symlink";
              configureParent = true;
            }
            {
              file = "/etc/ssh/ssh_host_rsa_key";
              how = "symlink";
              configureParent = true;
            }
          ];

          users = lib.optionalAttrs (builtins.hasAttr nvirellia.username config.users.users) {
            ${nvirellia.username} = {
              commonMountOptions = [
                "x-gvfs-hide"
                "x-gdu.hide"
              ];
              directories = [
                "Desktop"
                "Documents"
                "Downloads"
                "Music"
                "Pictures"
                "Projects"
                "Public"
                "Templates"
                "Videos"
                {
                  directory = ".ssh";
                  mode = "0700";
                }
                {
                  directory = ".config/1Password";
                  mode = "0700";
                }
                {
                  directory = ".config/gh";
                  mode = "0700";
                }
                {
                  directory = ".config/sops/age";
                  mode = "0700";
                }
                {
                  directory = ".local/share/keyrings";
                  mode = "0700";
                }
                {
                  directory = ".pi/agent";
                  mode = "0700";
                }
                {
                  directory = ".codex";
                  mode = "0700";
                }
                ".local/share/atuin"
                ".local/share/containers"
                ".local/share/direnv"
                ".local/share/fcitx5"
                ".local/share/fish"
                ".local/share/vicinae"
                ".local/share/zed"
                ".local/share/zoxide"
                ".local/state/nvim"
                ".local/state/wireplumber"
                ".mozilla"
                ".var/app"
                ".xpipe"
              ];
            };
          };
        };
      };

      # A persistent machine ID makes this commit service irrelevant.
      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    };
}
