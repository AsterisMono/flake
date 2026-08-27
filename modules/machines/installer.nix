{ inputs, ... }:
{
  machines.installer = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      installer
      i18n
      substituter-cn
    ];
    hardware = { lib, ... }: {
      networking.hostName = "installer";
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
  };
}
