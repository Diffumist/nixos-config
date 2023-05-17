{ lib, source, stdenv }:

stdenv.mkDerivation {
  inherit (source) pname version src;
  phases = [ "installPhase" ];
  installPhase = ''
    install -D -m755 $src/Country.mmdb $out/Country.mmdb
    install -D -m755 $src/geoip.dat $out/geoip.dat
  '';

  meta = with lib; {
    description = "Maxmind GeoIP database";
    homepage = "https://github.com/Dreamacro/maxmind-geoip";
    license = licenses.unfree;
  };
}
