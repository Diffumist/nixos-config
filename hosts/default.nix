{
  inputs,
  self,
  ...
}:
let
  lib = inputs.nixpkgs.lib;

  hasRole = role: host: lib.elem role host.roles;

  overlaysFor =
    host:
    lib.optionals (hasRole "desktop" host) [
      inputs.llm-agents.overlays.shared-nixpkgs
      inputs.nur-xddxdd.overlays.default
      inputs.nix-alien.overlays.default
      inputs.nix-cachyos-kernel.overlays.pinned
      inputs.nix-vscode-extensions.overlays.default
    ]
    ++ lib.optional (hasRole "dn42" host) inputs.nix-dn42.overlays.default
    ++ [ self.overlays.default ];

  insecurePackagesFor =
    host:
    lib.optionals (hasRole "desktop" host) [
      "electron-40.10.5"
    ];

  mkPkgs =
    host:
    import inputs.nixpkgs {
      inherit (host) system;
      overlays = overlaysFor host;
      config.allowUnfree = true;
      config.permittedInsecurePackages = insecurePackagesFor host;
    };

  defaultSystem = "x86_64-linux";
  defaultExternalModules = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.preservation.nixosModules.preservation
  ];

  allowedHostFields = [
    "buildOnTarget"
    "ciBuild"
    "deploy"
    "externalModules"
    "modules"
    "path"
    "roles"
    "stateVersion"
    "system"
    "tags"
    "targetHost"
    "targetPort"
    "targetUser"
  ];
  allowedRoles = [
    "container"
    "desktop"
    "dn42"
    "server"
  ];
  allowedTags = [
    "asia"
    "eu"
    "google"
    "us"
    "web"
  ];
  allowedSystems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
  inventory = {
    akilecloud-fra = {
      stateVersion = "25.11";
      roles = [ "server" ];
      tags = [ "eu" ];
    };
    bootstrap = {
      stateVersion = "25.11";
      roles = [ ];
      tags = [ ];
      deploy = false;
      ciBuild = false;
      externalModules = [
        inputs.disko.nixosModules.disko
        inputs.preservation.nixosModules.preservation
      ];
    };
    cloudnium-lax = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [
        "us"
        "web"
      ];
    };
    colocrossing-lax = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [
        "us"
        "web"
      ];
    };
    dedirock-lax = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
        "dn42"
      ];
      tags = [
        "us"
        "web"
      ];
    };
    google-east = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [
        "google"
        "us"
      ];
    };
    google-west = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [
        "google"
        "us"
      ];
    };
    geelinx-mys = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [ "asia" ];
    };
    geelinx-ord = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [
        "us"
        "web"
      ];
    };
    hawkpoint-lap = {
      stateVersion = "25.11";
      roles = [ "desktop" ];
      tags = [ ];
      deploy = false;
      ciBuild = true;
      modules = [
        inputs.home-manager.nixosModules.home-manager
        inputs.gaze.nixosModules.default
      ];
    };
    hostdzire-sfo = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
        "dn42"
      ];
      tags = [
        "us"
        "web"
      ];
    };
    liteserver-ams = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
        "dn42"
      ];
      tags = [
        "eu"
        "web"
      ];
    };
    lycheen-slc = {
      stateVersion = "25.11";
      roles = [ "server" ];
      tags = [ "us" ];
    };
    moecloud-sjc = {
      stateVersion = "25.11";
      roles = [ "server" ];
      tags = [ "us" ];
    };
    netcup-mnz = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [
        "us"
        "web"
      ];
    };
    netcup-nue = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
        "dn42"
      ];
      tags = [ "eu" ];
    };
    nixiso = {
      stateVersion = "25.11";
      roles = [ ];
      tags = [ ];
      deploy = false;
      ciBuild = false;
    };
    noboard-tyo = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
        "dn42"
      ];
      tags = [ "asia" ];
    };
    nosla-sjc = {
      stateVersion = "25.11";
      roles = [ "server" ];
      tags = [ "us" ];
    };
    raksmart-sjc = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [ "us" ];
    };
    vmiss-lax = {
      stateVersion = "25.11";
      roles = [ "server" ];
      tags = [
        "us"
        "web"
      ];
    };
    vmrack-lax = {
      stateVersion = "25.11";
      roles = [ "server" ];
      tags = [ "us" ];
    };
    wawo-hkg = {
      stateVersion = "25.11";
      roles = [
        "server"
        "dn42"
      ];
      tags = [ "asia" ];
    };
    vpstown-hkg = {
      stateVersion = "25.11";
      roles = [
        "server"
        "container"
      ];
      tags = [
        "asia"
        "web"
      ];
    };
  };

  normalizeHost =
    name: host:
    let
      unknownFields = lib.subtractLists allowedHostFields (lib.attrNames host);
      roles = host.roles or [ ];
      tags = host.tags or [ ];
      system = host.system or defaultSystem;
      path = host.path or (./. + "/${name}");
      deploy = host.deploy or true;
      ciBuild = host.ciBuild or deploy;
      buildOnTarget = host.buildOnTarget or false;
      externalModules = host.externalModules or defaultExternalModules;
      modules = host.modules or [ ];
      targetHost = host.targetHost or name;
      targetUser = host.targetUser or "root";
      requiresServer = lib.any (role: lib.elem role roles) [
        "container"
        "dn42"
      ];
    in
    assert lib.assertMsg (host ? stateVersion) "host ${name} must declare stateVersion";
    assert lib.assertMsg (
      builtins.isString host.stateVersion
      && builtins.match "[0-9][0-9]\\.[0-9][0-9]" host.stateVersion != null
    ) "host ${name} has invalid stateVersion ${toString host.stateVersion}";
    assert lib.assertMsg (unknownFields == [ ]) (
      "host ${name} has unknown fields: ${lib.concatStringsSep ", " unknownFields}"
    );
    assert lib.assertMsg (builtins.isList roles) "host ${name} roles must be a list";
    assert lib.assertMsg (builtins.isList tags) "host ${name} tags must be a list";
    assert lib.assertMsg (lib.all builtins.isString roles) "host ${name} roles must contain strings";
    assert lib.assertMsg (lib.all builtins.isString tags) "host ${name} tags must contain strings";
    assert lib.assertMsg (lib.unique roles == roles) "host ${name} has duplicate roles";
    assert lib.assertMsg (lib.unique tags == tags) "host ${name} has duplicate tags";
    assert lib.assertMsg (lib.subtractLists allowedRoles roles == [ ]) (
      "host ${name} has unknown roles: ${lib.concatStringsSep ", " (lib.subtractLists allowedRoles roles)}"
    );
    assert lib.assertMsg (lib.subtractLists allowedTags tags == [ ]) (
      "host ${name} has unknown tags: ${lib.concatStringsSep ", " (lib.subtractLists allowedTags tags)}"
    );
    assert lib.assertMsg (lib.elem system allowedSystems)
      "host ${name} has unsupported system ${system}";
    assert lib.assertMsg (builtins.isPath path) "host ${name} path must be a Nix path";
    assert lib.assertMsg (builtins.pathExists path)
      "host ${name} path does not exist: ${toString path}";
    assert lib.assertMsg (builtins.isBool deploy) "host ${name} deploy must be a boolean";
    assert lib.assertMsg (builtins.isBool ciBuild) "host ${name} ciBuild must be a boolean";
    assert lib.assertMsg (builtins.isBool buildOnTarget) "host ${name} buildOnTarget must be a boolean";
    assert lib.assertMsg (builtins.isList externalModules)
      "host ${name} externalModules must be a list";
    assert lib.assertMsg (builtins.isList modules) "host ${name} modules must be a list";
    assert lib.assertMsg (builtins.isString targetHost) "host ${name} targetHost must be a string";
    assert lib.assertMsg (builtins.isString targetUser) "host ${name} targetUser must be a string";
    assert lib.assertMsg (!deploy || lib.elem "server" roles) (
      "deployable host ${name} must have the server role"
    );
    assert lib.assertMsg (!requiresServer || lib.elem "server" roles) (
      "host ${name} roles container and dn42 require the server role"
    );
    host
    // {
      inherit
        ciBuild
        deploy
        path
        roles
        system
        tags
        ;
      inherit
        buildOnTarget
        externalModules
        modules
        targetHost
        targetUser
        ;
    };

  hosts = lib.mapAttrs normalizeHost inventory;
  tagsOf = host: lib.unique (host.tags ++ lib.optional (lib.elem "dn42" host.roles) "dn42");
  roleProfiles = {
    container = "${self}/profiles/roles/container.nix";
    dn42 = "${self}/profiles/roles/dn42.nix";
    server = "${self}/profiles/base/server.nix";
  };

  mkHostModules =
    name: host:
    [
      "${self}/modules/system/hostname.nix"
      {
        system.stateVersion = lib.mkForce host.stateVersion;
      }
    ]
    ++ lib.optional (lib.elem "server" host.roles) "${self}/modules/default.nix"
    ++ lib.concatMap (
      role: lib.optional (builtins.hasAttr role roleProfiles) roleProfiles.${role}
    ) host.roles
    ++ [ host.path ]
    ++ host.externalModules
    ++ host.modules;

  specialArgsFor = name: host: {
    inherit inputs self;
    hostName = name;
    hostPath = host.path;
    hostRoles = host.roles;
    hostTags = tagsOf host;
    overlays = overlaysFor host;
  };

  mkHost =
    name: host:
    let
      pkgs = mkPkgs host;
    in
    lib.nixosSystem {
      inherit pkgs;
      system = host.system;
      modules = mkHostModules name host;
      specialArgs = specialArgsFor name host;
    };

  mkColmenaNode = name: host: {
    imports = mkHostModules name host;
    deployment = {
      inherit (host) buildOnTarget targetHost targetUser;
      tags = tagsOf host;
    }
    // lib.optionalAttrs (host ? targetPort) {
      inherit (host) targetPort;
    };
  };

  mkColmenaHive =
    selectedHosts:
    {
      meta = {
        name = "nixos-config";
        nixpkgs = mkPkgs {
          system = defaultSystem;
          roles = [ ];
        };
        nodeNixpkgs = lib.mapAttrs (_: host: mkPkgs host) selectedHosts;
        specialArgs = {
          inherit inputs self;
        };
        nodeSpecialArgs = lib.mapAttrs specialArgsFor selectedHosts;
      };
    }
    // lib.mapAttrs mkColmenaNode selectedHosts;

  deployHosts = lib.filterAttrs (_: host: host.deploy) hosts;
  ciHosts = lib.filterAttrs (_: host: host.ciBuild) hosts;
in
{
  inherit hosts;
  ciHostNames = lib.attrNames ciHosts;
  colmena = mkColmenaHive deployHosts;
  nixosConfigurations = lib.mapAttrs mkHost hosts;
}
