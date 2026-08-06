{
  config,
  lib,
  pkgs,
  ...
}:
{
  # printf "Yes\n" | parted ---pretend-input-tty /dev/vda resizepart 2 100%
  # btrfs filesystem resize max /nix
  imports = [
    (import ../../profiles/hardware/ephemeral-btrfs.nix {
      device = "/dev/vda";
      firmware = "uefi";
      swapSize = "512M";
    })
  ];

  disko.devices = {
    disk.main.imageSize = "4G";
    nodev."/".mountOptions = [
      "nosuid"
      "nodev"
    ];
  };

  disko.imageBuilder.pkgs = pkgs.extend (
    _final: prev: {
      vmTools = prev.vmTools // {
        override =
          args:
          prev.vmTools.override (
            args
            // {
              kernel = config.boot.kernelPackages.kernel;
              kernelModules = args.kernelModules or args.kernel or config.boot.kernelPackages.kernel;
            }
          );
      };
    }
  );

  boot = {
    kernelParams = [
      "audit=0"
      "net.ifnames=0"
    ];
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    initrd = {
      compressor = "zstd";
      compressorArgs = [
        "-19"
        "-T0"
      ];
      systemd.enable = true;
      availableKernelModules = [
        "virtio_net"
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        # google
        "virtio_scsi"
        "sd_mod"
        "ahci"
        "ata_piix"
        "virtio_pci"
        "xen_blkfront"
        "vmw_pvscsi"
      ];
      kernelModules = [
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
      ];
    };
    supportedFilesystems.zfs = lib.mkForce false;
  };

  networking = {
    useDHCP = true;
    useNetworkd = true;
    nftables.enable = true;
    firewall.enable = false;
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
    ];
  };

  services.resolved.enable = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.MACAddress = "52:54:06:5d:0e:6f";
    networkConfig = {
      DHCP = "ipv4";
    };
  };

  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
    ];
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      btrfs-progs
      btop
      curl
      duf
      helix
      parted
      rsync
    ];
  };

  documentation = {
    doc.enable = false;
    info.enable = false;
    man.enable = false;
  };

  nix = {
    channel.enable = false;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
    };
  };

  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

}
