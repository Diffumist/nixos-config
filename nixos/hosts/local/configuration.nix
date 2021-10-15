{ lib, pkgs, inputs, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
    ./hardware.nix

    ../../config/desktop-env
    ../../config/nix-config.nix
  ];

  # Network
  networking = {
    hostName = "Dmistlaptop";
    firewall.enable = true;
    networkmanager.dns = "none";
    networkmanager.wifi.backend = "iwd";
    nameservers = [ "127.0.0.1" ];
  };
  time.timeZone = "Asia/Shanghai";

  services.clash = {
    enable = true;
    redirPort = 7891;
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

  services.zerotierone = {
    enable = true;
    joinNetworks = [ "93afae5963a9686e" ];
  };

  # Generate hashedPassword: mkpasswd
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
    users.diffumist = import ../../../home-manager/local.nix;
  };

  system.stateVersion = "20.09";
}
