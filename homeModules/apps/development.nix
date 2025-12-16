{
  pkgs,
  unstablePkgs,
  ...
}:
let
  ccnupr = pkgs.writeShellScriptBin "ccnupr" (builtins.readFile ./scripts/ccnupr.sh);
  realize = pkgs.writeShellScriptBin "realize" (builtins.readFile ./scripts/realize.sh);
in
{
  home.packages = with pkgs; [
    # Runtime / Compilers
    nodejs_22
    corepack_22
    devenv
    go
    uv

    # Language servers
    nixd
    nixfmt-rfc-style
    typescript # tsserver
    vscode-langservers-extracted
    yaml-language-server
    yamlfmt
    gopls

    # Scripts
    ccnupr
    realize
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    vimAlias = true;
    package = unstablePkgs.neovim-unwrapped;
  };
}
