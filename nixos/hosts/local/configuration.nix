{ lib, pkgs, inputs, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
    ./system.nix
    ./network.nix
    ./virtual.nix

    ../../modules/desktop-env
    ../../modules/nix-config.nix
  ];

  networking.hostName = "Dmistlaptop";

  time.timeZone = "Asia/Shanghai";

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
    users.diffumist = import ../../../home/local.nix;
  };

  system.stateVersion = "20.09";
}
