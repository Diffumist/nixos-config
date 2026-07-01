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
        device = "/dev/sda";
        imageSize = "4G";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "512M";
              type = "EF00";
              priority = 1;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
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
