{
  description = "diffumist's NixOS configuration";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # utils
    utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    # other pkgs
    nur = {
      url = "github:nix-community/NUR";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nickpkgs = {
      url = "github:NickCao/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # secrets
    nix-secrets = {
      url = "/home/diffumist/Documents/Project/nix-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, ... } @inputs:
    let
      this = import ./pkgs;
      overlays = [
        self.overlays.default
        inputs.nickpkgs.overlays.default
        inputs.berberman.overlays.default
        inputs.rust-overlay.overlays.default
      ];
    in
    inputs.utils.lib.eachSystem [ "x86_64-linux" ]
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
          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [
              colmena
              nvfetcher
              nixpkgs-fmt
            ];
          };
        }
      ) // {
      overlays.default = this.overlay;
      nixosModules.default = import ./modules;
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
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            inherit overlays;
            config.allowUnfree = true;
          };
        };
        mist = { name, ... }: {
          deployment = {
            targetHost = "${name}.diffumist.me";
            tags = [ "main" ];
          };
          imports = [ ./hosts/${name} ];
        };
      };
    };
}
