{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    xdgify-overlay = {
      url = "github:oxalica/xdgify-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nickcao = {
      url = "gitlab:nickcao/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  # Ref: https://github.com/oxalica/config
  outputs = inputs:
    let
      inherit (inputs.nixpkgs) lib;

      prToOverlay = pr: pathStrs: final: prev:
        with lib;
        foldl' recursiveUpdate prev (
          map
            (
              pathStr:
              let
                pathList = splitString "." pathStr;
              in
              setAttrByPath pathList (getAttrFromPath pathList pr.legacyPackages.${final.system})
            )
            pathStrs
        );

      overlays = {
        rust-overlay = inputs.rust-overlay.overlay;
        xdgify-overlay = inputs.xdgify-overlay.overlay;
        berberman-overlay = inputs.berberman.overlay;
        nickcao-overlay = inputs.nickcao.overlay;
      };

      mkSystem = system: overlays: modules: inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs.inputs = inputs;
        modules = [
          inputs.home-manager.nixosModules.home-manager
          { nixpkgs.overlays = overlays; }
          ({ lib, ... }: {
            options.home-manager.users = with lib.types; lib.mkOption {
              type = attrsOf (
                submoduleWith {
                  modules = [ ];
                  specialArgs.inputs = inputs;
                });
            };
          })
        ] ++ modules;
      };

    in
    {
      nixosConfigurations = {
        local = mkSystem "x86_64-linux"
          (with overlays; [
            rust-overlay
            xdgify-overlay
            berberman-overlay
            nickcao-overlay
          ])
          [ ./nixos/hosts/local/configuration.nix ];
      };
    };
}
