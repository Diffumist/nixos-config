{
  fetchurl,
  lib,
  stdenvNoCC,
  ...
}:

let
  version = "Snapshot-2611090908";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/komari-monitor/komari/releases/download/${version}/komari-linux-amd64";
      hash = "sha256-cascHKRYkxHPzaz0zUy61s32a7lrmFn4s++UDhuslZA=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/komari-monitor/komari/releases/download/${version}/komari-linux-arm64";
      hash = "sha256-AGbLwj/yBJWyL3x6Qwm2UEyzIURKQFKWk5SC7xrA98M=";
    };
  };
  src = sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "komari-monitor";
  inherit version src;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/komari"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/komari" --help >/dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "Lightweight self-hosted server monitoring solution";
    homepage = "https://github.com/komari-monitor/komari";
    license = lib.licenses.mit;
    mainProgram = "komari";
    platforms = lib.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
