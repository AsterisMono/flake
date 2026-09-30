_: {
  flake.modules.nixos.steam = { pkgs, ... }: {
    # Nested under niri, not a display-manager session: gamescope is the launch
    # option for Steam titles (`gamescope -- %command%`), and niri already has a
    # `^gamescope$` window rule for its client window.
    programs.gamescope.enable = true;

    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}
