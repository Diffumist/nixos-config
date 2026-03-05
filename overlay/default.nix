inputs: final: prev:
let
  lib = prev.lib;
  pkgsDir = ../pkgs;
  pkgDirs = lib.filterAttrs (_name: ty: ty == "directory") (builtins.readDir pkgsDir);
  importedPkgs = lib.mapAttrs (
    name: _ty:
    final.callPackage (pkgsDir + "/${name}") {
      inherit inputs;
    }
  ) pkgDirs;
in
importedPkgs
// {
  wemeet = prev.wemeet.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      substituteInPlace $out/share/applications/wemeetapp.desktop \
        --replace "Exec=wemeet" "Exec=wemeet-xwayland"
    '';
  });
  code-nautilus = prev.code-nautilus.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      substituteInPlace $out/share/nautilus-python/extensions/code-nautilus.py \
        --replace "VSCODE = 'code'" "VSCODE = 'codium'"
    '';
  });
  # stable-package = inputs.nixpkgs-stable.legacyPackages.${prev.system}.some-package;
}
