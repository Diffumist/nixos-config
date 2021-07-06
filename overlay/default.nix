self: super:

{
  materia-kde-theme = super.materia-kde-theme.overrideAttrs ({
    pname = "materia-kde-theme";
    version = "20210612";
    src = super.fetchgit {
      url = "https://github.com/diffumist/materia-kde";
      rev = "20210612";
      fetchSubmodules = false;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "";
    };
  });
}
