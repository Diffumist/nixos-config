{ ... }: {
  imports = [
    # env
    # (import ./clash.nix)
    (import ./gnome.nix)
    (import ./hardware.nix)
    (import ../../mist/modules/nix-config.nix)
    (import ../../mist/modules/packages.nix)
  ];
}