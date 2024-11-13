{ pkgs, ... }:
{
  fromYAML = builtins.fromJSON (
    builtins.readFile (
      pkgs.stdenv.mkDerivation {
        name = "fromYAML";
        phases = [ "buildPhase" ];
        buildPhase = "echo '${pkgs.yaml}' | ${pkgs.yaml2json}/bin/yaml2json > $out";
      }
    )
  );
  overrideSrc =
    {
      name,
      src ? null,
      patches ? [ ],
    }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          ${name} = (
            prev.${name}.overrideAttrs (
              finalAttrs: prevAttrs: {
                src = if src != null then src else prevAttrs.src;
                patches = (prevAttrs.patches or [ ]) ++ patches;
              }
            )
          );
        })
      ];
    };
}
