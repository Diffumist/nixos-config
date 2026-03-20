{
  lib,
  stdenvNoCC,
  fetchurl,
  zstd,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "apple-emoji-font";
  version = "2.0.0.20260219.2aa12422";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/macos-26-20260219-2aa12422/ttf-apple-emoji.pkg.tar.zst";
    hash = "sha256-bKP82lRDdnXo6lXNwa0G1MM7SFsE6t0OdHY/BAv5wCE=";
  };

  nativeBuildInputs = [ zstd ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    tar --zstd -xf "$src"
    runHook postUnpack
  '';

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm644 \
      usr/share/fonts/apple-color-emoji/apple-color-emoji.ttf \
      "$out/share/fonts/apple-color-emoji/apple-color-emoji.ttf"

    install -Dm644 \
      usr/share/fontconfig/conf.avail/75-apple-color-emoji.conf \
      "$out/share/fontconfig/conf.avail/75-apple-color-emoji.conf"

    mkdir -p "$out/etc/fonts/conf.d"
    ln -s \
      ../../../share/fontconfig/conf.avail/75-apple-color-emoji.conf \
      "$out/etc/fonts/conf.d/75-apple-color-emoji.conf"

    runHook postInstall
  '';

  meta = {
    description = "Apple Color Emoji font extracted from macOS";
    homepage = "https://github.com/samuelngs/apple-emoji-ttf";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
})
