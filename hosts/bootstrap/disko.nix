_:
let
  btrfsOptions = [
    "noatime"
    "compress-force=zstd:-5"
    "space_cache=v2"
  ];
in
{
  disko = {
    enableConfig = false;
    devices = {
      disk.main = {
        type = "disk";
        device = "/dev/vda";
        imageSize = "4G";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
              priority = 1;
            };
            nixos = {
              size = "100%";
              priority = 2;
              content = {
                type = "btrfs";
                extraArgs = [
                  "-f"
                  "-L"
                  "NIXOS"
                ];
                subvolumes = {
                  "@boot" = {
                    mountpoint = "/boot";
                    mountOptions = btrfsOptions;
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = btrfsOptions;
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = btrfsOptions;
                  };
                  "@swap" = {
                    mountpoint = "/.swap";
                    swap = {
                      swapfile.size = "512M";
                      swapfile.path = "real-path";
                    };
                  };
                };
                mountpoint = "/.subvols";
              };
            };
          };
        };
      };
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "mode=755"
          "nosuid"
          "nodev"
        ];
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "mode=755"
        "nosuid"
        "nodev"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@boot" ];
    };
    "/nix" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@nix" ];
    };
    "/persist" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      neededForBoot = true;
      options = btrfsOptions ++ [ "subvol=@persist" ];
    };
    "/.swap" = {
      device = "/dev/disk/by-label/NIXOS";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@swap" ];
    };
  };

  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];
}
