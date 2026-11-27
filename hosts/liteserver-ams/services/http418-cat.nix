{ pkgs, ... }:
let
  domain = "418.cat";
in
{
  my.services.caddy = {
    enable = true;
    virtualHosts.${domain} = {
      useCloudflareOriginCert = true;
      cloudflareOnly = true;
    };
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    root * ${pkgs.http418-cat}
    file_server
  '';
}
