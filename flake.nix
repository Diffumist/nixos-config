{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.utils.follows = "flake-utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nickpkgs = {
      url = "github:NickCao/flakes?dir=pkgs";
      flake = false;
    };
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.deploy-rs.overlay
              inputs.rust-overlay.overlay
              inputs.sops-nix.overlay
            ];
          };
        in
        rec {
          checks = (inputs.deploy-rs.lib.${system}.deployChecks {
            nodes = pkgs.lib.filterAttrs (name: cfg: cfg.profiles.system.path.system == system) self.deploy.nodes;
          });
          devShell = with pkgs; mkShell {
            buildInputs = [
              nvfetcher
              deploy-rs.deploy-rs
              ssh-to-age
              age
            ];
          };
        }
      ) //
    {
      nixosModules = import ./modules;
      nixosConfigurations = {
        local = import ./nixos/hosts/local { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        dos = import ./nixos/hosts/dos { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        vessel = import ./nixos/hosts/vessel { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        mist = import ./nixos/hosts/mist { system = "x86_64-linux"; inherit self nixpkgs inputs; };
      };
      deploy.nodes = {
        dos = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "dos.diffumist.me";
          profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dos;
        };
        vessel = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "vessel.diffumist.me";
          profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.vessel;
        };
        mist = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "mist.diffumist.me";
          profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mist;
        };
      };
    };
}
