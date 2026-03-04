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
  # gemini-cli-bin = prev.gemini-cli-bin.overrideAttrs (oldAttrs: {
  #   src = prev.fetchurl {
  #     url = "https://github.com/google-gemini/gemini-cli/releases/download/v0.30.0/gemini.js";
  #     hash = "sha256-N4pfjiaawx8kvaOFoQ53owJehD69fECJPpt5DxKVJ7k=";
  #   };
  #   installPhase = ''
  #     runHook preInstall

  #     install -D "$src" "$out/bin/gemini"

  #     # disable auto-update
  #     sed -i '/enableAutoUpdate: {/,/}/ s/default: true/default: false/' "$out/bin/gemini"

  #     # use `ripgrep` from `nixpkgs`, more dependencies but prevent downloading incompatible binary on NixOS
  #     # this workaround can be removed once the following upstream issue is resolved:
  #     # https://github.com/google-gemini/gemini-cli/issues/11438
  #     substituteInPlace $out/bin/gemini \
  #       --replace-fail 'const existingPath = await resolveExistingRgPath();' 'const existingPath = "${lib.getExe prev.ripgrep}";'

  #     runHook postInstall
  #   '';

  # });
  # stable-package = inputs.nixpkgs-stable.legacyPackages.${prev.system}.some-package;
}
