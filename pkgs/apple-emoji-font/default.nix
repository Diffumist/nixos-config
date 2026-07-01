{
  fetchurl,
  lib,
  stdenvNoCC,
  zstd,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "apple-emoji-font";
  version = "macos-26-20260613-f1fc560b";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-ttf/releases/download/${finalAttrs.version}/ttf-apple-emoji.pkg.tar.zst";
    hash = "sha256-BHpZhmZ9AYEyOXnU2W5XOw9Kp5CcvG9g3dQmfxrnRhs=";
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
