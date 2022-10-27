{ ... }:

{
  home-manager.users.cmiki = {
    programs.git = {
      enable = true;
      userName = "AsterisMono";
      userEmail = "cmiki@amono.me";
      extraConfig = {
        init.defaultBranch = "main";
        credential.helper = "store";
        pull.rebase = true;
      };
    };
  };
}
