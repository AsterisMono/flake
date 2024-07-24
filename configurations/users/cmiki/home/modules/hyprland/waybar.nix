{ config, lib, ... }:

with lib;

let
  cfg = config.amonoHome.waybar;
in
{
  options.amonoHome.waybar = {
    enable = mkOption {
      type = types.bool;
      default = config.amonoHome.hyprland.enable;
      description = "是否启用 Waybar";
    };
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          # "layer" = "top"; # Waybar at top layer
          # "position" = "bottom"; # Waybar position (top|bottom|left|right)
          # height = 30; # Waybar height (to be removed for auto height)
          #"width" = 1920; # Waybar width
          spacing = 4; # Gaps between modules (4px)
          # Choose the order of the modules
          modules-left = [
            "hyprland/workspaces"
          ];
          modules-center = [ ];
          modules-right = [
            "network"
            "pulseaudio"
            "backlight"
            "battery"
            "clock"
          ];
          # Modules configuration
          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
            format = "{name} {windows}";
            format-window-separator = " ";
            window-rewrite-default = "";
            window-rewrite = {
              "title<.*youtube.*>" = "";
              "class<firefox>" = "";
              "class<chromium-browser>" = "";
              "class<firefox> title<.*github.*>" = "";
              "class<firefox> title<.*slack.*>" = "";
              "class<kitty>" = "";
              "code" = "󰨞";
            };
          };
          keyboard-state = {
            numlock = true;
            capslock = true;
            format = "{name} {icon}";
            format-icons = {
              locked = "";
              unlocked = "";
            };
          };
          mpd = {
            format =
              "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime =%M =%S}/{totalTime =%M =%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
            format-disconnected = "Disconnected ";
            format-stopped =
              "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
            unknown-tag = "N/A";
            interval = 2;
            consume-icons = { on = " "; };
            random-icons = {
              off = ''<span color="#f53c3c"></span> '';
              on = " ";
            };
            repeat-icons = { on = " "; };
            single-icons = { on = "1 "; };
            state-icons = {
              paused = "";
              playing = "";
            };
            tooltip-format = "MPD (connected)";
            tooltip-format-disconnected = "MPD (disconnected)";
          };
          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              "activated" = "";
              "deactivated" = "";
            };
          };
          tray = {
            # "icon-size" = 21;
            spacing = 10;
          };
          clock = {
            # "timezone" = "America/New_York";
            tooltip-format = ''
              <big>{ =%Y %B}</big>
              <tt><small>{calendar}</small></tt>'';
            format-alt = "{ =%Y-%m-%d}";
            interval = 60;
          };
          backlight = {
            # "device" = "acpi_video1";
            format = "{percent}% ";
            format-icons = [ ];
          };
          battery = {
            states = {
              # "good" = 95;
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% 󰃨";
            format-plugged = "{capacity}% ";
            format-alt = "{time} {icon}";
            # "format-good" = ""; # An empty format will hide the module
            # "format-full" = "";
            format-icons = [ "" "" "" "" "" ];
          };
          network = {
            # "interface" = "wlp2*"; # (Optional) To force the use of this interface
            format-wifi = " {essid} ({signalStrength}%)";
            format-ethernet = "󰈀 {ipaddr}/{cidr}";
            tooltip-format = "{ifname} via {gwaddr} 󰈀";
            format-linked = "󰈀 {ifname} (No IP)";
            format-disconnected = "Disconnected";
            # "format-alt" = "{ifname} = {ipaddr}/{cidr}"
            on-click = "kitty --command nmtui";
          };
          pulseaudio = {
            # "scroll-step" = 1; # %; can be a float
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon}";
            format-bluetooth-muted = "󰆪 {icon}";
            format-muted = "󰆪 {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "󰂑";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };
        };
        memory = {
          format = "{percentage}%";
          interval = 10;
          states = {
            warning = 75;
            critical = 90;
          };
        };
        cpu = {
          format = "{usage}%";
          interval = 10;
          states = {
            warning = 75;
            critical = 90;
          };
        };
      };

      style = builtins.readFile ./waybar-style.css;
    };
  };
}
