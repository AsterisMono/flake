{
  pkgs,
  lib,
  assetsPath,
  ...
}:
{
  services = {
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };

    desktopManager.gnome.enable = true;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    gnome-maps
    simple-scan
    yelp
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-browser-connector
    gdm-settings
  ];

  # Override pulseaudio
  # I have no idea who enabled this
  services.pulseaudio.enable = lib.mkForce false;

  # Profile icon
  system.activationScripts.script.text =
    let
      username = "cmiki";
    in
    ''
      mkdir -p /var/lib/AccountsService/{icons,users}
      cp ${assetsPath}/noa.png /var/lib/AccountsService/icons/${username}
      echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${username}\n" > /var/lib/AccountsService/users/${username}

      chown root:root /var/lib/AccountsService/users/${username}
      chmod 0600 /var/lib/AccountsService/users/${username}

      chown root:root /var/lib/AccountsService/icons/${username}
      chmod 0444 /var/lib/AccountsService/icons/${username}
    '';
}
