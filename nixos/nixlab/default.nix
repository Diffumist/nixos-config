{ pkgs, secrets, lib, inputs, self, config, ... }:
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
    self.nixosModules.server
    self.nixosModules.services
  ];

  networking = {
    hostName = "nixlab";
    domain = "diffumist.me";
  };

  time.timeZone = "Asia/Shanghai";

  nix = {
    settings = {
      substituters = lib.mkForce [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      nix-path = [ "nixpkgs=${inputs.stable}" ];
    };
    registry = lib.mkForce {
      p.flake = inputs.stable;
    };
  };

  sops = {
    defaultSopsFile = ../nixlab.yaml;
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
    extraGroups = [ "wheel" "transmission" ];
    shell = pkgs.fish;
    passwordFile = config.sops.secrets.passwd.path;
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit secrets; };
    users.diffumist = import ./home.nix;
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];
  };

  modules.nginx.enable = true;
  system.stateVersion = "21.11";
}
