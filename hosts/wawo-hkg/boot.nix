{
  imports = [
    (import ../../profiles/hardware/ephemeral-btrfs.nix {
      device = "/dev/vda";
      swapSize = "512M";
    })
  ];
}
