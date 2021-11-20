{ lib, pkgs, dmist, secrets, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
  ];
  # swapfile
  swapDevices = [
    {
      device = "/var/swapfile/swapfile";
    }
  ];
  # network
  networking = {
    hostName = "local";
    networkmanager.dns = "none";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    nameservers = [ "127.0.0.1" ];
  };
  time.timeZone = "Asia/Shanghai";

  # modules options
  dmist = {
    gnome-env = {
      enable = true;
      waylandEnable = false;
    };
    clash.enable = true;
    hardware = {
      enable = true;
      nvidiaEnable = true;
    };
  };

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
    extraSpecialArgs = { inherit secrets; };
    users.diffumist = import ../../home;
  };
}
