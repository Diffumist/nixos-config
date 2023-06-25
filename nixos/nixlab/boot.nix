{ lib, pkgs, ... }:
{
  powerManagement.cpuFreqGovernor = lib.mkForce "powersave";

  boot.initrd = {
    availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "ahci" ]; # only loaded on demand
    kernelModules = [ "i915" ];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages;
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
    ];
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "kernel.panic" = 10;
    };
    enableContainers = false;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  fileSystems =
    let
      espDev = "/dev/disk/by-uuid/3A93-EA9E"; # EFI System Partition
      btrfsDev = "/dev/disk/by-uuid/72b6906a-562f-4a52-9540-fd525abd0ddb";

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
      "/home" = {
        fsType = "tmpfs";
        options = [ "defaults" "mode=755" ];
      };
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
      "/etc/ssh/ssh_host_ed25519_key"
    ];
    users.diffumist = {
      directories = [
        "Downloads"
        "Music"
        "Pictures"
        "Documents"
        "Videos"
        "Other"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".local/share/keyrings"; mode = "0700"; }
        ".config"
        ".local"
        ".cache"
      ];
    };
  };
}
