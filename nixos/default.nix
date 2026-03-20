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
    inputs.quickshell.overlays.default
    inputs.nix-cachyos-kernel.overlays.pinned
    inputs.nix-vscode-extensions.overlays.default
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
      inputs.impermanence.nixosModules.impermanence
      inputs.nur-xddxdd.nixosModules.setupOverlay
      inputs.nur-xddxdd.nixosModules.nix-cache-attic
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
        inputs.dms-plugin-registry.modules.default
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
    # colocrossing = {
    #   system = "x86_64-linux";
    #   path = ./colocrossing;
    # };
    # solidvps = {
    #   system = "x86_64-linux";
    #   path = ./solidvps;
    # };
    # dedirock = {
    #   system = "x86_64-linux";
    #   path = ./dedirock;
    # };
    # qiniu = {
    #   system = "x86_64-linux";
    #   path = ./qiniu;
    # };
    bitsflow = {
      system = "x86_64-linux";
      path = ./bitsflow;
      deploy = true;
    };
    nixiso = {
      system = "x86_64-linux";
      path = ./nixiso;
      deploy = false;
      useCommon = false;
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
