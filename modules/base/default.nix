{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.dmist.base;
in
{
  options = {
    dmist.base = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ./secrets.yaml;
      age = {
        keyFile = "/var/lib/sops.key";
      };
    };

    swapDevices = [
      {
        device = "/var/swapfile/swapfile";
      }
    ];

    networking.firewall.enable = true;
    system.stateVersion = "20.09";
  };
}
