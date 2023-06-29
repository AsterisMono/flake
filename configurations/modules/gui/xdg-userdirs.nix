{ ... }:

{
  # FIXME: user name variable
  home-manager.users.cmiki.xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
