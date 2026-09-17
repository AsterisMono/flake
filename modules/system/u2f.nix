{
  flake.modules.nixos.u2f = {
    security.pam.u2f = {
      control = "sufficient";
      settings = {
        authfile = "/etc/u2f-mappings";
        origin = "pam://nvirellia";
        cue = true;
      };
    };

    security.pam.services = {
      greetd.u2f.enable = true;
      login.u2f.enable = true;
      sudo.u2f.enable = true;
      swaylock.u2f.enable = true;
    };

    environment.etc."u2f-mappings".text =
      "nvirellia:cxMAOv20SDEK3+/85zFWEN1Bn+ch3DTjPafLHTkX1PrdCZmpkBL126BQ5FcuQUNSMxKEPNfREKv9L7kOIrtzc1aUJfTLu/JRk0jINfYPQ0AxB7iwjFEp61KZilT2g4dD,0QCaAy3o37rB9Pc6b5+oZj3YKAuf3hOqxkFq0WsUGheWYNKH4Ki49eoa/6cTby+jP3TOsc63uCHJ46ZZj7kl6A==,es256,+presence\n";
  };
}
