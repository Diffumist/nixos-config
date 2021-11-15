{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.dmist.cloud;
in
{
  options = {
    dmist.cloud = {
      enable = mkEnableOption "cloud";
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

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
      };
      oci-containers.backend = "podman";
    };

    powerManagement.cpuFreqGovernor = "ondemand";
  };
}
