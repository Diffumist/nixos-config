{ lib, inputs, ... }:
let
  included = [
    "home-manager"
    "flake-utils"
    "rust-overlay"
  ];
in
{
  nixpkgs.config.allowUnfree = true;
  nix.registry = lib.genAttrs included (
    name: {
      from.type = "indirect";
      from.id = name;
      flake = inputs.${name};
    }
  );

  nix.nixPath = map (name: "${name}=inputs.${name}") included;
}
