{ lib, source, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  inherit (source) pname version src;
  phases = [ "installPhase" ];
  installPhase = ''
    install -D -m755 $src/Country.mmdb $out/Country.mmdb
  '';

  meta = with lib; {
    description = "Maxmind GeoIP database";
    homepage = "https://github.com/Dreamacro/maxmind-geoip";
    license = licenses.unfreeRedistributable;
  };
}
