{
  lib,
  pkgsDir ? ./.,
}:

let
  packageDirs = lib.filterAttrs (_: ty: ty == "directory") (builtins.readDir pkgsDir);
  packageNames = lib.attrNames packageDirs;
  updateablePackageNames = [
    "apple-emoji-font"
    "cloudflare-ip-ranges"
    "cybergroupmate"
    "flyline"
    "komari-monitor"
    "magpie"
    "ranet"
    "tel42verifier"
    "wu"
    "xsz"
  ];
in
{
  inherit packageNames updateablePackageNames;

  fromPkgs = pkgs: lib.genAttrs packageNames (name: pkgs.callPackage (pkgsDir + "/${name}") { });
}
