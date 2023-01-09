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
      inputs.flake-utils.follows = "utils";
    };
    # other pkgs
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
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
        system: rec {
          pkgs = import nixpkgs {
            inherit overlays system;
            config.allowUnfree = true;
          };
          packages = this.packages pkgs;
          devShell = with pkgs; mkShell {
            nativeBuildInputs = [
              deploy-rs
              nvfetcher
              nixpkgs-fmt
            ];
          };
        }
      ) // {
      overlays.default = this.overlay;
      nixosConfigurations =
        let
          hosts = builtins.attrNames (builtins.readDir ./hosts);
          mkSystem = hostname:
            nixpkgs.lib.nixosSystem {
              system = builtins.readFile (./hosts + "/${hostname}/system");
              specialArgs = {
                inherit inputs self;
                inherit (inputs.nix-secrets) secrets;
              };
              modules = [{ nixpkgs = { inherit overlays; }; }]
              ++ [ (import (./hosts + "/${hostname}")) ]
              ++ import ./modules ++ [
                inputs.impermanence.nixosModules.impermanence
                inputs.home.nixosModules.home-manager
                inputs.nur.nixosModules.nur
              ];
            };
        in
        nixpkgs.lib.genAttrs hosts mkSystem;
      deploy.nodes = (builtins.mapAttrs
        (name: machine: {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = machine.config.networking.fqdn;
          profiles.system.path = inputs.deploy-rs.lib."${machine.pkgs.system}".activate.nixos machine;
        })
        (nixpkgs.lib.filterAttrs (n: v: n != "local") self.nixosConfigurations));
    };
}
