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
    flake-utils.url = "github:numtide/flake-utils";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
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
    preservation.url = "github:nix-community/preservation/main";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nix-dn42 = {
      url = "git+https://git.sr.ht/~prince213/nix-dn42";
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
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
      ]
      (
        system:
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
          devShells.default =
            with pkgs;
            mkShell {
              nativeBuildInputs = [
                age
                sops
                ninja
                inputs.colmena.packages.${system}.colmena
                nix-update
                updatePackageHashes
                ssh-to-age
              ];
            };
          formatter = pkgs.nixfmt;
          packages = localPackageSet // {
            bootstrap-image = self.nixosConfigurations.bootstrap.config.system.build.diskoImages;
          };
        }
      )
    // {
      overlays.default = import ./overlay inputs;
      colmena = import ./nixos {
        inherit inputs self;
        hostFilter = _: h: h.deploy or true;
        outputMode = "colmena";
      };
      colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
      nixosConfigurations = import ./nixos { inherit inputs self; };
    };
}
