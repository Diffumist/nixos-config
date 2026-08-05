{
  bashInteractive,
  fetchFromGitHub,
  lib,
  readline,
  rustPlatform,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "flyline";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "HalFrgrd";
    repo = "flyline";
    rev = "v${finalAttrs.version}";
    hash = "sha256-o8ncjjnnyZIEb7qfnD6yY6YFq6JdppT+lKkVWZfdVdo=";
  };

  cargoHash = "sha256-Nc1v70Z/jgnvCDVEE4gK9lakZ/YEnkEtYc+EfwwLa9E=";

  buildInputs = [ readline ];

  RUSTFLAGS = [
    "-C link-arg=-lreadline"
    "-C link-arg=-lhistory"
  ];

  # Upstream integration tests require Docker and a Bash version matrix.
  cargoTestFlags = [ "--lib" ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ bashInteractive ];
  installCheckPhase = ''
    runHook preInstallCheck

    bash --noprofile --norc -i -c \
      'enable -f '"$out"'/lib/bash/libflyline.so flyline; flyline --version'

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
