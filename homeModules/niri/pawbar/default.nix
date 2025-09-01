{ lib, pkgs, ... }:
{
  imports = [ ./options.nix ];

  services.pawbar = {
    enable = true;
    package = pkgs.flakePackages.pawbar;
    settings = {
      left = [
        "space"
        {
          custom = {
            format = "Noa Virellia 🏳️‍⚧️ with NixOS Build ${lib.version}";
          };
        }
      ];
      right = [
        {
          cpu = {
            onmouse = {
              left = {
                run = [
                  "kitty"
                  "--class"
                  "sysmon"
                  "btop"
                ];
              };
              hover = {
                config = {
                  cursor = "pointer";
                };
              };
            };
          };
        }
        "space"
        "space"
        "ram"
        "space"
        "space"
        {
          battery = {
            onmouse = {
              hover = {
                config = {
                  # Disable on hover
                  format = "{{.Icon}} {{.Percent}}%";
                };
              };
            };
          };
        }
        "sep"
        {
          volume = {
            onmouse = {
              left = {
                run = [
                  "wpctl"
                  "set-mute"
                  "@DEFAULT_AUDIO_SINK@"
                  "toggle"
                ];
              };
              hover = {
                config = {
                  cursor = "pointer";
                };
              };
            };
          };
        }
        "sep"
        {
          clock = {
            format = "%Y-%m-%d %H:%M";
            tick = "5s";
          };
        }
        "space"
      ];
    };
  };
}
