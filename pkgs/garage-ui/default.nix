{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  go-swag,
  makeWrapper,
  nodejs_24,
  ...
}:

let
  version = "0.11.3";

  src = fetchFromGitHub {
    owner = "Noooste";
    repo = "garage-ui";
    rev = "v${version}";
    hash = "sha256-ABJcdrONwAtBSvSvlL81sZUlZIfJVlleo1OtQojWaI4=";
  };

  frontend = buildNpmPackage {
    pname = "garage-ui-frontend";
    inherit version src;

    sourceRoot = "${src.name}/frontend";
    nodejs = nodejs_24;
    npmDepsFetcherVersion = 2;
    npmDepsHash = "sha256-/1tsc+xBvDQn+yU4tzuriP9ygmJpgDiCOqO305e55vM=";

    postPatch = ''
      # Upstream omits registry metadata that Nix needs for offline installation.
      cp ${./package-lock.json} package-lock.json
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r dist/. $out/

      runHook postInstall
    '';
  };
in
buildGoModule {
  pname = "garage-ui";
  inherit version src;

  modRoot = "backend";
  vendorHash = "sha256-w1ESuQkFw10X3v/L4iHq6DwxCc9Wbu6h/ujzJqHOipM=";

  nativeBuildInputs = [
    go-swag
    makeWrapper
  ];

  preBuild = ''
    swag init
  '';

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  postInstall = ''
    mkdir -p $out/share/garage-ui/frontend/dist
    cp -r ${frontend}/. $out/share/garage-ui/frontend/dist/

    wrapProgram $out/bin/garage-ui \
      --chdir $out/share/garage-ui
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/garage-ui --help
    test -f $out/share/garage-ui/frontend/dist/index.html

    runHook postInstallCheck
  '';

  meta = {
    description = "Web UI for managing a Garage object storage cluster";
    homepage = "https://github.com/Noooste/garage-ui";
    license = lib.licenses.mit;
    mainProgram = "garage-ui";
    platforms = lib.platforms.linux;
  };

  passthru = {
    inherit frontend;
  };
}
