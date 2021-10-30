{ lib, pkgs, inputs, dmist, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
    ./hardware.nix
  ];
  # Network
  networking = {
    hostName = "local";
    firewall.enable = true;
    networkmanager.dns = "none";
    networkmanager.wifi.backend = "iwd";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    nameservers = [ "127.0.0.1" ];
  };
  time.timeZone = "Asia/Shanghai";

  dmist.clash = {
    enable = true;
    redirPort = 7891;
    configFile = "/etc/clash/clash.yaml";
  };

  services.smartdns = {
    enable = true;
    settings = {
      conf-file = with pkgs; [
        "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
        "${smartdns-china-list}/apple.china.smartdns.conf"
        "${smartdns-china-list}/google.china.smartdns.conf"
      ];
      bind = [ "127.0.0.1:53" ];
      prefetch-domain = true;
      server = "223.5.5.5 -group china -exclude-default-group";
      server-tls = [ "8.8.8.8:853" "1.1.1.1:853" ];
      server-https = "https://cloudflare-dns.com/dns-query -exclude-default-group";
    };
  };

  # Generate hashedPassword: mkpasswd -m sha-512
  users = {
    groups."diffumist".gid = 1000;
    users."diffumist" = {
      isNormalUser = true;
      uid = 1000;
      group = "diffumist";
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.fish;
      hashedPassword = "$6$pdVI5OMHlykFwtcC$Hh1wEakcsiI5nG/zRI7Xdt10OD99e7D3SaKQu5SQWi9p.vpM6jgG01RtIlWfDwSp/K5jumRIWqS8NigILAlCi/";
    };
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.diffumist = import ../../home;
  };

  system.stateVersion = "20.09";
}
