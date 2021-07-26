{ stdenvNoCC, lib, source }:

stdenvNoCC.mkDerivation rec {
  inherit (source) pname version src;

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
