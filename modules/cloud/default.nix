{ lib, config, pkgs, ... }:
with lib;
let cfg = config.dmist.cloud; in
{
  options = {
    dmist.cloud = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };
  config = mkIf cfg.enable {
    i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
    networking.firewall.allowedTCPPorts = [ 22 ];
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      passwordAuthentication = false;
    };

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAd/6aBTs/HVmH0g1xHZ+ECETUjEOEHVI7PJuxELqYCg noname"
    ];

    boot.loader.grub.device = "/dev/vda";
    boot.initrd.kernelModules = [ "nvme" ];

    boot.kernel.sysctl = {
      "vm.swappiness" = 30;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.ip_forward" = 1;
    };

    boot.kernelPackages = pkgs.linuxPackages_latest;

    fileSystems =
      let
        btrfsDev = "/dev/disk/by-label/nixos";

        btrfs = options: {
          device = btrfsDev;
          fsType = "btrfs";
          options = [ "noatime" "compress-force=zstd" "space_cache=v2" ] ++ options;
          neededForBoot = true;
        };
        tmpfs = {
          fsType = "tmpfs";
          options = [ "defaults" "mode=755" ];
        };
      in
      {
        "/" = tmpfs;
        "/.subvols" = btrfs [ ];
        "/boot" = btrfs [ "subvol=boot" ];
        "/nix" = btrfs [ "subvol=nix" ];
        "/persist" = btrfs [ "subvol=persist" ];
        "/var/swapfile" = btrfs [ "subvol=swap" ];
      };

    environment.persistence."/persist" = {
      directories = [
        "/var/log"
        "/var/lib"
        "/var/db"
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
      ];
    };

    powerManagement.cpuFreqGovernor = "ondemand";
  };
}
