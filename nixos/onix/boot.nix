{ pkgs, ... }:
{
  boot.initrd = {
    availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usbhid"
      "ahci"
    ]; # only loaded on demand
    kernelModules = [ "amdgpu" ];
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_lqx;
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "kernel.panic" = 10;
    };
    kernelParams = [
      "i915.force_probe=!4908"
      "xe.force_probe=4908" # Xe Graphics For DG1
    ];
    enableContainers = false;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems =
    let
      espDev = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB512HBJQ-000L2_S4DYNF1M903404-part1"; # EFI System Partition
      btrfsDev = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB512HBJQ-000L2_S4DYNF1M903404-part2";

      btrfs = options: {
        device = btrfsDev;
        fsType = "btrfs";
        options = [
          "noatime"
          "space_cache=v2"
          "compress-force=zstd"
        ] ++ options;
        neededForBoot = true;
      };
    in
    {
      "/" = {
        fsType = "tmpfs";
        options = [
          "defaults"
          "mode=755"
        ];
      };
      "/.subvols" = btrfs [ ];
      "/home" = btrfs [ "subvol=@home" ];
      "/nix" = btrfs [ "subvol=@nix" ];
      "/.swap" = btrfs [ "subvol=@swap" ];
      "/persist" = btrfs [ "subvol=@persist" ];
      "/boot" = {
        device = espDev;
        fsType = "vfat";
      };
    };
  # swapfile
  swapDevices = [
    {
      device = "/.swap/rel-path";
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
