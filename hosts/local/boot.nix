{ lib, config, pkgs, ... }:
{
  boot.initrd = {
    availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "rtsx_pci_sdmmc" ]; # only loaded on demand
    kernelModules = [ "i915" ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_5_14;
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "snd-intel-dspcfg.dsp_driver=1" # enable legacy DSP driver
      "mitigations=off"
      "nvidia-drm.modeset=1"
      "intel_iommu=on"
      "iommu=pt"
      "quiet"
    ];
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "kernel.panic" = 10;
      "vm.swappiness" = 10;
      "net.ipv4.ip_forward" = 1;
    };
    extraModprobeConfig = ''
      options i915 enable_guc=2
      options i915 enable_fbc=1
      options i915 fastboot=1
      options kvm_intel nested=1
    '';
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 1;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems =
    let
      espDev = "/dev/disk/by-uuid/E245-3FCF"; # EFI System Partition
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
  # swapfile
  swapDevices = [
    {
      device = "/var/swapfile/swapfile";
    }
  ];

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
