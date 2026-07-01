{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  # printf "Yes\n" | parted ---pretend-input-tty /dev/vda resizepart 2 100%
  # btrfs filesystem resize max /nix
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko.nix
  ];

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
        # gcp
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
    loader = {
      grub = {
        enable = true;
        devices = [ "/dev/vda" ];
      };
    };
    supportedFilesystems.zfs = lib.mkForce false;
  };

  networking = {
    hostName = "bootstrap";
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
    matchConfig.MACAddress = "42:01:0a:80:00:02";
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
  fileSystems."/persist".neededForBoot = true;
  preservation = {
    enable = true;
    preserveAt."/persist" = {
      directories = [
        "/var/log"
        {
          directory = "/var/lib";
          inInitrd = true;
        }
        "/var/db"
      ];
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          how = "symlink";
          configureParent = true;
        }
      ];
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

  system.stateVersion = "25.11";
}
