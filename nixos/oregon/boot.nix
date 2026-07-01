{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
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
            extraArgs = [ "-f" ];
            subvolumes = {
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "noatime"
                  "compress-force=zstd:-5"
                  "space_cache=v2"
                ];
              };
              "@persist" = {
                mountpoint = "/persist";
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
            };
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

  systemd.tmpfiles.rules = [
    "d /persist/var/storage 0755 root root -"
  ];
}
