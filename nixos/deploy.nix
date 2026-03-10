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
      # nixosSystem 的返回通常既有 `system` 也有 `pkgs.system`；这里做兼容兜底
      system =
        if cfg ? pkgs && cfg.pkgs ? system then
          cfg.pkgs.system
        else if cfg ? system then
          cfg.system
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
