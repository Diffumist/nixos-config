{ ... }:
{
  # init: disko --mode destroy,format,mount /tmp/disk-config.nix
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
              "@root" = {
                mountpoint = "/";
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
                swap = {
                  swapfile.size = "1024M";
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
}
