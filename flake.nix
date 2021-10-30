{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    blank.follows = "digga/blank";
    nixlib.follows = "digga/nixlib";
    flake-utils.follows = "digga/flake-utils";
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus/1.2.0";
    deploy-rs.follows = "digga/deploy";
    flake-compat.follows = "digga/deploy/flake-compat";

    digga = {
      url = "github:divnix/digga";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home";
    };
    home = {
      url = "github:nix-community/home-manager/release-21.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    nickpkgs = {
      url = "github:NickCao/flakes";
      flake = false;
    };
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs =
    { self
    , nixpkgs
    , digga
    , home
    , utils
    , rust-overlay
    , deploy-rs
    , sops-nix
    , berberman
    , impermanence
    , ...
    } @ inputs:
    let
      this = import ./pkgs;
      nixcao = import "${inputs.nickpkgs}/pkgs";
      inherit (utils.lib) mkFlake exportModules exportOverlays exportPackages;
    in
    mkFlake {
      inherit self inputs;
      supportedSystems = [ "x86_64-linux" ];
      channelsConfig.allowUnfree = true;
      channels.nixpkgs.overlaysBuilder = channels:  map (x: x.overlay) [
        rust-overlay
        deploy-rs
        berberman
        nixcao
        this
        utils
        ];
      nixosModules = exportModules [
        ./modules/shadowsocks
        ./modules/plasma-env
        ./modules/clash
        ./modules/base
        ./modules/sops-nix
        ./modules/nix-config
      ];

      hostDefaults = {
        system = "x86_64-linux";
        channelName = "nixpkgs";
        modules = with self.nixosModules; [
          base
          # sops-nix
          nix-config
          # sops-nix.nixosModules.sops
          impermanence.nixosModules.impermanence
        ];
      };

      hosts = with self.nixosModules; {
        local.modules = [
          ./nixos/local/configuration.nix
          home.nixosModules.home-manager
          plasma-env
          clash
        ];
        vessel.modules = [
          shadowsocks
        ];
        mist.modules = vessel.modules;
        dos.modules = vessel.modules;
      };
      outputsBuilder = channels: with channels.nixpkgs; {
        devShell = mkShell {
          buildInputs = [
            cachix
            nixpkgs-fmt
            deploy-rs
          ];
        };
      };
    };
}
