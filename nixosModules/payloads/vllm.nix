{ pkgs, ... }:
{
  environment.defaultPackages = [
    pkgs.vllm
  ];

  environment.variables = {
    HF_ENDPOINT = "https://hf-mirror.com";
  };
}
