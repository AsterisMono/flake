_: {
  flake.modules.homeManager.obsidian =
    { pkgs, ... }:
    {
      # Obsidian stores vault, sync, and plugin secrets through Electron's
      # `safeStorage`, and Electron picks that backend from `XDG_CURRENT_DESKTOP`.
      # Sway is not one of the desktops it recognises as GNOME-like, so it falls
      # back to the plaintext `basic_text` store and Obsidian reports that no
      # secret store is available. The Secret Service is already running and
      # unlocked in the session (see the `keyring` aspect), so name the backend
      # that talks to it.
      programs.obsidian = {
        enable = true;
        package = pkgs.obsidian.override {
          commandLineArgs = "--password-store=gnome-libsecret";
        };
      };
    };
}
