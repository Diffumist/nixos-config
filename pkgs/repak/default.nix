{
  lib,
  rustPlatform,
  sources,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "repak";
  version = lib.removePrefix "v" sources.repak.version;

  inherit (sources.repak) src;

  cargoLock = sources.repak.cargoLock."Cargo.lock";

  cargoBuildFlags = [ "--package" "repak_cli" ];

  meta = {
    description = "Unreal Engine .pak file library and CLI";
    homepage = "https://github.com/trumank/repak";
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = "repak";
    platforms = lib.platforms.linux;
  };
})
