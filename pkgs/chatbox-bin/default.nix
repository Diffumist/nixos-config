{ stdenv, source, lib, webkitgtk, makeWrapper, wrapGAppsHook, glib, glibc, gtk3, fontconfig, openssl_1_1, gdk-pixbuf, cairo, hicolor-icon-theme, pango }:
stdenv.mkDerivation rec {
  inherit (source) pname version src;
  deps = [
    webkitgtk
    glib
    glibc
    gtk3
    fontconfig
    openssl_1_1
    gdk-pixbuf
    pango
    cairo
    hicolor-icon-theme
  ];
  sourceRoot = ".";
  unpackCmd = ''
    ar p "$src" data.tar.gz | tar xz
  '';
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper wrapGAppsHook ];

  buildInputs = deps;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons
    cp -R usr/share $out/
    cp -R usr/bin $out/

    # fix the path in the desktop file
    substituteInPlace \
      $out/share/applications/chatbox.desktop \
      --replace /usr/ $out/
  '';

  preFixup = let
    packages = deps;
    libPathNative = lib.makeLibraryPath packages;
    libPath64 = lib.makeSearchPathOutput "lib" "lib64" packages;
    libPath = "${libPathNative}:${libPath64}";
  in ''
    # patch executable
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}:$out/bin/chatbox" \
      $out/bin/chatbox
  '';
}