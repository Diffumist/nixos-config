{ lib, pkgs, inputs, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
    ./hardware.nix

    ../../config/desktop-env
    ../../config/nix-config.nix
    ../../config/network.nix
  ];

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
    enableTProxy = true;
    tproxyPort = 7891;
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
