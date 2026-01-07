{
  system,
  unstablePkgs,
  lib,
  ...
}:
let
  readJson = path: builtins.fromJSON (builtins.readFile path);
in
{
  programs.zed-editor = {
    enable = true;
    package = if system == "aarch64-darwin" then null else unstablePkgs.zed-editor;
    extensions = [
      "html"
      "svelte"
      "astro"
      "biome"
      "nix"
      "rose-pine-theme"
      "just"
    ];
    userSettings = readJson ./settings.json;
    userKeymaps = readJson ./keymap.json;
    mutableUserSettings = true;
    mutableUserKeymaps = true;
  };

  # https://zed.dev/docs/environment
  # When Zed has been launched via the macOS Dock, or a GNOME or KDE icon on Linux,
  # or an application launcher like Alfred or Raycast, it has no surrounding shell
  # environment from which to inherit its environment variables.
  #
  # In order to still have a useful environment, Zed spawns a login shell in the user's
  # home directory and gets its environment. This environment is then set on the Zed process.
  #
  # That means all Zed windows and projects will inherit that home directory environment.
  home.sessionVariables = {
    ZED_PREDICT_EDITS_URL = "http://gpu-worker-1.tail7fad75.ts.net:9000/predict_edits";
    EDITOR = "zed --wait -n";
  };

  # Session variables are now always set through the shell. This is
  # done automatically if the shell configuration is managed by Home
  # Manager. If not, then you must source the
  #   ${cfg.profileDirectory}/etc/profile.d/hm-session-vars.sh
  # file yourself.
  #
  # This hints we must manage zsh with home-manager if we're on aarch64-darwin.
  programs.zsh.enable = lib.mkDefault (system == "aarch64-darwin");

  # Stylix
  stylix.targets.zed.enable = false;
}
