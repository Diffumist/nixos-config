{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "xsz";
  version = "0.5.3";

  src = fetchFromGitHub {
    owner = "SaltyKitkat";
    repo = "xsz";
    rev = "v${finalAttrs.version}";
    hash = "sha256-QMdO6fTUaC8H9jINVQirOnfKNyqcWZ2rRqAd1D43udY=";
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
