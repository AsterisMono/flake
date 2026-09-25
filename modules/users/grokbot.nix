_: {
  flake.modules.nixos.grokbot =
    { pkgs, ... }:
    {
      users.users.grokbot = {
        isNormalUser = true;
        description = "Grok bot";
        createHome = true;
        packages = [ pkgs.devenv ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGm97q8xrP8bqnvVcWPwTZFn+xLmzwL6dIBNkrN/RSnT obsidian-agent-devbot@grok-bot-vm-501610"
        ];
      };
    };
}
