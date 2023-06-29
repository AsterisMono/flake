{ ... }:

{
  home-manager.users.cmiki = {
    programs.git = {
      enable = true;
      userName = "AsterisMono";
      userEmail = "cmiki@amono.me";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };

    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "https";
      };
    };
  };
}
