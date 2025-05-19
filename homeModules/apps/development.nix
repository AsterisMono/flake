{ pkgs, unstablePkgs, ... }:
let
  ccnupr = pkgs.writeShellScriptBin "ccnupr" (builtins.readFile ./scripts/ccnupr);
in
{
  home.packages = with pkgs; [
    nodejs_22
    corepack_22
    kubectl
    devenv

    # Language servers
    nixd
    typescript # tsserver
    vscode-langservers-extracted

    # Scripts
    ccnupr
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    package = unstablePkgs.neovim-unwrapped;
  };
}
