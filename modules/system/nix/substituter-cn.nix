{
  flake.modules.nixos.substituter-cn = {
    nix.settings.substituters = [
      "https://mirrors4.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://ipv4.mirrors.ustc.edu.cn/nix-channels/store"
    ];
  };
}
