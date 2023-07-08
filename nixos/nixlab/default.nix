{ pkgs, lib, inputs, config, ... }:
let
  user = "diffumist";
in
{
  imports = [
    ./boot.nix
    ./modules
    inputs.impermanence.nixosModules.impermanence
    inputs.nur.nixosModules.nur
    inputs.home-stable.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
  ];

  networking = {
    hostName = "nixlab";
    domain = "diffumist.me";
    useNetworkd = true;
    interfaces.eno1 = {
      useDHCP = true;
      ipv4.addresses = [{ address = "192.168.0.252"; prefixLength = 24; }];
      ipv4.routes = [{ address = "192.168.0.1"; prefixLength = 24; }];
    };
  };

  time.timeZone = "Asia/Shanghai";

  nix = {
    settings = {
      substituters = lib.mkForce [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      nix-path = [ "nixpkgs=${inputs.stable}" ];
    };
    registry = {
      p.flake = inputs.stable;
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/nixlab.yaml;
    secrets.passwd.neededForUsers = true;
    age = {
      keyFile = "/var/lib/sops.key";
      sshKeyPaths = [ ];
    };
    gnupg.sshKeyPaths = [ ];
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
    ];
  };
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    passwordFile = config.sops.secrets.passwd.path;
  };

  modules.nginx.enable = true;
  system.stateVersion = "21.11";
}
