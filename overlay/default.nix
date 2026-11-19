inputs: final: prev:
let
  inherit (prev) lib;
  localPackages = import ../pkgs { inherit lib; };
  importedPkgs = localPackages.fromPkgs final inputs;
in
importedPkgs
// {
  devin-cli = prev.devin-cli.overrideAttrs (
    finalAttrs: oldAttrs: {
      version = "3000.14.30821";
      src = final.fetchurl {
        url = lib.replaceStrings [ oldAttrs.version ] [ finalAttrs.version ] oldAttrs.src.url;
        hash =
          {
            x86_64-linux = "sha256-TcQ+PkOIus5g/iqoAQy7OZQC5ySJLXF1hFsc3vAOfds=";
            aarch64-linux = "sha256-PeuK9rAmBg6XXtNxk24TmBgCDl3Fq7y6B83gOfRzpaU=";
            aarch64-darwin = "sha256-Ru8addi9hRZlF54Ta345rVl9PXkTuV1n/SuI6civAGE=";
          }
          .${final.stdenv.hostPlatform.system};
      };
    }
  );
  nix-update = prev.nix-update.overrideAttrs (oldAttrs: {
    patches =
      (oldAttrs.patches or [ ])
      ++ lib.optional (oldAttrs.version == "1.16.0") (
        prev.fetchpatch {
          name = "nix-update-prefetch-lazy-flake-sources.patch";
          url = "https://github.com/Mic92/nix-update/commit/d545c1fad667e573128cad0db55fdc77134a4d3c.patch";
          hash = "sha256-CVSihQevWIwKSnjKo9ilw1hdi4a1t0xr6DunAUKSBFA=";
        }
      );
  });
  microfetch = prev.microfetch.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [ ./microfetch/storage.patch ];
  });
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
  rimsort = inputs.rimsort.packages.${prev.stdenv.hostPlatform.system}.rimsort;
  # stable-package = inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}.some-package;
}
