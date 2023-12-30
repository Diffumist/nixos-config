{ source, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  phases = [ "installPhase" ];
  installPhase = ''
    install -D -m755 $src/geosite.dat $out/geosite.dat
    install -D -m755 $src/geoip.dat $out/geoip.dat
  '';
}
