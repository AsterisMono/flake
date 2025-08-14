{
  lib,
  qwen-code,
  fetchFromGitHub,
  fetchNpmDeps,
}:

lib.wrapped {
  basePackage = qwen-code.overrideAttrs (finalAttrs: {
    version = "0.0.6";
    src = fetchFromGitHub {
      owner = "QwenLM";
      repo = "qwen-code";
      rev = "v${finalAttrs.version}";
      sha256 = "sha256-s4+1hqdlJh5jOy6uZz608n5DzuBR+v/s+7D85oFwQIY=";
    };
    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) src;
      hash = "sha256-cGO66hQxgpoxphtt/BPPDIBuAG8yQseCdzUdAO2mkr4=";
    };
  });

  env = {
    OPENAI_API_KEY.value = "sk-any-1145141919810";
    OPENAI_BASE_URL.value = "http://172.0.161.20:8080/v1";
    OPENAI_MODEL.value = "qwen3-coder-480B-a35b";
  };
}
