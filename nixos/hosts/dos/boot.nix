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

  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  swapDevices = [{ device = "/var/swapfile"; size = 1024; }];
}
