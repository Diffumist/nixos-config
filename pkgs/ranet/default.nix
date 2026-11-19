{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ranet";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = "ranet";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WqoGIK0bIBgOFd8EkfiwGxDdEQhXdxxfup1ObIuK/c0=";
  };

  cargoHash = "sha256-9egoV3yUgpmP5rajWJWAp5uy4zG+/zGzKsS72eyT4EI=";

  # Upstream skips this DNS-dependent snapshot in Nix builds.
  checkFlags = [ "--skip=address::test::remote" ];

  meta = {
    description = "Configure a full mesh of IPsec tunnels with strongSwan";
    homepage = "https://github.com/NickCao/ranet";
    license = lib.licenses.mit;
    mainProgram = "ranet";
    platforms = lib.platforms.linux;
  };
})
