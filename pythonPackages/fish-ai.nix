{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  setuptools,
  anthropic,
  binaryornot,
  cohere,
  google-genai,
  groq,
  iterfzf,
  keyring,
  mistralai,
  openai,
  simple-term-menu,
  socksio,
}:

buildPythonPackage rec {
  pname = "fish-ai";
  version = "2.3.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Realiserad";
    repo = "fish-ai";
    rev = "v${version}";
    hash = "sha256-ydWM8LoM6TsWOmMXzfJ5bSrvqrk9EPGS1wkKowbA3DA=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    anthropic
    binaryornot
    cohere
    google-genai
    groq
    iterfzf
    keyring
    mistralai
    openai
    simple-term-menu
    socksio
  ];

  pythonImportsCheck = [
    "fish_ai"
  ];

  pythonRelaxDeps = true;

  meta = {
    description = "Supercharge your command line with LLMs and get shell scripting assistance in Fish";
    homepage = "https://github.com/Realiserad/fish-ai";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ AsterisMono ];
    mainProgram = "fish-ai";
  };
}
