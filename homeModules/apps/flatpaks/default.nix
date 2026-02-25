{ inputs, ... }:
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    overrides = {
      global = {
        Context.filesystems = [
          "/nix/store:ro"
          "xdg-config/fontconfig:ro"
        ];
      };
    };
  };
}
