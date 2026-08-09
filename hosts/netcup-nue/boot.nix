{
  imports = [
    (import ../../profiles/hardware/ephemeral-btrfs.nix {
      device = "/dev/vda";
      swapSize = "1024M";
      persistTmpfiles = [ "d /persist/var/storage 0755 root root -" ];
    })
  ];
}
