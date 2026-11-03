{
  buildGoModule,
  iperf3,
  lib,
  makeWrapper,
  ...
}:

buildGoModule {
  pname = "netfit";
  version = "0.4.1";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      ./cmd
      ./internal
      ./README.md
    ];
  };

  subPackages = [ "cmd/netfit" ];
  vendorHash = "sha256-fcolwoy/Aft/eS/9lgn22L4/z+A1ml4Pfq9FmRnAN+A=";

  env.CGO_ENABLED = 0;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/netfit \
      --prefix PATH : ${lib.makeBinPath [ iperf3 ]}
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/netfit --help >/dev/null
    $out/bin/netfit version | grep -q '^netfit 0.4.1$'

    runHook postInstallCheck
  '';

  meta = {
    description = "Read-only adaptive TCP tuning recommendation tool";
    license = lib.licenses.mit;
    mainProgram = "netfit";
    platforms = lib.platforms.linux;
  };
}
