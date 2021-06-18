{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "materia-kde-theme";
  version = "20210612";

  src = fetchFromGitHub {
    owner = "diffumist";
    repo = "materia-kde";
    rev = version;
    sha256 = "";
  };

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "A port of the materia theme for Plasma";
    homepage = "https://git.io/materia-kde";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.diffumist ];
    platforms = lib.platforms.all;
  };
}