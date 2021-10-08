{ lib, pkgs, config, ... }:
{
  services.smartdns = {
    enable = true;
    settings = {
      conf-file = with pkgs; [
        "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
        "${smartdns-china-list}/apple.china.smartdns.conf"
        "${smartdns-china-list}/google.china.smartdns.conf"
      ];
      bind = [ "127.0.0.1:53" ];
      server = [
        "223.5.5.5 -group china -exclude-default-group"
        "8.8.8.8"
        "9.9.9.9"
        "1.1.1.1"
      ];
      server-https = [
        "https://223.5.5.5/dns-query -group china -exclude-default-group"
        "https://223.6.6.6/dns-query -group china -exclude-default-group"
      ];
    };
  };

  services.zerotierone = {
    enable = true;
    joinNetworks = [ "93afae5963a9686e" ];
  };
}
