{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.kernelModules = [ "kvm-amd" ];

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
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
                  swapfile.size = "3G";
                  swapfile.path = "real-path";
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
  fileSystems."/persist".neededForBoot = true;
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

  systemd.tmpfiles.rules = [
    "d /persist/var/storage 0755 root root -"
  ];
}
