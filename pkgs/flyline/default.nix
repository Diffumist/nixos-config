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
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "HalFrgrd";
    repo = "flyline";
    rev = "v${finalAttrs.version}";
    hash = "sha256-nOCawyqUdOkxaqFS11Tp9IaOm7hevWhnLjpxsr5YWCo=";
  };

  cargoHash = "sha256-4ifX9N1OnIxwNRy4rWBZSqE0460G/dx+N8N4ZHInBpk=";

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
