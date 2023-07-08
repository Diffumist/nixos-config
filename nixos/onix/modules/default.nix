{ ... }: {
  imports = [
    # env
    (import ./clash.nix)
    (import ./gnome.nix)
    (import ../../mist/modules/nix-config.nix)
    (import ../../mist/modules/common.nix)
  ];
}