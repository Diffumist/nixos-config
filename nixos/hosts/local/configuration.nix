{ lib, pkgs, inputs, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
    ./system.nix
    ./network.nix
    # ./virtual.nix

    ../../modules/desktop-env
    ../../modules/syncthing.nix
    ../../modules/nix-config.nix
    ../../modules/nix-registry.nix
    ../../modules/steam-compat.nix
  ];

  networking.hostName = "Dmistlaptop";

  time.timeZone = "Asia/Shanghai";

  users = {
    groups."diffumist".gid = 1000;
    users."diffumist" = {
      isNormalUser = true;
      uid = 1000;
      group = "diffumist";
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
    };
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.diffumist = import ../../../home/local.nix;
  };

  system.stateVersion = "20.09";
}
