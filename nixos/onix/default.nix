{
  lib,
  pkgs,
  secrets,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./boot.nix
    self.nixosModules.default
    inputs.impermanence.nixosModules.impermanence
    inputs.home.nixosModules.home-manager
    inputs.nur.nixosModules.nur
  ];

  # network
  networking = {
    hostName = "onix";
    domain = "diffumist.me";
    networkmanager.dns = "none";
    networkmanager.settings.main.manager = "unmanaged";
    networkmanager.settings.keyfile.path = "/var/lib/NetworkManager/system-connections";
    nameservers = [ "223.5.5.5" ];
    firewall.enable = lib.mkForce false;
  };

  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = "/home/diffumist/.config/clash-verge/profiles/r5pTU9CK4Jq5.yaml";
  };

  services.systembus-notify.enable = true;
  services.earlyoom.enableNotifications = true;
  services.lorri.enable = true;

  # modules options
  modules = {
    gnome-desktop.enable = true;
    hardware.enable = true;
  };

  users.users."diffumist" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "libvirtd"
    ];
    shell = pkgs.fish;
    hashedPassword = "$6$bBKQTanNcRjDBHwJ$dQBwXZvEzgiBLZ/iUXiGPeL1OMNmoCQ8RlO0MY2oCR5P4xyZvEl/TPVzvwwHTqCmPLXQhbEMVCteD6zZSz72Q/";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit secrets;
    };
    users.diffumist = import ../../home;
    sharedModules = [ ];
  };

  system.stateVersion = "24.05";
}
