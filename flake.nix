{
  description = "diffumist's NixOS configuration";
  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://attic.xuyh0120.win/lantian"
      "https://attic.diffumist.me/nixos-config"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "nixos-config:zM4D3PAPLRe0q415xXHbluX6X0Zc9kuAlsArsEuuvqA="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    preservation.url = "github:nix-community/preservation/main";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
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
    nur-xddxdd = {
      url = "github:xddxdd/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-dn42 = {
      url = "git+https://git.sr.ht/~diffumist/nix-dn42";
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
          updatePackageHashes = pkgs.writeShellApplication {
            name = "nix-update-hashes";
            runtimeInputs = [ pkgs.nix-update ];
            text = ''
              for package in ${nixpkgs.lib.escapeShellArgs localPackages.updateablePackageNames}; do
                echo "==> $package"
                nix-update --flake --version=skip "$@" "$package"
              done
            '';
          };
        in
        {
          pre-commit.settings = {
            package = pkgs.prek;
            hooks = {
              detect-private-keys.enable = true;
              keep-sorted.enable = true;
              nixfmt.enable = true;
              pre-commit-hook-ensure-sops = {
                enable = true;
                files = "^hosts/[^/]+/.*\.(json|ya?ml|keytab)$";
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
                inputs.colmena.packages.${system}.colmena
                nix-update
                updatePackageHashes
                ssh-to-age
              ]
              ++ config.pre-commit.settings.enabledPackages;
            };
          formatter = pkgs.nixfmt;
          legacyPackages = pkgs;
          packages = localPackageSet // {
            bootstrap-image = self.nixosConfigurations.bootstrap.config.system.build.diskoImages;
          };
        };

      flake = {
        overlays.default = import ./overlay inputs;
        colmena = import ./hosts {
          inherit inputs self;
          hostFilter = _: h: h.deploy or true;
          outputMode = "colmena";
        };
        colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
        nixosConfigurations = import ./hosts { inherit inputs self; };
      };
    };
}
