inputs: final: prev:
let
  inherit (prev) lib;
  localPackages = import ../pkgs { inherit lib; };
  importedPkgs = localPackages.fromPkgs final;
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
  # Work around czerwonk/bird_exporter#169: BIRD2 socket prefixes the first
  # OSPF detail line with `1006-  Channel ipv4`, which 1.7.1's `^\s+Channel`
  # regex drops, making OSPF export fail with HTTP 500.
  prometheus-bird-exporter = prev.prometheus-bird-exporter.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "")
      + lib.optionalString (oldAttrs.version == "1.7.1") ''
        substituteInPlace parser/parser.go \
          --replace-fail \
            'channelRegex = regexp.MustCompile(`^\s+Channel (?:ipv|roa)(4|6)(?:\s|$)`)' \
            'channelRegex = regexp.MustCompile(`^(?:\d{4}-)?\s+Channel (?:ipv|roa)(4|6)(?:\s|$)`)'
      '';
  });
  wemeet = prev.wemeet.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      substituteInPlace $out/share/applications/wemeetapp.desktop \
        --replace-fail "Exec=wemeet" "Exec=wemeet-xwayland"
    '';
  });
  code-nautilus = prev.code-nautilus.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      substituteInPlace $out/share/nautilus-python/extensions/code-nautilus.py \
        --replace-fail "VSCODE = 'code'" "VSCODE = 'codium'"
    '';
  });
  rimsort = inputs.rimsort.packages.${prev.stdenv.hostPlatform.system}.rimsort;
}
