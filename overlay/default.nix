inputs: final: prev:
let
  inherit (prev) lib;
  localPackages = import ../pkgs { inherit lib; };
  importedPkgs = localPackages.fromPkgs final inputs;
in
importedPkgs
// {
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
  # stable-package = inputs.nixpkgs-stable.legacyPackages.${prev.system}.some-package;
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
