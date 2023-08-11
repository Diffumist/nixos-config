{ ... }: {
  imports = [
    # env
    (import ./jellyfin.nix)
    (import ./samba.nix)
    (import ./syncthing.nix)
    (import ./nginx.nix)
    (import ./sshd.nix)
    (import ./transmission.nix)
    (import ../../mist/modules/nix-config.nix)
    (import ../../mist/modules/packages.nix)
  ];
}
