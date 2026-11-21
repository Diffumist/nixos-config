{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.ephemeralBtrfs;
  isSingleDisk = cfg.layout == "single-disk";
  isUefi = cfg.firmware == "uefi";
in
{
  options.my.hardware.ephemeralBtrfs = {
    enable = lib.mkEnableOption "the ephemeral Btrfs root layout";

    layout = lib.mkOption {
      type = lib.types.enum [
        "single-disk"
        "custom"
      ];
      default = "single-disk";
      description = "Whether this module generates the disk layout or only applies shared ephemeral-root policy.";
    };

    device = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/dev/vda";
      description = "Disk used by the generated single-disk layout; required for that layout.";
    };

    firmware = lib.mkOption {
      type = lib.types.enum [
        "bios"
        "uefi"
      ];
      default = "bios";
      description = "Firmware used by the generated single-disk layout.";
    };

    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "1024M";
      description = "Swapfile size used by the generated single-disk layout.";
    };

    mountOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "noatime"
        "compress-force=zstd:-5"
        "space_cache=v2"
      ];
      description = "Mount options shared by generated and custom Btrfs layouts.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !isSingleDisk || cfg.device != null;
            message = "my.hardware.ephemeralBtrfs.device must be set for the single-disk layout.";
          }
        ];

        disko.devices.nodev."/" = {
          fsType = "tmpfs";
          mountOptions = [ "mode=755" ];
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
                file = "/etc/ssh/ssh_host_ed25519_key";
                how = "symlink";
                configureParent = true;
              }
            ];
          };
        };
      }

      (lib.mkIf isSingleDisk {
        boot.loader = lib.mkIf isUefi {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        disko.devices.disk.main = lib.mkIf (cfg.device != null) {
          type = "disk";
          device = cfg.device;
          content = {
            type = "gpt";
            partitions =
              (
                if isUefi then
                  {
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
                  }
                else
                  {
                    boot = {
                      size = "1M";
                      type = "EF02";
                      priority = 1;
                    };
                  }
              )
              // {
                nixos = {
                  size = "100%";
                  priority = 2;
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "@nix" = {
                        mountpoint = "/nix";
                        inherit (cfg) mountOptions;
                      };
                      "@persist" = {
                        mountpoint = "/persist";
                        inherit (cfg) mountOptions;
                      };
                      "@swap" = {
                        mountpoint = "/.swap";
                        swap = {
                          swapfile.size = cfg.swapSize;
                          swapfile.path = "real-path";
                        };
                      };
                    }
                    // lib.optionalAttrs (!isUefi) {
                      "@boot" = {
                        mountpoint = "/boot";
                        inherit (cfg) mountOptions;
                      };
                    };
                  }
                  // lib.optionalAttrs (!isUefi) {
                    mountpoint = "/.subvols";
                  };
                };
              };
          };
        };

        systemd.tmpfiles.rules = [ "d /persist/var/storage 0755 root root -" ];
      })
    ]
  );
}
