{
  config,
  pkgs,
  hostname,
  ...
}:

{
  networking.hostName = hostname;
  networking.computerName = hostname;

  time.timeZone = "Asia/Shanghai";

  system = {
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    # This will be run as root. Take care.
    activationScripts.postActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      sudo -u ${config.system.primaryUser} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      smb.NetBIOSName = hostname;
      menuExtraClock.Show24Hour = true; # show 24 hour clock

      dock = {
        autohide = true;
        show-recents = false;
        tilesize = 56;
        mineffect = "scale";
        launchanim = false;
      };

      finder = {
        _FXShowPosixPathInTitle = true; # show full path in finder title
        AppleShowAllExtensions = true; # show all file extensions
        FXEnableExtensionChangeWarning = false; # disable warning when changing file extension
        QuitMenuItem = true; # enable quit menu item
        ShowPathbar = true; # show path bar
        ShowStatusBar = true; # show status bar
      };

      universalaccess.reduceMotion = true;

      NSGlobalDomain = {
        "com.apple.swipescrolldirection" = false;
        ApplePressAndHoldEnabled = false;
        KeyRepeat = 2;
        InitialKeyRepeat = 25;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      # Skip this when using external keyboard
      # swapLeftCtrlAndFn = true;
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;

  programs.fish.enable = true;

  environment.shells = with pkgs; [
    zsh
    fish
  ];

  environment.variables.SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  system.stateVersion = 5;
}
