_:

{
  programs.git = {
    enable = true;
    userName = "Chatnoir Miki";
    userEmail = "cmiki@amono.me";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
