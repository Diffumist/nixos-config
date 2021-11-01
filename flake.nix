{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    utils.url = "github:numtide/flake-utils";
    utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
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
      inputs.utils.follows = "utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.utils.follows = "utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nickpkgs = {
      url = "github:NickCao/flakes";
      flake = false;
    };
  };
  outputs =
    { self
    , nixpkgs
    , home
    , nickpkgs
    , deploy-rs
    , ...
    } @ inputs:
    let
      inherit (nixpkgs.lib) nixosSystem;
      system = "x86_64-linux";
      this = import ./pkgs; nixcao = import "${nickpkgs}/pkgs";
      overlays = with inputs; map (x: x.overlay) [
        this
        nixcao
        berberman
        sops-nix
        deploy-rs
        rust-overlay
      ];
      shareModules = with inputs; [
        self.nixosModules.base
        self.nixosModules.nix-config
        sops-nix.nixosModules.sops
        impermanence.nixosModules.impermanence
      ];
      mkServerSystem = { system, hostName, hostConfig ? ./hosts/. + "/${hostName}", ...}: nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          hostConfig
          { nixpkgs.overlays = overlays; }
        ] ++ shareModules;
      };
      mkDesktopSystem = { system, hostName, hostConfig ? ./hosts/. + "/${hostName}", ...}: nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          hostConfig
          home.nixosModules.home-manager
          { nixpkgs.overlays = overlays; }
          self.nixosModules.plasma-env
          self.nixosModules.clash
        ] ++ shareModules;
      };
    in
    {
      nixosModules = import ./modules;
      nixosConfigurations = {
        local = mkDesktopSystem {
          inherit system;
          hostName = "local";
        };
        dos = mkServerSystem {
          inherit system;
          hostName = "dos";
        };
        mist = mkServerSystem {
          inherit system;
          hostName = "mist";
        };
        vessel = mkServerSystem {
          inherit system;
          hostName = "vessel";
        };
      };
      deploy.nodes = with self.nixosConfigurations; {
        dos = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "dos.diffumist.me";
          profiles.system.path = deploy-rs.lib.${system}.activate.nixos dos;
        };
        vessel = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "vessel.diffumist.me";
          profiles.system.path = deploy-rs.lib.${system}.activate.nixos vessel;
        };
        mist = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "mist.diffumist.me";
          profiles.system.path = deploy-rs.lib.${system}.activate.nixos mist;
        };
      };
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
