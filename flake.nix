{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    blank.follows = "digga/blank";
    nixlib.follows = "digga/nixlib";
    flake-utils.follows = "digga/flake-utils";
    flake-utils-plus.follows = "digga/flake-utils-plus";
    deploy-rs.follows = "digga/deploy";
    flake-compat.follows = "digga/deploy/flake-compat";

    digga = {
      url = "github:divnix/digga";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home";
    };
    home = {
      url = "github:nix-community/home-manager";
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
      url = "github:NickCao/flakes?dir=pkgs";
      flake = false;
    };
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs =
    { self
    , nixpkgs
    , digga
    , home
    , flake-utils
    , rust-overlay
    , deploy-rs
    , sops-nix
    , berberman
    , impermanence
    , ...
    } @ inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              deploy-rs.overlay
              rust-overlay.overlay
              sops-nix.overlay
            ];
          };
        in
        rec {
          checks = (deploy-rs.lib.${system}.deployChecks {
            nodes = pkgs.lib.filterAttrs (name: cfg: cfg.profiles.system.path.system == system) self.deploy.nodes;
          });
          devShell = with pkgs; mkShell {
            buildInputs = [
              nvfetcher
              deploy-rs
              ssh-to-age
              age
            ];
          };
        }
      ) //
    {
      nixosModules = import ./modules;
      nixosConfigurations = {
        local = import ./nixos/local { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        dos = import ./nixos/dos { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        vessel = import ./nixos/vessel { system = "x86_64-linux"; inherit self nixpkgs inputs; };
        mist = import ./nixos/mist { system = "x86_64-linux"; inherit self nixpkgs inputs; };
      };
      deploy.nodes = {
        dos = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "dos.diffumist.me";
          profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.dos;
        };
        vessel = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "vessel.diffumist.me";
          profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.vessel;
        };
        mist = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "mist.diffumist.me";
          profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.mist;
        };
      };
    };
}
