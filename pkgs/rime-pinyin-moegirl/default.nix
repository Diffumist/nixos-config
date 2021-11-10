{ source, stdenv, lib }:
stdenv.mkDerivation {
  inherit (source) pname version src;
  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/share/rime-data/moegirl.dict.yaml
  '';
  meta = with lib; {
    description = "Fcitx 5 pinyin dictionary generator for MediaWiki instances";
    homepage = "https://github.com/outloudvi/mw2fcitx";
    license = licenses.unlicense;
  };
}
