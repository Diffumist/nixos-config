{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";

    flake-utils.url = "github:numtide/flake-utils";
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
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    let
      this = import ./pkgs;
    in
    {
      nixosConfigurations = {
        local = import ./nixos/hosts/local { system = "x86_64-linux"; inherit self nixpkgs inputs this; };
        server = import ./nixos/hosts/server { system = "x86_64-linux"; inherit self nixpkgs inputs this; };
      };
      deploy.nodes = {
        server = {
          sshUser = "root";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          hostname = "host.diffumist.me";
          profiles.system.path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.server;
        };
      };
    }
    // flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (system:
        rec {
          # Ref: https://gitlab.com/NickCao/flakes/-/blob/master/flake.nix#L79
          checks = this // (inputs.deploy-rs.lib.${system}.deployChecks {
            node = this.lib.filterAttrs (name: cfg: cfg.profiles.system.path.system == system) self.deploy.nodes;
          });
        }
      );
}
