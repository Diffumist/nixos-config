{ lib, pkgs, secrets, inputs, config, self, ... }:
{
  imports = [
    ./boot.nix
    ./modules
    inputs.impermanence.nixosModules.impermanence
    inputs.home.nixosModules.home-manager
    inputs.nur.nixosModules.nur
    inputs.sops-nix.nixosModules.sops
    inputs.daeuniverse.nixosModules.daed
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
    nameservers = [ "1.1.1.1" ];
    firewall.enable = lib.mkForce false;
  };

  services.daed = {
    enable = true;
    configDir = "/var/lib/daed";
    listen = "127.0.0.1:2023";
    openFirewall = {
      enable = true;
      port = 12345;
    };
  };

  system.activationScripts.initDaedSscripts = ''
    ln -nfs "${pkgs.v2ray-rules-dat}/geoip.dat" "/var/lib/daed/geoip.dat"
    ln -nfs "${pkgs.v2ray-rules-dat}/geosite.dat" "/var/lib/daed/geosite.dat"
  '';

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
      nvidiaEnable = false;
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
