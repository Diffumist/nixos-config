{ lib, pkgs, ... }:
{
  boot.loader.grub.device = "/dev/vda";
  boot.initrd.kernelModules = [ "nvme" ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
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
    in
    {
      "/" = {
        fsType = "tmpfs";
        options = [ "defaults" "mode=755" ];
      };
      "/.subvols" = btrfs [ ];
      "/boot" = btrfs [ "subvol=boot" ];
      "/nix" = btrfs [ "subvol=nix" ];
      "/persist" = btrfs [ "subvol=persist" ];
      "/var/swapfile" = btrfs [ "subvol=swap" ];
    };

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

  powerManagement.cpuFreqGovernor = "ondemand";
}
