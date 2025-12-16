{ unstablePkgs, ... }:
let
  readJson = path: builtins.fromJSON (builtins.readFile path);
  _zed = unstablePkgs.lib.wrapped {
    basePackage = unstablePkgs.zed-editor;
    env.ZED_PREDICT_EDITS_URL.value = "http://172.0.161.24:9000/predict_edits";
  };
in
{
  programs.zed-editor = {
    enable = true;
    package = _zed;
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
}
