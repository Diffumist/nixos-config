{ config, ... }:
let
  btrfsMountOptions = config.my.hardware.ephemeralBtrfs.mountOptions;
in
{
  my.hardware.ephemeralBtrfs.layout = "custom";

  disko.devices.disk = {
    main = {
      type = "disk";
      device = "/dev/sdc";
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
                  mountOptions = btrfsMountOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsMountOptions;
                };
              };
              mountpoint = "/.subvols";
            };
          };
        };
      };
    };
    persist = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions.persist = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            mountpoint = "/persist";
            mountOptions = btrfsMountOptions;
          };
        };
      };
    };
    swap = {
      type = "disk";
      device = "/dev/sdb";
      content = {
        type = "gpt";
        partitions.swap = {
          size = "100%";
          content.type = "swap";
        };
      };
    };
  };
}
