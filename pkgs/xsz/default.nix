{
  lib,
  rustPlatform,
  sources,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "xsz";
  version = lib.removePrefix "v" sources.xsz.version;

  inherit (sources.xsz) src;

  cargoLock = sources.xsz.cargoLock."Cargo.lock";

  meta = {
    description = "Multi-threaded Btrfs compression analysis tool";
    homepage = "https://github.com/SaltyKitkat/xsz";
    license = lib.licenses.gpl2Only;
    mainProgram = "xsz";
    platforms = lib.platforms.linux;
  };
})
