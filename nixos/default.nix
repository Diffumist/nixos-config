{
  inputs,
  self,
  hostFilter ? (_: _: true),
  ...
}:
let
  lib = inputs.nixpkgs.lib;
  overlays = [
    self.overlays.default
    inputs.llm-agents.overlays.default
    inputs.quickshell.overlays.default
    inputs.nix-cachyos-kernel.overlays.default
    inputs.nix-vscode-extensions.overlays.default
    inputs.nix-dn42.overlays.default
  ];
  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };

  defaults = {
    extra = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.hermes-agent.nixosModules.default
      inputs.impermanence.nixosModules.impermanence
      inputs.nur-xddxdd.nixosModules.setupOverlay
      inputs.nix-dn42.nixosModules.default
    ];
  };

  hosts = {
    hawkpoint = {
      system = "x86_64-linux";
      path = ./hawkpoint;
      deploy = false;
      useCommon = false;
      extra = defaults.extra ++ [
        inputs.home-manager.nixosModules.home-manager
      ];
    };
    phoenix = {
      system = "x86_64-linux";
      path = ./phoenix;
      deploy = true;
    };
    liteserver = {
      system = "x86_64-linux";
      path = ./liteserver;
      deploy = true;
    };
    geelinx-jp = {
      system = "x86_64-linux";
      path = ./geelinx-jp;
      deploy = true;
    };
    geelinx-mys = {
      system = "x86_64-linux";
      path = ./geelinx-mys;
      deploy = false;
    };
    noboard = {
      system = "x86_64-linux";
      path = ./noboard;
      deploy = true;
    };
    wawo = {
      system = "x86_64-linux";
      path = ./wawo;
      deploy = true;
    };
    nosla-lax = {
      system = "x86_64-linux";
      path = ./nosla-lax;
      deploy = true;
    };
    nosla-sjc = {
      system = "x86_64-linux";
      path = ./nosla-sjc;
      deploy = true;
    };
    vmrack = {
      system = "x86_64-linux";
      path = ./vmrack;
      deploy = true;
    };
    dedirock = {
      system = "x86_64-linux";
      path = ./dedirock;
      deploy = true;
    };
    hostdzire = {
      system = "x86_64-linux";
      path = ./hostdzire;
      deploy = true;
    };
    colocrossing = {
      system = "x86_64-linux";
      path = ./colocrossing;
      deploy = true;
    };
    solidvps = {
      system = "x86_64-linux";
      path = ./solidvps;
      deploy = true;
    };
    nixiso = {
      system = "x86_64-linux";
      path = ./nixiso;
      deploy = false;
      useCommon = false;
    };
    bootstrap = {
      system = "x86_64-linux";
      path = ./bootstrap;
      deploy = false;
      useCommon = false;
      extra = [
        inputs.disko.nixosModules.disko
        inputs.impermanence.nixosModules.impermanence
      ];
    };
  };

  mkHost =
    name: h:
    let
      system = h.system;
      pkgs = mkPkgs system;
      extra = h.extra or defaults.extra;
      useCommon = h.useCommon or true;
    in
    lib.nixosSystem {
      inherit system pkgs;
      modules = (lib.optional useCommon ./common) ++ [ h.path ] ++ extra;
      specialArgs = {
        inherit inputs overlays;
        hostName = name;
      };
    };
in
lib.mapAttrs mkHost (lib.filterAttrs hostFilter hosts)
