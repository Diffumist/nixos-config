{ lib, pkgs, secrets, inputs, config, self, ... }:
{
  imports = [
    ./boot.nix
    ./modules
    inputs.impermanence.nixosModules.impermanence
    inputs.home.nixosModules.home-manager
    inputs.nur.nixosModules.nur
    inputs.sops-nix.nixosModules.sops
  ];

  # sops = {
  #   defaultSopsFile = ../../secrets/onix.yaml;
  #   secrets.passwd.neededForUsers = true;
  #   age = {
  #     keyFile = "/var/lib/sops.key";
  #     sshKeyPaths = [ ];
  #   };
  #   gnupg.sshKeyPaths = [ ];
  # };

  nix.registry.p.flake = self;

  # network
  networking = {
    hostName = "onix";
    domain = "diffumist.me";
    networkmanager.dns = "none";
    networkmanager.extraConfig = ''
      [main]
      rc-manager = unmanaged
      [keyfile]
      path = /var/lib/NetworkManager/system-connections
    '';
    nameservers = [ "1.1.1.1" ];
    firewall.enable = lib.mkForce false;
  };

  time.timeZone = "Asia/Shanghai";

  # FHS fix for nixos
  services.envfs.enable = true;
  programs.nix-ld.enable = true;


  # modules options
  modules = {
    gnome-env.enable = true;
    hardware = {
      enable = true;
      nvidiaEnable = false;
      yubikeyEnable = true;
    };
  };
  services.lorri.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];

  users.users."diffumist" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" ];
    shell = pkgs.fish;
    hashedPassword = "$6$bBKQTanNcRjDBHwJ$dQBwXZvEzgiBLZ/iUXiGPeL1OMNmoCQ8RlO0MY2oCR5P4xyZvEl/TPVzvwwHTqCmPLXQhbEMVCteD6zZSz72Q/";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit secrets; };
    users.diffumist = import ../../home;
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];
  };

  system.stateVersion = "23.11";
}
