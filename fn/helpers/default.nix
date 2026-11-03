{ lib }:
{
  lists = import ./lists.nix { inherit lib; };
  network = import ./network.nix { inherit lib; };
  postgresql = import ./postgresql.nix { inherit lib; };
  systemd = import ./systemd.nix { inherit lib; };
}
