_: {
  flake.modules.nixos.udiskie = {
    services.udisks2.enable = true;
  };

  flake.modules.homeManager.udiskie = {
    services.udiskie.enable = true;

    # graphical-session.target already scopes this to a session; the
    # environment check keeps it out of TTY sessions.
    systemd.user.services.udiskie.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
  };
}
