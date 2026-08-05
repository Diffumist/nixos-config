{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "xsz";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "SaltyKitkat";
    repo = "xsz";
    rev = "v${finalAttrs.version}";
    hash = "sha256-UdG7OpDmOfp6avJhTspiyqNlyuxw7NKaEjqfHQeAeeA=";
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
