{ source, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  phases = [ "installPhase" ];
  installPhase = ''
    install -D -m755 $src/Country.mmdb $out/Country.mmdb
    install -D -m755 $src/geoip.dat $out/geoip.dat
  '';
}
