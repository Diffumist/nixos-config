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
    nickpkgs = {
      url = "github:NickCao/flakes";
      flake = false;
    };
    # secrets
    nix-secrets = {
      url = "github:Diffumist/nix-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nix-secrets, nixpkgs, utils, ... } @inputs:
    let
      system = "x86_64-linux";
      this = import ./pkgs;
      nixcao = import "${inputs.nickpkgs}/pkgs";
      other.overlay = final: prev: {
        # Ref: https://github.com/NickCao/flakes/blob/08044fc9e40fab5eec0dbcb336777477a6d4bfaa/nixos/local/default.nix#L21
        alacritty = final.symlinkJoin {
          name = "alacritty";
          paths = [ prev.alacritty ];
          buildInputs = [ final.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/alacritty --unset WAYLAND_DISPLAY
          '';
        };
      };
      overlays = with inputs; map (x: x.overlay) [
        nur
        self
        other
        nixcao
        sops-nix
        deploy-rs
        berberman
        rust-overlay
      ];
      nixosModules = import ./modules ++ [
        inputs.sops-nix.nixosModules.sops
        inputs.impermanence.nixosModules.impermanence
        inputs.home.nixosModules.home-manager
      ];
      mkSystem = hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            inherit (nix-secrets) secrets;
          };
          modules = [{ nixpkgs = { inherit overlays; }; }]
            ++ hostname
            ++ nixosModules;
        };
      mkDeployNodes = hostname: {
        sshUser = "root";
        sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
        hostname = "${hostname}.diffumist.me";
        profiles.system.path = inputs.deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations."${hostname}";
      };
    in
    {
      overlay = this.overlay;
      nixosConfigurations = {
        local = mkSystem [ ./hosts/local ];
        mist = mkSystem [ ./hosts/mist ];
        vessel = mkSystem [ ./hosts/vessel ];
      };
      deploy.nodes = {
        vessel = mkDeployNodes "vessel";
        mist = mkDeployNodes "mist";
      };
    } // utils.lib.eachSystem [ "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
        in
        rec {
          packages = this.packages pkgs;
          checks = packages // (inputs.deploy-rs.lib."${system}".deployChecks {
            nodes = pkgs.lib.filterAttrs (name: cfg: cfg.profiles.system.path.system == system) self.deploy.nodes;
          });
          legacyPackages = pkgs;
          devShell = with pkgs; mkShell {
            nativeBuildInputs = [
              deploy-rs.deploy-rs 
              nvfetcher
              nixpkgs-fmt
            ];
          };
        }
      );
}
