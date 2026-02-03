{ ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # TODO: 改成你的磁盘
        device = "/dev/disk/by-id/nixos";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "512MiB";
              priority = 1;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = [ "umask=0077" ];
              };
            };

            nixos = {
              size = "100%";
              priority = 2;
              content = {
                type = "btrfs";

                # 让设备有 /dev/disk/by-label/nixos
                extraArgs = [ "-L" "nixos" ];

                subvolumes = {
                  "@" = {
                    mountpoint = "/.subvols";
                    mountOptions = [
                      "noatime"
                      "compress-force=zstd:-5"
                      "space_cache=v2"
                    ];
                  };

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
                    mountOptions = [
                      "noatime"
                      "compress-force=zstd:-5"
                      "space_cache=v2"
                    ];
                  };

                  "@persist" = {
                    mountpoint = "/.persist";
                    mountOptions = [
                      "noatime"
                      "compress-force=zstd:-5"
                      "space_cache=v2"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/" = {
    fsType = "tmpfs";
    options = [ "defaults" ];
  };
}
