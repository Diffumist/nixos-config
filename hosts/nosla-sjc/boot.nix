{
  imports = [
    (import ../../profiles/hardware/ephemeral-btrfs.nix {
      device = "/dev/sda";
      swapSize = "512M";
    })
  ];
}
