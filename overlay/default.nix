inputs: final: prev:
let
  inherit (prev) lib;
  localPackages = import ../pkgs { inherit lib; };
  importedPkgs = localPackages.fromPkgs final inputs;
in
importedPkgs
// {
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
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (_: pythonPrev: {
      anyio = pythonPrev.anyio.overridePythonAttrs (oldAttrs: {
        # Python 3.12.15 rejects client-only TLS arguments in server-side tests.
        patches =
          (oldAttrs.patches or [ ])
          ++ lib.optionals (pythonPrev.python.pythonVersion == "3.12" && oldAttrs.version == "4.14.2") [
            ./anyio/server-hostname.patch
          ];
      });
    })
  ];
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
// lib.optionalAttrs (prev ? cachyosKernels) {
  cachyosKernels = prev.cachyosKernels // {
    linuxPackages-cachyos-latest-lto-zen4 =
      prev.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4.extend
        (
          _: kernelPrev: {
            yt6801 = kernelPrev.yt6801.overrideAttrs (oldAttrs: {
              makeFlags = (oldAttrs.makeFlags or [ ]) ++ [
                "CC=cc"
                "LLVM=1"
              ];
            });
          }
        );
  };
}
