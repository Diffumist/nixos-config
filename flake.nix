{
  description = "diffumist's NixOS configuration";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # utils
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    home = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # other pkgs
    nur = {
      url = "github:nix-community/NUR";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    daeuniverse.url = "github:daeuniverse/flake.nix";
    # secrets
    nix-secrets = {
      url = "git+ssh://git@github.com/Diffumist/nix-secrets";
    };
  };
  outputs = { self, nixpkgs, ... } @inputs:
    let
      this = import ./pkgs;
      overlays = [
        self.overlays.default
        inputs.berberman.overlays.default
        inputs.nix-vscode-extensions.overlays.default
        (final: prev: {
          alacritty = final.symlinkJoin {
            name = "alacritty";
            paths = [ prev.alacritty ];
            buildInputs = [ final.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/alacritty --unset WAYLAND_DISPLAY
            '';
          };
        })
      ];
    in
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ]
      (
        system:
        rec
        {
          pkgs = import nixpkgs {
            inherit overlays system;
            config.allowUnfree = true;
            config.permittedInsecurePackages = [
              "openssl-1.1.1u"
            ];
          };
          packages = this.packages pkgs;
          check = packages;
          legacyPackages = pkgs;
          devShells.default = with pkgs; mkShell {
            nativeBuildInputs = [
              sops
              age
              cachix
              colmena
              # nvfetcher
              nixpkgs-fmt
            ];
          };
        }
      ) // {
      overlays.default = this.overlay;
      nixosConfigurations =
        let
          hosts = builtins.attrNames (builtins.readDir ./nixos);
          mkSystem = hostname:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs self;
                inherit (inputs.nix-secrets) secrets;
              };
              modules = [{ nixpkgs = { inherit overlays; }; }]
              ++ [ (import (./nixos + "/${hostname}")) ];
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
            targetHost = "108.166.217.159";
            targetPort = 2222;
          };
          imports = [ ./nixos/${name} ];
        };
        nixlab = { name, ... }: {
          deployment = {
            targetHost = "192.168.0.252";
            targetPort = 2222;
          };
          imports = [ ./nixos/${name} ];
        };
      };
    };
}
