{
  system,
  username,
  lib,
  ...
}:

{
  programs.home-manager.enable = true;

  home = {
    inherit username;
    homeDirectory = if system == "aarch64-darwin" then "/Users/${username}" else "/home/${username}";
    stateVersion = "24.05";
  };

  xdg.userDirs = lib.mkIf (system != "aarch64-darwin") {
    enable = true;
    createDirectories = true;
  };
}
