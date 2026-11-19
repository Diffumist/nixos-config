{
  bashInteractive,
  fetchFromGitHub,
  lib,
  readline,
  rustPlatform,
  util-linux,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "flyline";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "HalFrgrd";
    repo = "flyline";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ZK8qhsQ6FFCzGSQ/eaT/l3zSYe2UP/v/bmv8zPNwgTs=";
  };

  cargoHash = "sha256-HP03rAvGZDEQIWKGOtOdGISbU6LNJhI3eyE2GzYFcW8=";

  buildInputs = [ readline ];

  RUSTFLAGS = [
    "-C link-arg=-lreadline"
    "-C link-arg=-lhistory"
  ];

  # Upstream integration tests require Docker and a Bash version matrix.
  cargoTestFlags = [ "--lib" ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    bashInteractive
    util-linux
  ];
  installCheckPhase = ''
    runHook preInstallCheck

    # Version reporting queries terminal capabilities and needs a controlling TTY.
    script --quiet --return --command \
      "bash --noprofile --norc -i -c 'enable -f $out/lib/bash/libflyline.so flyline && flyline --version'" \
      "$TMPDIR/flyline-version.log"
    grep -F "flyline ${finalAttrs.version}" "$TMPDIR/flyline-version.log"

    runHook postInstallCheck
  '';

  installPhase = ''
    runHook preInstall

    libPath="$(find target -name libflyline.so -type f -print -quit)"
    test -n "$libPath"
    install -Dm755 "$libPath" "$out/lib/bash/libflyline.so"

    runHook postInstall
  '';

  meta = {
    description = "Bash loadable builtin for a modern line editing experience";
    homepage = "https://github.com/HalFrgrd/flyline";
    license = with lib.licenses; [
      gpl3Only
      mit
    ];
    platforms = lib.platforms.linux;
  };
})
