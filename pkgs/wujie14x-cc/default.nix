{
  fetchFromGitHub,
  go,
  lib,
  stdenvNoCC,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "wujie14x-cc";
  version = "0-unstable-2026-10-19";

  src = fetchFromGitHub {
    owner = "LongSang01";
    repo = "wujie14X-Linux-Driver";
    rev = "1d58f0f45b23d7ffe7769e1154a2c1420243b311";
    hash = "sha256-BUdkbD2FlAPg1So2kakGCpufKReQCnHkFBjmv0dZmr0=";
  };

  nativeBuildInputs = [ go ];

  env = {
    CGO_ENABLED = 0;
    GO111MODULE = "off";
  };

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export GOCACHE="$TMPDIR/go-cache"
    go build -trimpath -ldflags="-s -w" -o wujie14xCC ./wujie14xCC.go

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 wujie14xCC "$out/bin/wujie14xCC"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/wujie14xCC" -h >/dev/null 2>&1

    runHook postInstallCheck
  '';

  meta = {
    description = "ACPI control utility for MECHREVO WUJIE 14X laptops";
    homepage = "https://github.com/LongSang01/wujie14X-Linux-Driver";
    # Upstream provides no license for the standalone utility.
    license = lib.licenses.unfree;
    mainProgram = "wujie14xCC";
    platforms = [ "x86_64-linux" ];
  };
}
