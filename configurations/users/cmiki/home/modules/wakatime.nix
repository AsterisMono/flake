{ flake, ... }:
let
  wakatimeApiKeySecretModule = {
    age.secrets.wakatimeApiKey = {
      file = ${flake}/secrets/wakatime-apikey.age;
      path = "/home/cmiki/.wakatime.cfg";
    };
  };
in
{
  imports = [
    wakatimeApiKeySecretModule
  ];
}
