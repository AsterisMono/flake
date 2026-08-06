{
  flake.modules.generic.constants-nvirellia = { lib, ... }: {
    options.constants.nvirellia = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };

    config.constants.nvirellia = {
      username = "nvirellia";
      preferredName = "Noa Virellia";
      email = "i@nvirellia.im";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOOz0CMmkGSXv4H77rmrmvadltAlwAZeVimxGoUAfArs";
      hashedPassword = "$y$j9T$Or7mqutFE5iEFtJb4QmdR1$N0yuyRzIOavwnsnrkK4yR5Msg1oQ0RAXpKVN/LpV3p.";
    };
  };
}
