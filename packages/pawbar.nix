{
  fetchFromGitHub,
  fetchgit,
  buildGoModule,

  udev,
  librsvg,
  cairo,
  pkg-config,
}:
let
  vaxis = fetchgit {
    url = "https://git.sr.ht/~codelif/vaxis";
    hash = "sha256-7j9npVYu7U8QyXrFYbeyda64l0S0VYdQNE9S6wc+lxM=";
  };
in
buildGoModule {
  pname = "pawbar";
  version = "0-unstable-2025-08-31";
  src = fetchFromGitHub {
    owner = "codelif";
    repo = "pawbar";
    rev = "0963638b92a5206904ad85f95760177683cea383";
    hash = "sha256-dfQwCLXVGMkMff/uiDKQptDIGZbilob68X3lI57Tt48=";
  };

  postUnpack = ''
    cp -r ${vaxis} vaxis
  '';

  subPackages = [ "cmd/pawbar" ];
  vendorHash = "sha256-5ysy7DGLE99svDPUw1vS05CT7HRcSP1ov27rTqm6a8Y=";
  buildInputs = [
    udev
    librsvg
    cairo
  ];
  nativeBuildInputs = [ pkg-config ];
}
