{ config, ... }:
{
  services.sillytavern = {
    enable = true;
    configFile = "/var/lib/SillyTavern/config.mutable.yaml";
    listen = false;
    listenAddressIPv4 = "127.0.0.1";
    port = 8002;
    whitelist = false;
  };

  systemd.tmpfiles.rules = [
    "C /var/lib/SillyTavern/config.mutable.yaml 0600 sillytavern sillytavern - ${config.services.sillytavern.package}/lib/node_modules/sillytavern/config.yaml"
  ];

  my.services.caddy = {
    enable = true;
    virtualHosts."tavern.diffumist.me" = {
      useCloudflareACME = true;
      oauth2ForwardAuth = "oauth.diffumist.me";
    };
  };
  services.caddy.virtualHosts."tavern.diffumist.me" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:${toString config.services.sillytavern.port}
    '';
  };

  my.networking.usedTCPPorts.sillytavern = config.services.sillytavern.port;
}
