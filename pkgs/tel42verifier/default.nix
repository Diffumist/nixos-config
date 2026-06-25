{
  lib,
  buildGoModule,
  sources,
  ...
}:

buildGoModule rec {
  pname = "tel42verifier";
  version = lib.removePrefix "v" sources.tel42verifier.version;

  inherit (sources.tel42verifier) src;

  subPackages = [ "cmd/tel42verifier" ];

  vendorHash = "sha256-kS1oS7I1jGTJn1jpId8MwsPd/v+0NOpayUNWfZZHaRQ=";

  ldflags = [
    "-s"
    "-w"
    "-X"
    "main.Version=v${version}"
  ];

  env.CGO_ENABLED = 0;

  postInstall = ''
    install -Dm644 config.yaml $out/share/examples/tel42verifier/enum_config.yaml
    install -Dm644 README.md $out/share/doc/tel42verifier/README.md
  '';

  meta = {
    description = "Asterisk AGI helper for Telephony42 Caller ID verification via DNS ENUM";
    homepage = "https://github.com/strexp/tel42verifier";
    license = lib.licenses.mit;
    mainProgram = "tel42verifier";
    platforms = lib.platforms.linux;
  };
}
