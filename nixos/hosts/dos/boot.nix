{ lib, pkgs, ... }:
{
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.kernelModules = [ "nvme" ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 30;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.ip_forward" = 1;
  };
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    blacklistedKernelModules = [ "ip_tables" ];
  };


  fileSystems =
    let
      btrfsDev = "/dev/disk/by-label/nixos";

      btrfs = options: {
        device = btrfsDev;
        fsType = "btrfs";
        options = [ "noatime" "compress-force=zstd" "space_cache=v2" ] ++ options;
        neededForBoot = true;
      };
      tmpfs = {
        fsType = "tmpfs";
        options = [ "defaults" "mode=755" ];
      };
    in
    {
      "/" = tmpfs;
      "/.subvols" = btrfs [ ];
      "/boot" = btrfs [ "subvol=boot" ];
      "/nix" = btrfs [ "subvol=nix" ];
      "/persist" = btrfs [ "subvol=persist" ];
    };

  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
      size = 2048; # MiB
    }
  ];

  environment.persistence."/persist" = {
    directories = [
      "/var/log"
      "/var/lib"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };
}
