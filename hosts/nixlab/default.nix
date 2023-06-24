{ modulesPath, pkgs, secrets, lib, inputs, self, ... }:
let
  user = "diffumist";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    ./services.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.nur.nixosModules.nur
    inputs.home-stable.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.services
    self.nixosModules.server
  ];

  networking = {
    hostName = "nixlab";
    domain = "diffumist.me";
  };

  time.timeZone = "Asia/Shanghai";

  nix = {
    settings.substituters = lib.mkForce [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
    gc.options = lib.mkForce "--delete-older-than 60d";
    registry = lib.mkForce {
      p = {
        from = { id = "nixpkgs"; type = "indirect"; };
        flake = inputs.stable;
      };
    };
    nixPath = lib.mkForce [ "nixpkgs=${inputs.stable}" ];
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
    hashedPassword = "$6$6J91Plm9yvX7KiMs$DOUaBLnKLqpxJXlIAdIWA6KNs8boT58CuavOoMka2DFAZbLe9hRu5ubMBfYfiukHld3LC/rx/CA4B2eBetB.60";
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

  system.stateVersion = "21.11";
}
