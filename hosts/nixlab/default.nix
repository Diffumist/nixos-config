{ modulesPath, pkgs, secrets, lib, inputs, self, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.nur.nixosModules.nur
    inputs.home-stable.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.services
  ];

  networking = {
    hostName = "nixlab";
    domain = "diffumist.me";
    useDHCP = lib.mkDefault true;
    firewall.enable = true;
  };

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  time.timeZone = "Asia/Shanghai";

  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings.PasswordAuthentication = false;
  };

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
    ];
    diffumist.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
    ];
  };

  nix = {
    package = pkgs.nixVersions.unstable;
    settings = {
      trusted-users = [ "root" "@wheel" ];
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
      ];
      auto-allocate-uids = true;
      use-cgroups = true;
      builders-use-substitutes = true;
      substituters = lib.mkBefore [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 60d";
    };

    extraOptions = ''
      flake-registry = /etc/nix/registry.json
      access-tokens = github.com=${secrets.github-token}
    '';

    registry = {
      p = {
        from = { id = "nixpkgs"; type = "indirect"; };
        flake = inputs.stable;
      };
    };
    nixPath = [ "nixpkgs=${inputs.stable}" ];
  };

  users.users."diffumist" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$6J91Plm9yvX7KiMs$DOUaBLnKLqpxJXlIAdIWA6KNs8boT58CuavOoMka2DFAZbLe9hRu5ubMBfYfiukHld3LC/rx/CA4B2eBetB.60";
  };

  services.earlyoom.enable = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    oci-containers.backend = "podman";
  };

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

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
