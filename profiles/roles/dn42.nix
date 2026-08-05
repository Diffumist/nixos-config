{ inputs, self, ... }:
{
  imports = [
    inputs.nix-dn42.nixosModules.default
    "${self}/modules/services/dn42/flap-damping.nix"
    "${self}/modules/services/dn42/mesh.nix"
    "${self}/modules/services/dn42/peer.nix"
    "${self}/profiles/common/services/dn42.nix"
    "${self}/profiles/common/services/dn42-peers.nix"
  ];
}
