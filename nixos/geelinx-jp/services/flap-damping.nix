{ lib, config, ... }:
let
  domain = "flap-dn42.diffumist.me";
  flapalertedAddress = "fd22:1056:95a4:4::1";
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
    FA_webhookInstanceName=geelinx-jp
  '';

  systemd.services.flapalerted.serviceConfig.EnvironmentFile =
    config.sops.templates."flapalerted-webhook.env".path;

  my.services.caddy.enable = true;
  services.caddy.virtualHosts.${domain} = {
    useACMEHost = domain;
    extraConfig = ''
      encode zstd gzip
      reverse_proxy [${flapalertedAddress}]:${toString frontendPort}
    '';
  };

  sops.secrets.cloudflare_api_token = {
    sopsFile = ../secrets.yaml;
  };

  security.acme.certs.${domain} = {
    dnsProvider = "cloudflare";
    credentialFiles = {
      CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
      CF_ZONE_API_TOKEN_FILE = config.sops.secrets.cloudflare_api_token.path;
    };
  };
}
