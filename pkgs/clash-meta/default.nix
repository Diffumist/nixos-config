{ stdenvNoCC, source, }:
stdenvNoCC.mkDerivation {
  inherit (source) pname version src;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/clash.meta-linux-amd64.gz
    gzip --decompress $out/bin/clash.meta-linux-amd64.gz
    chmod +x $out/bin/clash.meta-linux-amd64
    mv $out/bin/clash.meta-linux-amd64 $out/bin/clash
  '';
}
