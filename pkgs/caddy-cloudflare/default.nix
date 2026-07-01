{
  cacert,
  caddy,
  caddy-dns-cloudflare,
  git,
  go,
  stdenv,
  xcaddy,
  ...
}:

let
  version = "2.11.4";
  cloudflarePlugin = "github.com/caddy-dns/cloudflare@v${caddy-dns-cloudflare.version}";
in
caddy.overrideAttrs (oldAttrs: {
  pname = "caddy-cloudflare";
  inherit version;

  src = stdenv.mkDerivation {
    pname = "caddy-cloudflare-src";
    inherit version;
    url = "https://github.com/caddyserver/caddy";
    rev = "v${version}";

    nativeBuildInputs = [
      go
      xcaddy
      cacert
      git
    ];

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild

      export GOCACHE=$TMPDIR/go-cache
      export GOPATH="$TMPDIR/go"
      XCADDY_SKIP_BUILD=1 TMPDIR="$PWD" xcaddy build v${version} --with ${cloudflarePlugin}
      (cd buildenv* && go mod vendor)

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mv buildenv* "$out"
      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
  };

  vendorHash = null;
  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];

  postInstallCheck = (oldAttrs.postInstallCheck or "") + ''
    $out/bin/caddy build-info | grep -F github.com/caddy-dns/cloudflare >/dev/null
  '';

  __intentionallyOverridingVersion = true;
})
