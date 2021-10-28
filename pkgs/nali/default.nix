{ lib, source, buildGoModule }:

buildGoModule rec {
  inherit (source) pname version src;

  vendorSha256 = "Kb2T+zDUuH+Rx8amYsTIhR5L3DIx5nGcDGqxHOn90NU=";

  subPackages = [ "." ];
  runVend = true;
  meta = with lib; {
    description = "An offline tool for querying IP geographic information and CDN provider.";
    homepage = "https://github.com/zu1k/nali";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}