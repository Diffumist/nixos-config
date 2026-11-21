{
  cacert,
  fetchurl,
  lib,
  makeWrapper,
  openssl,
  stdenv,
  stdenvNoCC,
  unzip,
  zlib,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "agy-acp-server";
  version = "1.5.2";

  src = fetchurl {
    url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${finalAttrs.version}-linux-x86_64.zip";
    sha256 = "99dd8612450805011619d7b8447ce374c289e00549d8557f36790e1dd6256852";
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  # PyInstaller / .par archives append payload data to the ELF binary;
  # stripping or patching ELF headers corrupts the appended archive.
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  unpackPhase = ''
    runHook preUnpack

    mkdir -p unpacked
    unzip -q "$src" -d unpacked

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    par_path="$(find unpacked -name 'agy_acp_server.par' -type f -print -quit)"
    test -n "$par_path"
    pkg_dir="$(dirname "$par_path")"

    mkdir -p "$out/lib/agy-acp-server" "$out/bin"
    cp -r "$pkg_dir"/. "$out/lib/agy-acp-server/"
    chmod +x "$out/lib/agy-acp-server/agy_acp_server.par"
    if [ -f "$out/lib/agy-acp-server/localharness_external" ]; then
      chmod +x "$out/lib/agy-acp-server/localharness_external"
    fi

    makeWrapper "$out/lib/agy-acp-server/agy_acp_server.par" "$out/bin/agy-acp-server" \
      --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt" \
      --prefix NIX_LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          openssl
          stdenv.cc.cc.lib
          zlib
        ]
      }"

    runHook postInstall
  '';

  meta = {
    description = "Google Antigravity Agent Client Protocol (ACP) server";
    homepage = "https://antigravity.google/docs/ide/extensions";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "agy-acp-server";
    platforms = [ "x86_64-linux" ];
  };
})
