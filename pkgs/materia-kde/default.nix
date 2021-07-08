{ source, lib, stdenv }:

stdenv.mkDerivation rec {
  inherit (source) pname version src;

  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "The diffumist's fork for materia-kde";
    homepage = "https://github.com/diffumist/materia-kde";
    license = licenses.gpl3;
    maintainers = [ maintainers.diffumist ];
    platforms = platforms.all;
  };
}
