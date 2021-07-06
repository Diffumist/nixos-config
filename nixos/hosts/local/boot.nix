{ lib, config, pkgs, ... }:
{
  # Initrd.
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "rtsx_pci_sdmmc" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];

  # Kernel.
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    # exfat-nofuse
    acpi_call # For TLP
    (pkgs.linuxPackages.isgx.override { inherit kernel; })
  ];
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "kernel.panic" = 10;
    "vm.swappiness" = 10;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # For NTFS rw mount.
  boot.supportedFilesystems = [ "ntfs-3g" ];

  # Boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  # Filesystems.
  fileSystems =
    let
      espDev = "/dev/disk/by-uuid/E245-3FCF";
      btrfsDev = "/dev/disk/by-uuid/96679f22-3764-4c1e-9770-3aa96430b4bc";

      btrfs = name: {
        device = btrfsDev;
        fsType = "btrfs";
        options = [ "subvol=${name}" ];
      };
    in
    {
      "/" = btrfs "@";
      "/.subvols" = btrfs "";
      "/home" = btrfs "@home";
      "/nix" = btrfs "@nix";
      "/var/swapfile" = btrfs "@swap";
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

  # Misc.

  powerManagement.cpuFreqGovernor = "powersave";

  # High-resolution display.
  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";
}
