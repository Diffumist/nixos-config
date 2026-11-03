{ config, ... }:
let
  btrfsMountOptions = config.my.hardware.ephemeralBtrfs.mountOptions;
in
{
  my.hardware.ephemeralBtrfs.layout = "custom";

  disko.devices.disk = {
    main = {
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
                  mountOptions = btrfsMountOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsMountOptions;
                };
                "@swap" = {
                  mountpoint = "/.swap";
                  swap = {
                    swapfile.size = "1024M";
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
    persist = {
      type = "disk";
      device = "/dev/vdb";
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
  };
}
