{ modulesPath, ... }:
let
  btrfsMountOptions = [
    "noatime"
    "compress-force=zstd:-5"
    "space_cache=v2"
  ];
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
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
  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "mode=755"
      ];
    };
  };
  fileSystems."/persist".neededForBoot = true;
  preservation = {
    enable = true;
    preserveAt."/persist" = {
      directories = [
        "/var/log"
        {
          directory = "/var/lib";
          inInitrd = true;
        }
        "/var/db"
      ];
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          how = "symlink";
          configureParent = true;
        }
      ];
    };
  };
  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
