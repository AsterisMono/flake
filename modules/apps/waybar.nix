_: {
  flake.modules.nixos.waybar =
    { lib, ... }:
    {
      options.hardware.sensors.cpuTemperature = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              hwmonPathAbs = lib.mkOption {
                type = lib.types.str;
                description = "Runtime hwmon directory containing the CPU temperature sensor.";
              };

              inputFilename = lib.mkOption {
                type = lib.types.str;
                default = "temp1_input";
                description = "CPU temperature input file within the hwmon directory.";
              };
            };
          }
        );
        default = null;
        description = "The machine's CPU temperature sensor.";
      };
    };

  flake.modules.homeManager.waybar =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      cpuTemperatureSensor = osConfig.hardware.sensors.cpuTemperature;
    in
    {
      home.packages = [ pkgs.selfPackages.waycat ];

      services.playerctld.enable = true;

      programs.waybar = {
        enable = true;
        systemd.enable = true;

        settings = [
          {
            name = "topbar";
            layer = "top";
            position = "top";
            exclusive = true;
            passthrough = false;
            height = 30;
            spacing = 20;
            modules-left = [
              "clock"
              "custom/nixos"
              "systemd-failed-units"
            ];
            modules-center = [ "mpris" ];
            modules-right = [
              "custom/waycat"
              "network#speed"
            ]
            ++ lib.optional (cpuTemperatureSensor != null) "temperature"
            ++ [
              "memory"
              "battery"
              "wireplumber"
              "tray"
            ];

            clock = {
              format = "🏳️‍⚧️ {:%H:%M}";
              tooltip-format = "{:%Y-%m-%d}";
            };

            systemd-failed-units = {
              hide-on-ok = true;
              format = " {nr_failed}";
              format-ok = "";
              system = true;
              user = true;
            };

            backlight = {
              format = "{icon} {percent}%";
              format-icons = [
                "󰃞"
                "󰃝"
                "󰃠"
              ];
              on-scroll-up = "brightnessctl set 1%+";
              on-scroll-down = "brightnessctl set 1%-";
              min-length = 6;
            };

            battery = {
              format = "{icon} {capacity}%";
              format-charging = " {capacity}%";
              format-plugged = " {capacity}%";
              format-icons = [
                "󰂎"
                "󰁺"
                "󰁻"
                "󰁼"
                "󰁽"
                "󰁾"
                "󰁿"
                "󰂀"
                "󰂁"
                "󰂂"
                "󰁹"
              ];
            };

            wireplumber = {
              format = "{icon} {volume}%";
              format-muted = "";
              scroll-step = 1;
              on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
              on-click-right = "pavucontrol";
              format-icons.default = "";
            };

            temperature = lib.optionalAttrs (cpuTemperatureSensor != null) {
              hwmon-path-abs = cpuTemperatureSensor.hwmonPathAbs;
              input-filename = cpuTemperatureSensor.inputFilename;
              format = " {temperatureC}°C";
            };

            cpu = {
              interval = 1;
              format = "{usage}%";
            };

            "custom/waycat" = {
              exec = "${pkgs.lib.getExe pkgs.selfPackages.waycat} --format-enabled --format '<span font_family=\"polycat\" size=\"160%\">$frame</span>'";
              format = "{}";
            };

            memory = {
              interval = 3;
              format = " {}%";
              tooltip = true;
              tooltip-format = "Memory - {used:0.1f}GB used";
              on-click = "kitty --start-as=fullscreen --title btop sh -c 'btop'";
            };

            "network#speed" = {
              interval = 3;
              format-wifi = " {bandwidthUpBytes}  {bandwidthDownBytes}";
              format-ethernet = " {bandwidthUpBytes}  {bandwidthDownBytes}";
            };

            bluetooth = {
              format = "󰂯 {status}";
              format-disabled = "";
              format-connected = "󰂯 {num_connections}";
              tooltip-format = "{device_alias}";
              tooltip-format-connected = "󰂯 {device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}";
            };

            mpris = {
              format = "{status_icon} {dynamic}";
              dynamic-order = [
                "title"
                "artist"
                "album"
              ];
              status-icons = {
                playing = "";
                paused = "";
                stopped = "";
              };
            };

            tray = {
              icon-size = 16;
              spacing = 4;
            };

            "custom/nixos" = {
              exec = "cat /run/current-system/nixos-version";
              interval = "once";
              format = "with Noa Virellia · NixOS {text}";
            };
          }
          {
            name = "taskbar";
            layer = "top";
            position = "bottom";
            exclusive = true;
            passthrough = false;
            height = 30;
            spacing = 0;
            modules-left = [
              "sway/workspaces"
              "wlr/taskbar"
            ];
            modules-right = [
              "custom/waycodex"
              "custom/wayherdr"
              "sway/scratchpad"
            ];
            "custom/waycodex" = {
              exec = "${pkgs.lib.getExe pkgs.selfPackages.waycodex} --offline '' --format '5h {5h_left}% • 1w {1w_left}% • reset {next_reset}'";
              interval = 60;
              format = "{}";
            };
            "custom/wayherdr" = {
              exec = "${pkgs.lib.getExe pkgs.selfPackages.wayherdr} --offline '' --format ' <span foreground=\"#5a524c\">|</span> 󰄛 {working}{{#blocked}} <span foreground=\"#d8a657\">󱜺</span> {blocked}{{/blocked}}{{#done}} <span foreground=\"#a9b665\">󰅿</span> {done}{{/done}}'";
              interval = 3;
              format = "{}";
            };
            "sway/workspaces" = {
              all-outputs = true;
              disable-scroll-wraparound = true;
              format = "{name}";
            };
            "sway/scratchpad" = {
              format = "{icon} {count}";
              format-icons = [
                ""
                ""
              ];
              show-empty = false;
              tooltip = true;
              tooltip-format = "{app}: {title}";
              on-click = "swaymsg scratchpad show";
            };
            "wlr/taskbar" = {
              all-outputs = true;
              format = "{icon} {title}";
              icon-size = 16;
              icon-theme = "Tela-dark";
              tooltip = false;
              on-click = "activate";
              on-click-middle = "close";
              rewrite = {
                "(.{24}).+" = "$1…";
                "Firefox Web Browser" = "Firefox";
              };
            };
          }
        ];

        style = ''
          window#waybar.topbar {
            background: alpha(@base00, 0.92);
          }

          window#waybar.topbar > box {
            padding: 4px 8px;
          }

          window#waybar.taskbar {
            background: alpha(@base00, 0.92);
            border-top: 1px solid alpha(@base04, 0.35);
          }

          window#waybar.taskbar > box {
            padding-right: 8px;
          }

          #workspaces {
            background: @base01;
          }

          #workspaces button,
          #taskbar button {
            min-width: 32px;
            padding: 0 10px;
            color: @base04;
            background: transparent;
            border: 0;
            border-radius: 0;
            box-shadow: inset 0 -2px transparent;
            text-shadow: none;
          }

          #taskbar button {
            min-width: 240px;
          }

          #workspaces button:hover,
          #taskbar button:hover {
            padding: 0 10px;
            color: @base04;
            background: transparent;
            border: 0;
            box-shadow: inset 0 -2px transparent;
            text-shadow: none;
          }

          #workspaces button.focused,
          #taskbar button.active {
            color: @base07;
            background: @base02;
            box-shadow: inset 0 -2px @base0D;
          }

          #workspaces button.urgent,
          #taskbar button.urgent {
            color: @base00;
            background: @base08;
            box-shadow: inset 0 -2px @base0A;
          }

          #custom-nixos {
            margin-left: -10px;
            padding-top: 2px;
            font-size: 8pt;
          }
        '';
      };
    };
}
