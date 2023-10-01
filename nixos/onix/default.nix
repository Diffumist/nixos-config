{ lib, pkgs, secrets, inputs, config, self, ... }:
{
  imports = [
    ./boot.nix
    ./modules
    inputs.impermanence.nixosModules.impermanence
    inputs.home.nixosModules.home-manager
    inputs.nur.nixosModules.nur
    inputs.sops-nix.nixosModules.sops
    inputs.daeuniverse.nixosModules.dae
  ];

  sops = {
    defaultSopsFile = ../../secrets/onix.yaml;
    secrets.passwd.neededForUsers = true;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

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
    nameservers = [ "127.0.0.1" ];
    firewall.enable = lib.mkForce false;
  };

  # services.dae.enable = true;
  # environment.etc."dae/config.dae" = {
  #   source = secrets.dae.configFile;
  #   mode = "0600";
  # };

  # services.dae = {
  #   enable = true;
  #   disableTxChecksumIpGeneric = false;
  #   config = lib.readFile secrets.dae.configFile;
  #   assets = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
  # };

  time.timeZone = "Asia/Shanghai";

  # FHS fix for nixos
  services.envfs.enable = true;
  programs.nix-ld.enable = true;


  # modules options
  modules = {
    gnome-env = {
      enable = true;
      waylandEnable = true;
    };
    hardware = {
      enable = true;
      nvidiaEnable = true;
      yubikeyEnable = true;
    };
  };
  services.lorri.enable = true;
  programs.adb.enable = true;
  users.groups."adbusers".members = [ "diffumist" ];

  users.users."diffumist" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets.passwd.path;
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

  system.stateVersion = "21.11";
}
