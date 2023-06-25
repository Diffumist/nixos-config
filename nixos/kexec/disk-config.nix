{ disks ? [ "/dev/vda" ], ... }:
{
  disk = {
    main = {
      type = "disk";
      device = builtins.elemAt disks 0;
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "boot";
            type = "partition";
            start = "0";
            end = "1M";
            flags = [ "bios_grub" ];
          }
          {
            type = "partition";
            name = "ESP";
            start = "1MiB";
            end = "128MiB";
            fs-type = "fat32";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "nixos";
            start = "128MiB";
            end = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/.subvol" = {
                  mountpoint = "/";
                };
                "/nix" = {
                  mountOptions = [ "noatime" "space_cache=v2" "compress-force=zstd" ];
                };
                "/persist" = {
                  mountOptions = [ "noatime" "space_cache=v2" "compress-force=zstd" ];
                };
              };
            };
          }
        ];
      };
    };
  };
}
