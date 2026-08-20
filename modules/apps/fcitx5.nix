_: {
  flake.modules.homeManager.fcitx5 = { pkgs, ... }: {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          qt6Packages.fcitx5-configtool
          fcitx5-fluent
          (fcitx5-rime.override {
            rimeDataPkgs = [ rime-ice ];
          })
        ];
      };
    };

    xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
      patch:
        __include: rime_ice_suggestion:/

        schema_list:
          - schema: rime_ice
    '';
  };
}
