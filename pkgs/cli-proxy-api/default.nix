{
  lib,
  stdenv,
  fetchurl,
  ...
}:

let
  pname = "cli-proxy-api";
  version = "6.9.24";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_amd64.tar.gz";
      hash = "sha256-n6UtlJS/wtYePQcLF19TDsxIaebnhXncmoKDe5bMeqE=";
    };
  };

in
stdenv.mkDerivation {
  inherit pname version;

  src =
    srcs.${stdenv.hostPlatform.system}
      or (throw "Unsupported architecture: ${stdenv.hostPlatform.system}");

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
