{ lib, config, pkgs, ... }:
with lib;
let cfg = config.dmist.cloud; in
{
  options = {
    dmist.cloud.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };
  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      passwordAuthentication = false;
    };
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };
}
