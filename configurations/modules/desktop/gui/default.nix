{ ... }:

{
  imports = [
    # Desktop Manager and Display Manager are bundled to maximize compatibility.
    ./fonts.nix
    ./audio.nix
    ./ime.nix
  ];
}
