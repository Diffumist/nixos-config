{ inputs, self }:
let
  inherit (inputs.nixpkgs.lib) mapAttrs;
  deployConfigurations = import ./default.nix {
    inherit inputs self;
    hostFilter = _: h: h.deploy or false;
  };
  mkNode =
    name:
    let
      cfg = deployConfigurations.${name};
      # `pkgs.system` is deprecated in favor of `pkgs.stdenv.hostPlatform.system`.
      system =
        if cfg ? pkgs && cfg.pkgs ? stdenv && cfg.pkgs.stdenv ? hostPlatform then
          cfg.pkgs.stdenv.hostPlatform.system
        else
          throw "deploy: cannot determine system for host '${name}'";
    in
    {
      hostname = name;
      profiles.system.path = inputs.deploy-rs.lib.${system}.activate.nixos cfg;
      user = "root";
      sshUser = "root";
      fastConnection = true;
      # DEBUG
      autoRollback = false;
      magicRollback = false;
      interactiveSudo = false;
    };
in
{
  nodes = mapAttrs (name: _: mkNode name) deployConfigurations;
}
