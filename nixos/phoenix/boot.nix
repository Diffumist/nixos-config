{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "kvm-amd" ];
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

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # for grub MBR
          priority = 1;
        };
        nixos = {
          size = "100%";
          priority = 2;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@boot" = {
                mountpoint = "/boot";
                mountOptions = [
                  "noatime"
                  "compress-force=zstd:-5"
                  "space_cache=v2"
                ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "noatime"
                  "compress-force=zstd:-5"
                  "space_cache=v2"
                ];
              };
              "@swap" = {
                mountpoint = "/.swap";
                swap = {
                  swapfile.size = "1024M";
                  swapfile.path = "rel-path";
                };
              };
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "noatime"
                  "compress-force=zstd:-5"
                  "space_cache=v2"
                ];
              };
            };
            mountpoint = "/.subvols";
          };
        };
      };
    };
  };
  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "mode=755"
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
  fileSystems."/persist".neededForBoot = true;
  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];

}
