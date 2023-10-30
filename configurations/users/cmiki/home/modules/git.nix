{ ... }:

{
  programs.git = {
    enable = true;
    userName = "AsterisMono";
    userEmail = "cmiki@amono.me";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
