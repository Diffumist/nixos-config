{ lib, pkgs, secrets, config, ... }:
{
  imports = [
    ./boot.nix
    ./software.nix
  ];

  # network
  networking = {
    hostName = "local";
    domain = "diffumist.me";
    networkmanager.dns = "none";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    nameservers = [ "127.0.0.1" ];
    firewall.enable = lib.mkForce false;
  };
  time.timeZone = "Asia/Shanghai";

  # modules options
  modules = {
    gnome-env = {
      enable = true;
      waylandEnable = false;
    };
    clash.enable = true;
    hardware = {
      enable = true;
      nvidiaEnable = true;
      canokeyEnable = true;
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
      hashedPassword = "$6$6J91Plm9yvX7KiMs$DOUaBLnKLqpxJXlIAdIWA6KNs8boT58CuavOoMka2DFAZbLe9hRu5ubMBfYfiukHld3LC/rx/CA4B2eBetB.60";
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit secrets; };
    users.diffumist = import ../../home;
  };
}
