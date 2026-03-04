{
  lib,
  stdenv,
  fetchurl,
  ...
}:

let
  pname = "cli-proxy-api";
  version = "6.8.39";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_amd64.tar.gz";
      sha256 = "91ef258d02559a10084a01218931a2244819cee02e53f1ed101ee4101bb1f240";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_arm64.tar.gz";
      sha256 = "f46abe2ef160e63b693a8a0c16b7fe058f7dfc832ff6ba1377c448c42be3f614";
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
      "aarch64-linux"
    ];
    mainProgram = "cli-proxy-api";
  };
}
