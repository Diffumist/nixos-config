{
  description = "diffumist's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-20.09";

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
    nixos-cn = {
      url = "github:nixos-cn/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

  };
  # Ref: https://github.com/oxalica/config
  outputs = inputs:
    let
      pkgDir = ./pkgs;

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
        tdesktop-font = final: prev: {
          tdesktop = prev.tdesktop.overrideAttrs (
            oldAttrs: {
              patches = (oldAttrs.patches or []) ++ [ ./patches/tdesktop-0001-use-system-font-and-use-stylename.patch ];
            }
          );
        };
      };

      # Ref: https://github.com/dramforever/config/blob/63be844019b7ca675ea587da3b3ff0248158d9fc/flake.nix#L24-L28
      system-label = let
        inherit (inputs) self;
      in
        {
          system.configurationRevision = self.rev or null;
          system.nixos.label =
            if self.sourceInfo ? lastModifiedDate && self.sourceInfo ? shortRev
            then "${lib.substring 0 8 self.sourceInfo.lastModifiedDate}.${self.sourceInfo.shortRev}"
            else lib.warn "Repo is dirty, revision will not be available in system label" "dirty";
        };

      mkSystem = system: overlays: modules: inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs.inputs = inputs;
        modules = [
          system-label
          inputs.nixos-cn.nixosModules.nixos-cn-registries
          inputs.home-manager.nixosModules.home-manager
          { nixpkgs.overlays = overlays; }
          (
            { lib, ... }: {
              options.home-manager.users = with lib.types; lib.mkOption {
                type = attrsOf (
                  submoduleWith {
                    modules = [];
                    specialArgs.inputs = inputs;
                  }
                );
              };
            }
          )
        ] ++ modules;
      };

    in
      {
        nixosConfigurations = {
          local = mkSystem "x86_64-linux"
            (with overlays; [ rust-overlay xdgify-overlay tdesktop-font ])
            [ ./nixos/hosts/local/configuration.nix ];
        };
      };
}
