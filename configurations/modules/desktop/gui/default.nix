{ ... }:

{
  imports = [
    # Desktop Manager and Display Manager are bundled to maximize compatibility.
    ./dms/plasma.nix

    ./fonts.nix
    ./audio.nix
    ./ime.nix
  ];
}
