{ nvimConfig, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  xdg.configFile.nvim.source = nvimConfig;

  home.packages = with pkgs; [
    lua_ls # Lua language server
  ];
}
