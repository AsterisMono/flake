{ system, lib, ... }:
{
  config = lib.mkIf (system == "aarch64-darwin") {
    # Need to manually config iterm2 to use this settings file.
    # Settings - General - Settings - Load settings from a custom folder or URL
    home.file.".config/iterm2/com.googlecode.iterm2.plist" = {
      source = ./com.googlecode.iterm2.plist;
    };
  };
}
