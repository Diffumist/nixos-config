{ pkgs, ... }:
{
  boot.loader.grub.device = "/dev/vda";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    # bbr
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    # burst / accept queues
    "net.core.somaxconn" = 4096;
    "net.ipv4.tcp_max_syn_backlog" = 4096;
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_syncookies" = 1;

    # QUIC/UDP buffers (good default for 1Gbps+)
    "net.core.rmem_max" = 67108864;
    "net.core.wmem_max" = 67108864;
    "net.core.rmem_default" = 1048576;
    "net.core.wmem_default" = 1048576;
    "net.ipv4.udp_rmem_min" = 16384;
    "net.ipv4.udp_wmem_min" = 16384;

    # outbound-heavy helpers (harmless even if not needed)
    "net.ipv4.ip_local_port_range" = "10240 65535";
    "net.ipv4.tcp_fin_timeout" = 15;
    "net.ipv4.tcp_tw_reuse" = 1;
  };

  fileSystems =
    let
      btrfsDev = "/dev/disk/by-label/nixos";

      btrfs = options: {
        device = btrfsDev;
        fsType = "btrfs";
        options = [
          "noatime"
          "compress-force=zstd:-5"
          "space_cache=v2"
        ]
        ++ options;
        neededForBoot = true;
      };
    in
    {
      "/" = {
        fsType = "tmpfs";
        options = [ "defaults" ];
      };
      "/.subvols" = btrfs [ ];
      "/boot" = btrfs [ "subvol=@boot" ];
      "/nix" = btrfs [ "subvol=@nix" ];
      "/.swap" = btrfs [ "subvol=@swap" ];
      "/.persist" = btrfs [ "subvol=@persist" ];
    };

  environment.persistence."/.persist" = {
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
  # swapfile
  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];

}
