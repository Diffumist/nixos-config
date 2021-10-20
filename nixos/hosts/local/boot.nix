{ lib, config, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "rtsx_pci_sdmmc" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [ "kvm-intel" "qxl" "bochs_drm" ];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.extraModulePackages = with config.boot.kernelPackages; [
    (pkgs.linuxPackages_zen.nvidia_x11.override { inherit kernel; })
  ];
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.panic" = 10;
    "vm.swappiness" = 10;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  # Ref: https://thesofproject.github.io/latest/getting_started/intel_debug/introduction.html
  # Use HDaudio legacy drivers
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=1
  '';
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
      };
    in
    {
      "/" = btrfs [ "subvol=@" ];
      "/.subvols" = btrfs [ ];
      "/home" = btrfs [ "subvol=@home" ];
      "/nix" = btrfs [ "subvol=@nix" ];
      "/var/swapfile" = btrfs [ "subvol=@swap" ];
      "/boot" = {
        device = espDev;
        fsType = "vfat";
      };
    };

  swapDevices = [
    {
      device = "/var/swapfile/swapfile";
      size = 8192; # MiB
    }
  ];

  powerManagement.cpuFreqGovernor = "powersave";
}
