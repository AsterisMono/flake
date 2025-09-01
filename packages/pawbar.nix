{
  fetchFromGitHub,
  buildGoModule,

  udev,
  librsvg,
  cairo,
  pkg-config,
}:

buildGoModule {
  pname = "pawbar";
  version = "0-unstable-2025-08-31";
  src = fetchFromGitHub {
    owner = "codelif";
    repo = "pawbar";
    rev = "0963638b92a5206904ad85f95760177683cea383";
    hash = "sha256-dfQwCLXVGMkMff/uiDKQptDIGZbilob68X3lI57Tt48=";
  };

  subPackages = [ "cmd/pawbar" ];
  vendorHash = "sha256-5ysy7DGLE99svDPUw1vS05CT7HRcSP1ov27rTqm6a8Y=";
  buildInputs = [
    udev
    librsvg
    cairo
  ];
  nativeBuildInputs = [ pkg-config ];
}
