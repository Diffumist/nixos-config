{ pkgs, lib, ... }:

let
  nbPython = pkgs.python312.withPackages (ps: [
    ps.uv
    ps.pip
    ps.virtualenv
  ]);

  nbRuntime = pkgs.symlinkJoin {
    name = "nb-runtime";
    paths = [
      pkgs.nb-cli
      nbPython
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nb \
        --prefix PATH : ${lib.makeBinPath [ nbPython ]}
    '';
  };
in
{
  environment.systemPackages = [
    nbRuntime
  ];
}
