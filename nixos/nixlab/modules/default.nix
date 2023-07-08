{ ... }: {
  imports = [
    # env
    (import ./jellyfin.nix)
    (import ./samba.nix)
    (import ./syncthing.nix)
    (import ./hardware.nix)
    (import ./nginx.nix)
    (import ./sshd.nix)
    (import ../../mist/modules/nix-config.nix)
    (import ../../mist/modules/common.nix)
  ];
}
