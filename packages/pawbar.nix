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
  version = "0-unstable-2025-09-05";
  src = fetchFromGitHub {
    owner = "AsterisMono";
    repo = "pawbar";
    rev = "79d851e7752206d440f8e33c6bd7822e4cd97a48";
    hash = "sha256-2K2O+cudkDur/Itaxuk+ySDDJLel7em+H5Fh+HKcPfc=";
    fetchSubmodules = true;
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
