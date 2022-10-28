{ inputs, config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs;[
    libsForQt5.bismuth
  ];

  home-manager.users.cmiki.programs.plasma = {
    shortcuts = {
      "bismuth"."focus_bottom_window" = "Meta+J";
      "bismuth"."focus_left_window" = "Meta+H";
      "bismuth"."focus_next_window" = "Meta+N";
      "bismuth"."focus_prev_window" = "Meta+P";
      "bismuth"."focus_right_window" = "Meta+L";
      "bismuth"."focus_upper_window" = "Meta+K";
      "bismuth"."move_window_to_bottom_pos" = "Meta+Shift+J";
      "bismuth"."move_window_to_left_pos" = "Meta+Shift+H";
      "bismuth"."move_window_to_right_pos" = "Meta+Shift+L";
      "bismuth"."move_window_to_upper_pos" = "Meta+Shift+K";
      "bismuth"."toggle_float_layout" = "Meta+Shift+F";
      "bismuth"."toggle_monocle_layout" = "Meta+M";
    };
    files = {
      "kwinrc"."Plugins"."bismuthEnabled" = true;
      "kwinrc"."Script-bismuth"."maximizeSoleTile" = true;
      "kwinrc"."Script-bismuth"."preventMinimize" = true;
      "kwinrc"."Script-bismuth"."screenGapBottom" = 4;
      "kwinrc"."Script-bismuth"."screenGapLeft" = 4;
      "kwinrc"."Script-bismuth"."screenGapRight" = 4;
      "kwinrc"."Script-bismuth"."screenGapTop" = 4;
      "kwinrc"."Script-bismuth"."tileLayoutGap" = 4;
      "kwinrc"."Script-bismuth"."untileByDragging" = false;
      "kwinrc"."org.kde.kdecoration2"."BorderSize" = "None";
      "kwinrc"."org.kde.kdecoration2"."BorderSizeAuto" = false;
      "kwinrc".''org.kde.kdecoration2''."library" = lib.mkForce "org.kde.bismuth.decoration";
      "kwinrc".''org.kde.kdecoration2''."theme" = lib.mkForce "Bismuth";
    };
  };
}
