{
  description = "diffumist's NixOS configuration";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # utils
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    impermanence.url = "github:nix-community/impermanence";
    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # other pkgs
    nur.url = "github:nix-community/NUR";
    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    # secrets
    nix-secrets.url = "git+ssh://git@github.com/Diffumist/nix-secrets";
  };
  outputs =
    { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.flake-utils.lib.defaultSystems;
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          devShells.default = import ./shell.nix { inherit pkgs; };
        };
      flake = {
        nixosModules = import ./modules;
        overlays.default = import ./overlay { inherit inputs; };
        nixosConfigurations = inputs.nixpkgs.lib.genAttrs (builtins.attrNames (builtins.readDir ./nixos)) (
          hostname:
          inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs self;
              inherit (inputs.nix-secrets) secrets;
            };
            modules = [
              (import (./nixos + "/${hostname}"))
              {
                nixpkgs.overlays = [
                  self.overlays.default
                  inputs.berberman.overlays.default
                  inputs.nix-vscode-extensions.overlays.default
                ];
              }
            ];
          }
        );
      };
    }
    // {
      # Remote Build
      colmena = {
        meta = {
          specialArgs = {
            inherit self inputs;
            inherit (inputs.nix-secrets) secrets;
          };
          nixpkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        mist =
          { name, ... }:
          {
            deployment = {
              targetHost = "74.48.73.20";
              targetPort = 2222;
            };
            imports = [ ./nixos/${name} ];
          };
      };
    };
}
