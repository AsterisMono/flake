{ pkgs, ... }:
let
  lineageVersion = "18.1-20250628";
  images = {
    system = pkgs.fetchzip {
      url = "https://sourceforge.net/projects/waydroid/files/images/system/lineage/waydroid_x86_64/lineage-${lineageVersion}-VANILLA-waydroid_x86_64-system.zip/download";
      extension = "zip";
      hash = "sha256-C/M1EbSbWHn5a2PMnmlKGtZITd2Iya2jtrJB6mYFMfY=";
    };
    vendor = pkgs.fetchzip {
      url = "https://sourceforge.net/projects/waydroid/files/images/vendor/waydroid_x86_64/lineage-${lineageVersion}-MAINLINE-waydroid_x86_64-vendor.zip/download";
      extension = "zip";
      hash = "sha256-5iQpAUhDOde2cdb+bXu5sxcldk6EN0jbl8zWt24NrYA=";
    };
  };
  waydroidImages = pkgs.symlinkJoin {
    name = "waydroid-images";
    paths = with images; [
      system
      vendor
    ];
  };
in
{
  virtualisation.waydroid.enable = true;

  environment = {
    etc."waydroid-extra/images".source = waydroidImages;
    systemPackages = [
      pkgs.nur.repos.ataraxiasjel.waydroid-script
    ];
  };
}
