inputs: final: prev:
let
  lib = prev.lib;
  pkgsDir = ../pkgs;
  sources = import (pkgsDir + "/_sources/generated.nix") {
    inherit (prev)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };
  pkgDirs = lib.filterAttrs (name: ty: ty == "directory" && name != "_sources") (
    builtins.readDir pkgsDir
  );
  importedPkgs = lib.mapAttrs (
    name: _ty:
    final.callPackage (pkgsDir + "/${name}") {
      inherit inputs sources;
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
  caddy-cloudflare = prev.caddy.withPlugins {
    plugins = [
      "github.com/caddy-dns/cloudflare@v0.2.4"

    ];
    hash = "sha256-8yZDrejNKsaUnUaTUFYbarWNmxafqp2z2rWo+XRsxV8=";
  };
  code-nautilus = prev.code-nautilus.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      substituteInPlace $out/share/nautilus-python/extensions/code-nautilus.py \
        --replace "VSCODE = 'code'" "VSCODE = 'codium'"
    '';
  });
  # stable-package = inputs.nixpkgs-stable.legacyPackages.${prev.system}.some-package;
}
