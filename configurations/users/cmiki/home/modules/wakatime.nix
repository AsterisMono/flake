{ config, ... }:
let
  wakatimeApiKeySecretModule = {
    age.secrets.wakatimeApiKey = {
      file = ../../../../../../secrets/wakatime-apikey.age;
      path = "/home/cmiki/.wakatime.cfg";
    };
  };
in
{
  imports = [
    wakatimeApiKeySecretModule
  ];
}
