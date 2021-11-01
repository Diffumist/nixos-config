{ lib, source, buildGoModule }:

buildGoModule rec {
  inherit (source) pname version src;

  vendorSha256 = "nOHwXGWD5uRTuflL2pCUDOdl/JaNIunRCplpaYEdF58=";

  subPackages = [ "." ];
  runVend = true;
  meta = with lib; {
    description = "An offline tool for querying IP geographic information and CDN provider.";
    homepage = "https://github.com/zu1k/nali";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
