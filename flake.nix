{
  description = "diffumist's NixOS configuration";
  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    preservation.url = "github:nix-community/preservation/main";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:nix-community/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    nur-xddxdd.url = "github:xddxdd/nur-packages";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    system76-scheduler-niri = {
      url = "github:Kirottu/system76-scheduler-niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-dn42 = {
      url = "git+https://git.418.cat/DiffFork/nix-dn42?ref=sing-tun";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dn42-registry = {
      url = "git+https://git.lantian.pub/backup/dn42-registry.git";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.git-hooks-nix.flakeModule ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { config, system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
          localPackages = import ./pkgs { lib = nixpkgs.lib; };
          localPackageSet = localPackages.fromPkgs pkgs inputs;
          availableLocalPackages = nixpkgs.lib.filterAttrs (
            _: package: nixpkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform package
          ) localPackageSet;
          updatePackage =
            package:
            let
              useUpdateScript = localPackageSet.${package}.nixUpdateUseUpdateScript or false;
              updateScriptFlag = nixpkgs.lib.optionalString useUpdateScript "--use-update-script";
            in
            ''
              echo "==> ${package}"
              nix-update --flake ${updateScriptFlag} "$@" ${nixpkgs.lib.escapeShellArg package}
            '';
          updatePackageHashes = pkgs.writeShellApplication {
            name = "nix-update-hashes";
            runtimeInputs = [ pkgs.nix-update ];
            text = nixpkgs.lib.concatMapStrings updatePackage localPackages.updateablePackageNames;
          };
        in
        {
          pre-commit.settings = {
            hooks = {
              detect-private-keys.enable = true;
              keep-sorted.enable = true;
              nixfmt.enable = true;
              pre-commit-hook-ensure-sops = {
                enable = true;
                files = "^(hosts/[^/]+/.*|profiles/common/secrets/.*)\.(json|ya?ml|keytab)$";
              };
            };
          };

          devShells.default =
            with pkgs;
            mkShell {
              shellHook = config.pre-commit.shellHook;
              nativeBuildInputs = [
                age
                sops
                ninja
                nix-update
                ssh-to-age
                bashInteractive
                updatePackageHashes
                inputs.colmena.packages.${system}.colmena
              ]
              ++ config.pre-commit.settings.enabledPackages;
            };
          formatter = pkgs.nixfmt;
          legacyPackages = pkgs;
          packages =
            availableLocalPackages
            // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
              bootstrap-image = self.nixosConfigurations.bootstrap.config.system.build.diskoImages;
            };
        };

      flake =
        let
          hostOutputs = import ./hosts { inherit inputs self; };
        in
        {
          overlays.default = import ./overlay inputs;
          inherit (hostOutputs) colmena nixosConfigurations;
          colmenaHive = inputs.colmena.lib.makeHive hostOutputs.colmena;
          lib.ciHostNames = hostOutputs.ciHostNames;
        };
    };
}
