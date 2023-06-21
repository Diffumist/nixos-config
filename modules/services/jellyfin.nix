{ config, lib, ... }:

with lib;
let
  cfg = config.modules.jellyfin;
in
{
  options.modules.jellyfin = {
    enable = mkEnableOption "jellyfin";
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
    };
    services.jellyseerr = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
    };
  };
}
