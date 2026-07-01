{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "caddy-dns-cloudflare";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "caddy-dns";
    repo = "cloudflare";
    rev = "v${finalAttrs.version}";
    hash = "sha256-0Csi6WmyoGj7bXeo2Lrnwr0SCoV6c/niymtOp5DdiT4=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    cp -r . "$out"
    runHook postInstall
  '';

  meta = {
    description = "Cloudflare DNS provider module for Caddy";
    homepage = "https://github.com/caddy-dns/cloudflare";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
