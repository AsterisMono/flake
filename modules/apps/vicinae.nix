_: {
  flake.modules.homeManager.vicinae = {
    programs.vicinae = {
      enable = true;
      systemd = {
        enable = true;
        autoStart = true;
      };
    };
  };
}
