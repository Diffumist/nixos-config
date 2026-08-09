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
