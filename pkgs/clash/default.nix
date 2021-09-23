{ stdenvNoCC, lib, fetchurl}:

stdenvNoCC.mkDerivation rec {
  pname = "clash";
  version = "2021.09.15";
  src = fetchurl {
    sha256 = "wYCyECiIwR5XIOfYxsdPswpxBlC3G//5ICdSFSNiteI=";
    url = "https://github.com/Dreamacro/clash/releases/download/premium/clash-linux-amd64-2021.09.15.gz";
  };

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir $out
    cp $src $out/clash.gz
    gzip --decompress $out/clash.gz
    install -Dm755 "$out/clash" "$out/bin/clash"
    rm $out/clash
  '';

  meta = with lib; {
    homepage = https://github.com/Dreamacro/clash;
    description = "Close-sourced pre-built Clash binary with TUN support and more";
    license = licenses.unfree;
  };
}
