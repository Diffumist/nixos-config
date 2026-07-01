{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "xsz";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "SaltyKitkat";
    repo = "xsz";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ujAwKK9yZI+jHtqoavir0pluuKWD6TCG/t1KzF7H9P0=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Multi-threaded Btrfs compression analysis tool";
    homepage = "https://github.com/SaltyKitkat/xsz";
    license = lib.licenses.gpl2Only;
    mainProgram = "xsz";
    platforms = lib.platforms.linux;
  };
})
