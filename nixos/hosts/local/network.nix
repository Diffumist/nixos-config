{ lib, pkgs, config, ... }:
{
  networking = {
    hostName = "Dmistlaptop";
    firewall.enable = false;
    networkmanager.dns = "none";
    networkmanager.wifi.backend = "iwd";
    nameservers = [ "127.0.0.1" ];
  };

  # FIXME: https://github.com/NixOS/nixpkgs/issues/97389
  # services.syncthing = {
  #   enable = true;
  #   user = "diffumist";
  #   openDefaultPorts = true;
  #   declarative = {
  #     devices = {
  #       android = {
  #         addresses = [ "dynamic" ];
  #         id = "P4HRTS6-CPFCLPU-QYTPFJV-F3NTFQW-3BY42Q6-L5GSIMM-HQO3LPV-UHMGGA3";
  #       };
  #     };
  #     folders = {
  #       "/home/diffumist/Pictures/ShaftImages/" = {
  #         id = "d7zsp-fqqmz";
  #         devices = [ "android" ];
  #       };
  #       "/home/diffumist/Music/Sync" = {
  #         id = "vghwu-tsmep";
  #         devices = [ "android" ];
  #       };
  #     };
  #   };
  # };

  services.smartdns = {
    enable = true;
    settings = with pkgs; {
      conf-file = [
        "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
        "${smartdns-china-list}/apple.china.smartdns.conf"
        "${smartdns-china-list}/google.china.smartdns.conf"
      ];
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
