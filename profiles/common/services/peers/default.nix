{
  config,
  hostName,
  lib,
  ...
}:
let
  # <node>/<peer>.nix: one directory per node, named by the first label of
  # its endpoint (sjc-0), and one file per peer, named by the peer.
  node = lib.findFirst (node: node.hostName == hostName) null (
    lib.attrValues config.my.services.dn42.mesh.nodes
  );
  dir = ./. + "/${lib.head (lib.splitString "." node.endpoint)}";
in
{
  my.services.dn42.peers = lib.optionalAttrs (node != null && builtins.pathExists dir) (
    lib.mapAttrs' (
      file: _: lib.nameValuePair (lib.removeSuffix ".nix" file) (import (dir + "/${file}"))
    ) (builtins.readDir dir)
  );
}
