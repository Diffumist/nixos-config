{
  inputs,
  self,
  hostFilter ? (_: _: true),
  outputMode ? "systems",
  ...
}:
let
  lib = inputs.nixpkgs.lib;
  overlays = [
    self.overlays.default
    inputs.llm-agents.overlays.default
    inputs.quickshell.overlays.default
    inputs.nix-cachyos-kernel.overlays.pinned
    inputs.nix-vscode-extensions.overlays.default
    inputs.nix-dn42.overlays.default
  ];
  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
      config.permittedInsecurePackages = [
        "pnpm-10.29.2"
      ];
    };

  defaults = {
    system = "x86_64-linux";
    extra = [
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.preservation.nixosModules.preservation
      inputs.nur-xddxdd.nixosModules.setupOverlay
      inputs.nix-dn42.nixosModules.default
    ];
  };

  hostNames = [
    "bootstrap"
    "carolina"
    "colocrossing"
    "dedirock"
    "geelinx-jp"
    "geelinx-mys"
    "geelinx-us"
    "hawkpoint"
    "hostdzire"
    "liteserver"
    "nixiso"
    "noboard"
    "nosla-lax"
    "nosla-sjc"
    "oregon"
    "phoenix"
    "sla-sjc"
    "solidvps"
    "vmrack"
    "wawo"
  ];

  hostTags = {
    asia = [
      "geelinx-jp"
      "geelinx-mys"
      "noboard"
      "wawo"
    ];
    dn42 = [
      "hostdzire"
      "liteserver"
      "dedirock"
      "geelinx-jp"
      "wawo"
    ];
    eu = [ "liteserver" ];
    gcp = [
      "carolina"
      "oregon"
    ];
    sing-box = [
      "noboard"
      "nosla-lax"
      "nosla-sjc"
      "sla-sjc"
      "vmrack"
    ];
    us = [
      "carolina"
      "colocrossing"
      "dedirock"
      "geelinx-us"
      "hostdzire"
      "nosla-lax"
      "nosla-sjc"
      "oregon"
      "phoenix"
      "sla-sjc"
      "solidvps"
      "vmrack"
    ];
    web-server = [
      "colocrossing"
      "dedirock"
      "geelinx-us"
      "hostdzire"
      "liteserver"
      "phoenix"
      "solidvps"
    ];
  };

  hosts = lib.genAttrs hostNames (_: { }) // {
    hawkpoint = {
      deploy = false;
      useCommon = false;
      extra = defaults.extra ++ [
        inputs.home-manager.nixosModules.home-manager
      ];
    };
    geelinx-mys.deploy = false;
    nixiso = {
      deploy = false;
      useCommon = false;
    };
    bootstrap = {
      deploy = false;
      useCommon = false;
      extra = [
        inputs.disko.nixosModules.disko
        inputs.preservation.nixosModules.preservation
      ];
    };
  };

  systemOf = h: h.system or defaults.system;
  tagsOf = name: lib.filter (tag: lib.elem name hostTags.${tag}) (lib.attrNames hostTags);

  mkHost =
    name: h:
    let
      system = systemOf h;
      pkgs = mkPkgs system;
    in
    lib.nixosSystem {
      inherit system pkgs;
      modules = mkHostModules name h;
      specialArgs = {
        inherit inputs overlays;
        hostName = name;
      };
    };

  mkHostModules =
    name: h:
    let
      extra = h.extra or defaults.extra;
      path = h.path or (./. + "/${name}");
      useCommon = h.useCommon or true;
    in
    (lib.optional useCommon ./common) ++ [ path ] ++ extra;

  mkColmenaNode = name: h: {
    imports = mkHostModules name h;
    deployment = {
      targetHost = h.targetHost or name;
      targetUser = h.targetUser or "root";
      tags = tagsOf name;
      buildOnTarget = h.buildOnTarget or false;
    }
    // lib.optionalAttrs (h ? targetPort) {
      inherit (h) targetPort;
    };
  };

  mkColmenaHive =
    hosts:
    {
      meta = {
        name = "nixos-config";
        allowApplyAll = false;
        nixpkgs = mkPkgs "x86_64-linux";
        nodeNixpkgs = lib.mapAttrs (_name: h: mkPkgs (systemOf h)) hosts;
        specialArgs = {
          inherit inputs overlays;
        };
        nodeSpecialArgs = lib.mapAttrs (name: _h: { hostName = name; }) hosts;
      };
    }
    // lib.mapAttrs mkColmenaNode hosts;
in
let
  filteredHosts = lib.filterAttrs hostFilter hosts;
in
if outputMode == "hosts" then
  filteredHosts
else if outputMode == "colmena" then
  mkColmenaHive filteredHosts
else
  lib.mapAttrs mkHost filteredHosts
