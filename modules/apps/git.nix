{
  flake.modules.homeManager.git = { config, ... }: {
    programs.git = {
      enable = true;
      settings = {
        user = with config.constants.nvirellia; {
          name = preferredName;
          inherit email;
          signingKey = sshPubKey;
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        commit.gpgsign = true;
        gpg.format = "ssh";
      };
    };
  };
}
