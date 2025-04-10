{ pkgs, ... }:
let
  oneDriveFsOptions = [
    "ro"
    "_netdev"
    "nofail"
    "allow_other"
    "args2env"
    # TODO: secret management
    "config=/home/cmiki/.config/rclone/onedrive.conf"
    "cache-dir=/var/rclone"
    "vfs-cache-mode=full"
  ];
in
{
  environment.systemPackages = [ pkgs.rclone ];
  fileSystems."/var/lib/vrchat-library" = {
    device = "one-drive:/图片/VRChat";
    fsType = "rclone";
    options = oneDriveFsOptions;
  };
  fileSystems."/var/lib/music" = {
    device = "one-drive:/音乐";
    fsType = "rclone";
    options = oneDriveFsOptions;
  };
}
