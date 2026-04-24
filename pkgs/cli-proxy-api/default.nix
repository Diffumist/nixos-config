{
  lib,
  stdenv,
  sources,
  ...
}:

stdenv.mkDerivation {
  inherit (sources.cli-proxy-api) pname version src;

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 cli-proxy-api $out/bin/cli-proxy-api
    runHook postInstall
  '';

  meta = with lib; {
    description = "Proxy server providing OpenAI/Gemini/Claude compatible API interfaces";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
    ];
    mainProgram = "cli-proxy-api";
  };
}
