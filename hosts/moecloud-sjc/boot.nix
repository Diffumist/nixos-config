{
  imports = [
    (import ../../profiles/hardware/ephemeral-btrfs.nix {
      device = "/dev/sda";
      persistTmpfiles = [ "d /persist/var/storage 0755 root root -" ];
    })
  ];
}
