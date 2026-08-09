{ pkgs, ... }:
let
  domain = "418.cat";
in
{
  my.services.caddy = {
    enable = true;
    virtualHosts.${domain}.useCloudflareACME = true;
  };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    encode zstd gzip
    root * ${pkgs.http418-cat}
    file_server
  '';
}
