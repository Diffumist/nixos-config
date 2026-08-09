{ config, ... }:
{
  services.sillytavern = {
    enable = true;
    listen = false;
    listenAddressIPv4 = "127.0.0.1";
    port = 8000;
    whitelist = false;
  };

  my.services.caddy = {
    enable = true;
    virtualHosts."tavern.diffumist.me" = {
      useCloudflareACME = true;
      oauth2ForwardAuth = "oauth.diffumist.me";
    };
  };
  services.caddy.virtualHosts."tavern.diffumist.me" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:${toString config.services.sillytavern.port}
    '';
  };
}
