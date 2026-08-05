{
  imports = [
    (import ../../profiles/hardware/ephemeral-btrfs.nix {
      device = "/dev/vda";
      swapSize = "6144M";
    })
  ];
}
