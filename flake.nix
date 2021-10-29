{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixos.url = "github:nixos/nixpkgs/release-21.05";
    latest.url = "github:nixos/nixpkgs/nixos-unstable";

    blank.follows = "digga/blank";
    nixlib.follows = "digga/nixlib";
    flake-utils.follows = "digga/flake-utils";
    flake-utils-plus.follows = "digga/flake-utils-plus";
    deploy-rs.follows = "digga/deploy";
    flake-compat.follows = "digga/deploy/flake-compat";

    digga = {
      url = "github:divnix/digga";
      inputs.nixpkgs.follows = "latest";
      inputs.home-manager.follows = "home";
    };
    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "latest";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "latest";
      inputs.flake-utils.follows = "flake-utils";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "latest";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "latest";
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
    , latest
    , digga
    , deploy-rs
    , sops-nix
    , home
    , nixos
    , flake-utils
    , ...
    } @ inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (
        system:
        let
          pkgs = import latest {
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
        local = import ./nixos/hosts/local { system = "x86_64-linux"; inherit self latest inputs; };
        dos = import ./nixos/hosts/dos { system = "x86_64-linux"; inherit self latest inputs; };
        vessel = import ./nixos/hosts/vessel { system = "x86_64-linux"; inherit self latest inputs; };
        mist = import ./nixos/hosts/mist { system = "x86_64-linux"; inherit self latest inputs; };
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
