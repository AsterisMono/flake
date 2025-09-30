{
  lib,
  buildPythonPackage,
  fetchPypi,
  poetry-core,
  eval-type-backport,
  httpx,
  invoke,
  pydantic,
  python-dateutil,
  pyyaml,
  typing-inspection,
}:

buildPythonPackage rec {
  pname = "mistralai";
  version = "1.9.10";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-qVchJ28DW/hsf9wTc9f7fQVtg1ECJvNJQm4NUiwMCWU=";
  };

  build-system = [
    poetry-core
  ];

  dependencies = [
    eval-type-backport
    httpx
    invoke
    pydantic
    python-dateutil
    pyyaml
    typing-inspection
  ];

  pythonImportsCheck = [
    "mistralai"
  ];

  meta = {
    description = "Python Client SDK for the Mistral AI API";
    homepage = "https://pypi.org/project/mistralai/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ AsterisMono ];
  };
}
