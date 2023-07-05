{ ... }: {
  imports = [
    # env
    (import ./jellyfin.nix)
    (import ./samba.nix)
    (import ./syncthing.nix)
    (import ./transmission.nix)
  ];
}
