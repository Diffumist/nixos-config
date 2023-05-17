{ pkgs, ... }:
{
  boot.initrd = {
    availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "ahci" ]; # only loaded on demand
    kernelModules = [ "i915" ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages;
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
      "intel_iommu=on"
      "iommu=pt"
      "nowatchdog"
    ];
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "kernel.panic" = 10;
    };
    extraModprobeConfig = ''
      options i915 enable_guc=2
      options i915 enable_fbc=1
      options i915 fastboot=1
      blacklist ideapad_laptop
      options kvm_intel nested=1
    '';
    enableContainers = false;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems =
    let
      espDev = "/dev/disk/by-label/ESP_EFI"; # EFI System Partition
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
      "/var/swap" = btrfs [ "subvol=@swap" ];
      "/persist" = btrfs [ "subvol=@persist" ];
      "/boot" = {
        device = espDev;
        fsType = "vfat";
      };
    };
  # swapfile
  swapDevices = [
    {
      device = "/var/swap/swapfile";
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
