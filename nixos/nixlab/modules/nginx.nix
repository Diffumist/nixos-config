{ config, lib, ... }:

with lib;
let
  cfg = config.modules.nginx;
in
{
  options.modules.nginx = {
    enable = mkEnableOption "nginx";
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      enableReload = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
    };

    users.users.nginx.extraGroups = [ "acme" ];
  };
}
