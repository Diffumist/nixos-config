{ inputs }:
final: prev:
let
  inherit (final) callPackage lib symlinkJoin;
  mkShellArgs =
    names: option:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = prev.${name}.override {
          commandLineArgs = lib.escapeShellArgs option;
        };
      }) names
    );
in
{
  fzf-fish = callPackage ../packages/shells/fish/fzf-fish.nix { };
}
# // mkShellArgs [
#   "chromium"
# ] []
