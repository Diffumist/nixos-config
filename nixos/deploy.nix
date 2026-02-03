inputs:
let
  inherit (inputs.nixpkgs.lib) mapAttrs;
  nodeNames = builtins.attrNames inputs.self.nixosConfigurations;
  mkNode = name: {
    hostname = name;
    profiles.system.path =
      inputs.deploy-rs.lib.x86_64-linux.activate.nixos
        inputs.self.nixosConfigurations.${name};
    user = "root";
    fastConnection = true;
  };
in
{
  nodes = mapAttrs (name: _: mkNode name) inputs.self.nixosConfigurations;
}
