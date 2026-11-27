{ config, ... }:
let
  domain = "flap-dn42.diffumist.me";
  flapalertedAddress = config.my.services.dn42.flapDamping.serverAddress;
  frontendPort = 11791;
in
{
  my.services.dn42.flapDamping.runServer = true;

  sops.secrets.bark_device_key = {
    sopsFile = ../secrets.yaml;
  };

  sops.templates."flapalerted-webhook.env".content = ''
    FA_webhookUrlStart=http://bark.diffumist.me/${config.sops.placeholder.bark_device_key}/FlapAlerted/DN42%20route%20flap%20started
    FA_webhookUrlEnd=http://bark.diffumist.me/${config.sops.placeholder.bark_device_key}/FlapAlerted/DN42%20route%20flap%20ended
    FA_webhookInstanceName=noboard
  '';

  systemd.services.flapalerted.serviceConfig.EnvironmentFile =
    config.sops.templates."flapalerted-webhook.env".path;

  my.services.caddy = {
    enable = true;
    virtualHosts.${domain} = {
      useCloudflareOriginCert = true;
      cloudflareOnly = true;
    };
  };
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy [${flapalertedAddress}]:${toString frontendPort}
  '';
}
