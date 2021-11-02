{
  description = "diffumist's NixOS configuration";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/release-21.05";
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
      inputs.utils.follows = "utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # other pkgs
    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nickpkgs = {
      url = "github:NickCao/flakes";
      flake = false;
    };
  };
  outputs =
    { self
    , home
    , nixpkgs
    , stable
    , sops-nix
    , nickpkgs
    , deploy-rs
    , berberman
    , rust-overlay
    , impermanence
    , ...
    } @ inputs:
    let
      inherit (builtins) map mapAttrs import;
      system = "x86_64-linux";
      this = import ./pkgs;
      nixcao = import "${nickpkgs}/pkgs";
      overlays = map (x: x.overlay) [
        this
        nixcao
        sops-nix
        deploy-rs
        berberman
        rust-overlay
      ];
      allModules = import ./modules;
      shareModules = with allModules; [
        base
        nix-config
        sops-nix.nixosModules.sops
        impermanence.nixosModules.impermanence
      ];
      desktopModules = with allModules; [
        clash
        plasma-env
        home.nixosModules.home-manager
      ];
      serverModules = with allModules; [
        cloud
        shadowsocks
      ];
      mkSystem = { hostname, config ? ./. + "/hosts/${hostname}", ... }: 
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            config
            { nixpkgs = { inherit overlays; }; }
          ] ++ shareModules ++ (if hostname == "local" then desktopModules else serverModules);
        };
      mkDeployNodes = { hostname, ... }: {
        sshUser = "root";
        sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
        hostname = "${hostname}.diffumist.me";
        profiles.system.path = deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations."${hostname}";
      };
    in
    {
      nixosConfigurations = {
        local = mkSystem { hostname = "local"; };
        dos = mkSystem { hostname = "dos"; };
        mist = mkSystem { hostname = "mist"; };
        vessel = mkSystem { hostname = "vessel"; };
      };
      deploy.nodes = {
        dos = mkDeployNodes { hostname = "dos"; };
        vessel = mkDeployNodes { hostname = "vessel"; };
        mist = mkDeployNodes { hostname = "mist"; };
      };
      checks = mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
