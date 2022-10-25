{ ... }:

{
  home-manager.users.cmiki = {
    programs.git = {
      enable = true;
      userName = "AsterisMono";
      userEmail = "cmiki@amono.me";
      # signing.key = "DFE7C05195DA2F2BF14481CF3A6BE8BAF2EDE134";
      extraConfig = {
        init.defaultBranch = "main";
        credential.helper = "store";
        pull.rebase = true;
      };
    };
  };
}
