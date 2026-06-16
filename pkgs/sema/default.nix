{
  lib,
  rustPlatform,
  ...
}:

rustPlatform.buildRustPackage {
  pname = "sema";
  version = "0.1.0";

  # Local in-tree source; keep only what the build needs so target/ and the
  # local sema.toml/state don't bust the derivation hash.
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Small dead man's switch webhook server";
    license = lib.licenses.mit;
    mainProgram = "sema";
    platforms = lib.platforms.linux;
  };
}
