_: {
  flake.modules.nixos.quickshell =
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

  flake.modules.homeManager.quickshell =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      cpuTemperatureSensor = osConfig.hardware.sensors.cpuTemperature or null;

      sensorPath = lib.optionalString (
        cpuTemperatureSensor != null
      ) "${cpuTemperatureSensor.hwmonPathAbs}/${cpuTemperatureSensor.inputFilename}";

      # Emits one JSON object per sample. Missing or unreadable metrics are
      # reported as null so the shell can distinguish "unavailable" from zero.
      healthScript = pkgs.writeShellApplication {
        name = "quickshell-health";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gawk
          pkgs.gnugrep
          pkgs.systemd
        ];
        text = ''
          sensor="''${1:-}"
          state_dir="''${XDG_RUNTIME_DIR:-/tmp}/quickshell-health"
          mkdir -p "$state_dir"

          iface=""
          while read -r name destination _; do
            if [ "$destination" = "00000000" ]; then
              iface="$name"
              break
            fi
          done < /proc/net/route

          rx=0
          tx=0
          if [ -n "$iface" ] && [ -r "/sys/class/net/$iface/statistics/rx_bytes" ]; then
            rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
            tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
          fi

          now=$(date +%s%N)
          down=0
          up=0
          previous="$state_dir/net"
          if [ -r "$previous" ]; then
            read -r previous_time previous_rx previous_tx < "$previous" || true
            if [ -n "''${previous_time:-}" ] && [ "$now" -gt "''${previous_time:-0}" ] \
              && [ "$rx" -ge "''${previous_rx:-0}" ] && [ "$tx" -ge "''${previous_tx:-0}" ]; then
              elapsed=$(( (now - previous_time) / 1000000000 ))
              if [ "$elapsed" -gt 0 ]; then
                down=$(( (rx - previous_rx) / elapsed ))
                up=$(( (tx - previous_tx) / elapsed ))
              fi
            fi
          fi
          printf '%s %s %s\n' "$now" "$rx" "$tx" > "$previous"

          memory=$(awk '
            /^MemTotal:/ { total = $2 }
            /^MemAvailable:/ { available = $2 }
            /^SwapTotal:/ { swap_total = $2 }
            /^SwapFree:/ { swap_free = $2 }
            /^Zswap:/ { zswap = $2 }
            /^Zswapped:/ { zswapped = $2 }
            END {
              printf "%.3f %.3f %.3f %.3f %.3f %.3f",
                (total - available) / 1048576,
                total / 1048576,
                (swap_total - swap_free) / 1048576,
                swap_total / 1048576,
                zswap / 1048576,
                zswapped / 1048576
            }
          ' /proc/meminfo)
          read -r mem_used mem_total swap_used swap_total zswap zswapped <<< "$memory"

          psi_some_10=0
          psi_some_60=0
          psi_some_300=0
          psi_full_10=0
          psi_full_60=0
          psi_full_300=0
          if [ -r /proc/pressure/memory ]; then
            pressure=$(awk '
              /^some/ {
                for (i = 1; i <= NF; i++) {
                  split($i, kv, "=")
                  if (kv[1] == "avg10") s10 = kv[2]
                  if (kv[1] == "avg60") s60 = kv[2]
                  if (kv[1] == "avg300") s300 = kv[2]
                }
              }
              /^full/ {
                for (i = 1; i <= NF; i++) {
                  split($i, kv, "=")
                  if (kv[1] == "avg10") f10 = kv[2]
                  if (kv[1] == "avg60") f60 = kv[2]
                  if (kv[1] == "avg300") f300 = kv[2]
                }
              }
              END { printf "%s %s %s %s %s %s", s10 + 0, s60 + 0, s300 + 0, f10 + 0, f60 + 0, f300 + 0 }
            ' /proc/pressure/memory)
            read -r psi_some_10 psi_some_60 psi_some_300 psi_full_10 psi_full_60 psi_full_300 <<< "$pressure"
          fi

          temperature=null
          if [ -n "$sensor" ] && [ -r "$sensor" ]; then
            raw=$(cat "$sensor")
            temperature=$(awk -v raw="$raw" 'BEGIN { printf "%.1f", raw / 1000 }')
          fi

          failed_system=$(systemctl list-units --state=failed --no-legend --no-pager -q 2>/dev/null | grep -c . || true)
          failed_user=$(systemctl --user list-units --state=failed --no-legend --no-pager -q 2>/dev/null | grep -c . || true)

          printf '{"iface":"%s","netUp":%s,"netDown":%s,"memUsed":%s,"memTotal":%s,"swapUsed":%s,"swapTotal":%s,"zswap":%s,"zswapped":%s,"psiSome10":%s,"psiSome60":%s,"psiSome300":%s,"psiFull10":%s,"psiFull60":%s,"psiFull300":%s,"temp":%s,"failedSystem":%s,"failedUser":%s}\n' \
            "$iface" "$up" "$down" \
            "$mem_used" "$mem_total" "$swap_used" "$swap_total" "$zswap" "$zswapped" \
            "$psi_some_10" "$psi_some_60" "$psi_some_300" "$psi_full_10" "$psi_full_60" "$psi_full_300" \
            "$temperature" "$failed_system" "$failed_user"
        '';
      };

      # Prints one line per herdr client process: the client pid followed by its
      # ancestor pids. Herdr panes belong to the herdr server, so the only
      # honest relation to a desktop window is the terminal that hosts the
      # client; the shell intersects these pids with Sway's window pids before
      # it is willing to raise anything. Read-only: /proc only.
      herdrHostScript = pkgs.writeShellApplication {
        name = "quickshell-herdr-host";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
        ];
        text = ''
          for proc in /proc/[0-9]*; do
            pid="''${proc#/proc/}"
            [ -r "$proc/comm" ] || continue
            [ "$(cat "$proc/comm" 2>/dev/null)" = "herdr" ] || continue
            cmdline=$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null || true)
            case "$cmdline" in
              # The server owns the panes; only the client is attached to a window.
              *server*) continue ;;
            esac

            line="$pid"
            current="$pid"
            hops=0
            while [ "$current" -gt 1 ] && [ "$hops" -lt 16 ]; do
              stat=$(cat "/proc/$current/stat" 2>/dev/null) || break
              rest="''${stat#*) }"
              ppid=$(printf '%s' "$rest" | cut -d' ' -f2)
              [ -n "$ppid" ] || break
              [ "$ppid" -gt 1 ] || break
              line="$line $ppid"
              current="$ppid"
              hops=$((hops + 1))
            done
            printf '%s\n' "$line"
          done
        '';
      };

      qmlString =
        value: "\"${lib.replaceStrings [ "\\" "\"" "\n" ] [ "\\\\" "\\\"" " " ] (toString value)}\"";

      qmlList = values: "[${lib.concatMapStringsSep ", " qmlString values}]";

      # Herdr owns its socket; the shell only ever connects to it. The default
      # session lives beside herdr's configuration, and the endpoint stays
      # empty when herdr is not part of this machine, which keeps V1 quiet.
      herdrEndpoint =
        if (config.programs.herdr.enable or false) then "${config.xdg.configHome}/herdr/herdr.sock" else "";

      swayPackage = config.wayland.windowManager.sway.package;
      kitty = lib.getExe pkgs.kitty;
      btop = lib.getExe pkgs.btop;
      waycat = lib.getExe pkgs.selfPackages.waycat;

      runtimeQml = pkgs.writeText "Runtime.qml" ''
        pragma Singleton
        import Quickshell

        Singleton {
          readonly property string quickshellVersion: ${qmlString pkgs.quickshell.version};
          readonly property string swayVersion: ${qmlString swayPackage.version};
          readonly property string hostName: ${qmlString osConfig.networking.hostName};
          readonly property string homeDirectory: ${qmlString config.home.homeDirectory};
          readonly property string nixosVersion: ${qmlString osConfig.system.nixos.label};
          readonly property string herdrEndpoint: ${qmlString herdrEndpoint};
          readonly property string swaymsg: ${qmlString (lib.getExe' swayPackage "swaymsg")};
          readonly property string healthScript: ${qmlString (lib.getExe healthScript)};
          readonly property string sensorPath: ${qmlString sensorPath};
          readonly property string herdrHostScript: ${
            qmlString (if herdrEndpoint == "" then "" else lib.getExe herdrHostScript)
          };
          readonly property string pavucontrol: ${qmlString (lib.getExe pkgs.pavucontrol)};
          readonly property string waycat: ${qmlString waycat};
          readonly property var btopCommand: ${
            qmlList [
              kitty
              "--start-as=fullscreen"
              "--title"
              "btop"
              "sh"
              "-c"
              btop
            ]
          };
        }
      '';

      configDir = pkgs.runCommand "quickshell-desk-bars" { } ''
        mkdir -p $out
        cp -r ${./.}/. $out/
        rm -f $out/default.nix
        cp ${runtimeQml} $out/Runtime.qml
      '';
    in
    {
      programs.quickshell = {
        enable = true;
        package = pkgs.quickshell;
        activeConfig = "desk";
        configs.desk = configDir;
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
      };

      # MPRIS player choice is kept stable across player restarts.
      services.playerctld.enable = true;

      # waycat supplies both the health-bar animation process and the
      # "polycat" font its frames are drawn with. The shell consumes it, so it
      # has to install it here: the Waybar feature that used to own this
      # package is no longer composed once Quickshell replaces it.
      home.packages = [ pkgs.selfPackages.waycat ];

      systemd.user.services.quickshell = {
        Unit = {
          ConditionEnvironment = [
            "WAYLAND_DISPLAY"
            "XDG_SESSION_DESKTOP=sway"
          ];
          PartOf = [ "graphical-session.target" ];
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
        Service = {
          Restart = "on-failure";
          RestartSec = 2;
          TimeoutStopSec = 5;
        };
      };
    };
}
