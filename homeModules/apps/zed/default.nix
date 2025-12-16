{ system, unstablePkgs, ... }:
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

  home.sessionVariables = {
    ZED_PREDICT_EDITS_URL = "http://172.0.161.24:9000/predict_edits";
    EDITOR = "zed --wait -n";
  };
}
