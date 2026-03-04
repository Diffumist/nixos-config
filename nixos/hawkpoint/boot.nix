{
  config,
  lib,
  pkgs,
  ...
}:
{
  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "uas"
        "sd_mod"
      ];
    };
    extraModulePackages = [
      config.boot.kernelPackages.acpi_call
      config.boot.kernelPackages.tuxedo-drivers
      config.boot.kernelPackages.yt6801
    ];
    kernelModules = [
      "kvm-amd"
      "acpi_call"
      "tuxedo-drivers"
      "yt6801"
    ];
    kernelParams = lib.mkAfter [
      # hardware
      "acpi.ec_no_wakeup=1"
      "amdgpu.dcdebugmask=0x12"
      "mt7921e.disable_aspm=1"
    ];
    kernel.sysctl = {

    };
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 7;
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;
  };

  fileSystems =
    let
      uuid = "0c926c27-fbb4-4153-ab93-a6d81f8257a9";

      mkBtrfs = subvol: opts: {
        device = "/dev/disk/by-uuid/${uuid}";
        fsType = "btrfs";
        neededForBoot = true;
        options = [
          "subvol=${subvol}"
          "space_cache=v2"
          "noatime"
        ]
        ++ opts;
      };
    in
    {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=25%"
          "mode=755"
        ];
      };

      "/home" = mkBtrfs "@home" [ "compress-force=zstd:-5" ];
      "/nix" = mkBtrfs "@nix" [ "compress-force=zstd:-5" ];
      "/persist" = mkBtrfs "@persist" [ "compress-force=zstd:-5" ];
      "/.swap" = mkBtrfs "@swap" [ ];

      "/.subvols" = {
        device = "/dev/disk/by-uuid/${uuid}";
        fsType = "btrfs";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/BD1C-DEDA";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
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
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };
  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];
}
