{
  lib,
  pkgsDir ? ./.,
}:

let
  packageDirs = lib.filterAttrs (name: ty: ty == "directory" && name != "_sources") (
    builtins.readDir pkgsDir
  );
  packageNames = lib.attrNames packageDirs;
  updateablePackageNames = [
    "apple-emoji-font"
    "bub"
    "caddy-cloudflare"
    "caddy-dns-cloudflare"
    "cybergroupmate"
    "tel42verifier"
    "xsz"
  ];
in
{
  inherit packageNames updateablePackageNames;

  fromPkgs =
    pkgs: inputs:
    lib.genAttrs packageNames (name: pkgs.callPackage (pkgsDir + "/${name}") { inherit inputs; });
}
