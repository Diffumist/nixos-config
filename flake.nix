{
  description = "diffumist's NixOS configuration";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/release-23.05";
    # utils
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-stable = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "stable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows= "";
    };
    # other pkgs
    nur = {
      url = "github:nix-community/NUR";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # secrets
    nix-secrets = {
      url = "/home/diffumist/Documents/Project/nix-secrets";
    };
  };
  outputs = { self, nixpkgs, stable, ... } @inputs:
    let
      this = import ./pkgs;
      overlays = [
        self.overlays.default
        inputs.berberman.overlays.default
      ];
    in
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit overlays system;
            config.allowUnfree = true;
          };
        in
        {
          packages = this.packages pkgs;
          legacyPackages = pkgs;
          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [
              sops
              age
              cachix
              colmena
              nvfetcher
              nixpkgs-fmt
            ];
          };
        }
      ) // {
      overlays.default = this.overlay;
      nixosModules = import ./modules;
      nixosConfigurations =
        let
          hosts = builtins.attrNames (builtins.readDir ./hosts);
          mkSystem = hostname:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs self;
                inherit (inputs.nix-secrets) secrets;
              };
              modules = [{ nixpkgs = { inherit overlays; }; }]
              ++ [ (import (./hosts + "/${hostname}")) ];
            };
        in
        nixpkgs.lib.genAttrs hosts mkSystem;
      colmena = {
        meta = {
          specialArgs = {
            inherit self inputs;
            inherit (inputs.nix-secrets) secrets;
          };
          nixpkgs = import stable {
            system = "x86_64-linux";
            inherit overlays;
            config.allowUnfree = true;
          };
        };
        mist = { name, ... }: {
          deployment = {
            targetHost = "108.166.217.159";
            targetPort = 2222;
          };
          imports = [ ./hosts/${name} ];
        };
        nixlab = { name, ... }: {
          deployment = {
            targetHost = "192.168.0.100";
            targetPort = 2222;
          };
          imports = [ ./hosts/${name} ];
        };
      };
    };
}
