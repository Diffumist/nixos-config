{
  device,
  firmware ? "bios",
  swapSize ? "1024M",
  persistTmpfiles ? [ ],
}:
{
  lib,
  modulesPath,
  ...
}:
let
  isUefi = firmware == "uefi";
  mountOptions = [
    "noatime"
    "compress-force=zstd:-5"
    "space_cache=v2"
  ];
in
assert lib.assertOneOf "firmware" firmware [
  "bios"
  "uefi"
];
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader = lib.mkIf isUefi {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  disko.devices = {
    disk.main = {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions =
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
              nixos = {
                size = "100%";
                priority = 2;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@nix" = {
                      mountpoint = "/nix";
                      inherit mountOptions;
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      inherit mountOptions;
                    };
                    "@swap" = {
                      mountpoint = "/.swap";
                      swap = {
                        swapfile.size = swapSize;
                        swapfile.path = "real-path";
                      };
                    };
                  };
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
              nixos = {
                size = "100%";
                priority = 2;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@boot" = {
                      mountpoint = "/boot";
                      inherit mountOptions;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      inherit mountOptions;
                    };
                    "@swap" = {
                      mountpoint = "/.swap";
                      swap = {
                        swapfile.size = swapSize;
                        swapfile.path = "real-path";
                      };
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      inherit mountOptions;
                    };
                  };
                  mountpoint = "/.subvols";
                };
              };
            };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [ "mode=755" ];
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

  systemd = {
    suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    tmpfiles.rules = persistTmpfiles;
  };
}
