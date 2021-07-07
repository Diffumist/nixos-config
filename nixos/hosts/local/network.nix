{ lib, pkgs, config, ... }:
{
  networking = {
    hostName = "Dmistlaptop";
    firewall.enable = false;
    networkmanager.dns = "dnsmasq";
    networkmanager.wifi.backend = "iwd";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    nameservers = [ "127.0.0.1" ];
  };
  services.smartdns = {
    enable = true;
    settings = with pkgs; {
      conf-file = [
        "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
        "${smartdns-china-list}/apple.china.smartdns.conf"
        "${smartdns-china-list}/google.china.smartdns.conf"
      ];
      nameserver =
        [ "/cache.nixos.org/china" "/.6in4.dev/china" ];
      bind = [ "127.0.0.1:53" ];
      server = [
        "114.114.114.114 -group china -exclude-default-group"
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
}
