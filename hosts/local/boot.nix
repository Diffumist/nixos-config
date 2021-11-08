{ lib, config, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "rtsx_pci_sdmmc" ]; # only loaded on demand
  boot.kernelPackages = pkgs.linuxPackages_xanmod;
  boot.extraModulePackages = with config.boot.kernelPackages; [
    (pkgs.linuxPackages_xanmod.nvidia_x11.override { inherit kernel; })
  ];
  # Ref: https://thesofproject.github.io/latest/getting_started/intel_debug/introduction.html
  # use legacy drivers
  boot.kernelParams = [ "snd-intel-dspcfg.dsp_driver=1" ];
  boot.blacklistedKernelModules = [ "ip_tables" ];
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.panic" = 10;
    "vm.swappiness" = 10;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  boot.supportedFilesystems = [ "ntfs-3g" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  fileSystems =
    let
      espDev = "/dev/disk/by-uuid/E245-3FCF";
      btrfsDev = "/dev/disk/by-label/NixOS";

      btrfs = options: {
        device = btrfsDev;
        fsType = "btrfs";
        options = [ "noatime" "space_cache=v2" "compress-force=zstd" ] ++ options;
        neededForBoot = true;
      };
    in
    {
      "/" = {
        fsType = "tmpfs";
        options = [ "defaults" "mode=755" ];
      };
      "/.subvols" = btrfs [ ];
      "/home" = btrfs [ "subvol=@home" ];
      "/nix" = btrfs [ "subvol=@nix" ];
      "/var/swapfile" = btrfs [ "subvol=@swap" ];
      "/persist" = btrfs [ "subvol=@persist" ];
      "/boot" = {
        device = espDev;
        fsType = "vfat";
      };
    };

  environment.persistence."/persist" = {
    directories = [
      "/var/log"
      "/var/lib"
      "/var/db"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  powerManagement.cpuFreqGovernor = "powersave";
}
