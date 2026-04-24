inputs: final: prev:
let
  lib = prev.lib;
  pkgsDir = ../pkgs;
  sources = import (pkgsDir + "/_sources/generated.nix") {
    inherit (prev) fetchgit fetchurl fetchFromGitHub dockerTools;
  };
  pkgDirs = lib.filterAttrs (name: ty: ty == "directory" && name != "_sources") (builtins.readDir pkgsDir);
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
  code-nautilus = prev.code-nautilus.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      substituteInPlace $out/share/nautilus-python/extensions/code-nautilus.py \
        --replace "VSCODE = 'code'" "VSCODE = 'codium'"
    '';
  });
  memos = prev.memos.overrideAttrs (
    oldAttrs:
    let
      version = "0.27.1";
      src = prev.fetchFromGitHub {
        owner = "usememos";
        repo = "memos";
        rev = "v${version}";
        hash = "sha256-HEQeMsUVvmrnW3pvTzMGIlCl8B9UuwnlyU8U0r1aRSc=";
      };
      memos-web = oldAttrs.memos-web.overrideAttrs (_: {
        inherit version src;
        pnpmDeps = prev.fetchPnpmDeps {
          pname = "memos-web";
          inherit version src;
          sourceRoot = "${src.name}/web";
          fetcherVersion = 3;
          hash = "sha256-NTPP9nHAtiTmIUpchxAvWLN6s99UKVXF7E+Z4JpiFT8=";
        };
        pnpmRoot = "web";
        nativeBuildInputs = [
          prev.nodejs
          prev.pnpmConfigHook
          prev.pnpm
        ];
        buildPhase = ''
          runHook preBuild
          pnpm -C web build
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          cp -r web/dist $out
          runHook postInstall
        '';
      });
    in
    {
      inherit version src memos-web;
      vendorHash = "sha256-QNJosdRo1DauCOGFB+GrasSoKSmRhc3EjRfjm4TG0Jo=";
      preBuild = ''
        rm -rf server/router/frontend/dist
        cp -r ${memos-web} server/router/frontend/dist
      '';
      ldflags = (oldAttrs.ldflags or [ ]) ++ [
        "-X github.com/usememos/memos/internal/version.Version=${version}"
      ];
      doCheck = false;
      meta = oldAttrs.meta // {
        changelog = "https://github.com/usememos/memos/releases/tag/v${version}";
      };
    }
  );
  codex-cli = inputs.codex-cli-nix.packages.${prev.stdenv.hostPlatform.system}.default;
  # stable-package = inputs.nixpkgs-stable.legacyPackages.${prev.system}.some-package;
}
