{ lib, config, pkgs, ... }:
{
  # Initrd.
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "rtsx_pci_sdmmc" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];

  # Kernel.
  boot.kernelModules = [ "kvm-intel" ];
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

      btrfs = options: {
        device = btrfsDev;
        fsType = "btrfs";
        options = [ "noatime" ] ++ options;
      };
    in
    {
      "/" = btrfs [ "subvol=@" "compress-force=zstd" ];
      "/.subvols" = btrfs [];
      "/home" = btrfs [ "subvol=@home" "compress-force=zstd" ];
      "/nix" = btrfs [ "subvol=@nix" "compress-force=zstd" ];
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

  # Misc.

  powerManagement.cpuFreqGovernor = "powersave";

  # High-resolution display.
  hardware.video.hidpi.enable = true;
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-u24n.psf.gz";
}
