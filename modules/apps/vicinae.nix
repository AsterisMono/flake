_: {
  flake.modules.homeManager.vicinae = {
    programs.vicinae = {
      enable = true;
      settings.providers.applications.preferences.launchPrefix = "uwsm app --";
      systemd = {
        enable = true;
        autoStart = true;
      };
    };
  };
}
