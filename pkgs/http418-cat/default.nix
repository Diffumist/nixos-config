{
  lib,
  rustPlatform,
  ...
}:

rustPlatform.buildRustPackage {
  pname = "http418-cat";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./assets
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  installPhase = ''
    runHook preInstall

    generator="$(find target -path '*/release/http418-cat' -type f -print -quit)"
    test -n "$generator"
    "$generator" "$out"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    test -s "$out/index.html"
    test -s "$out/418.png"
    grep -q 'lang="ca"' "$out/index.html"
    grep -q 'Sóc una tetera' "$out/index.html"

    runHook postInstallCheck
  '';

  meta = {
    description = "Static 418.cat teapot cat landing page";
    homepage = "https://418.cat";
    platforms = lib.platforms.unix;
  };
}
