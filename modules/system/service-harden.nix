{
  config,
  helpers,
  lib,
  ...
}:
let
  requiredKeys = builtins.attrNames helpers.systemd.serviceHarden;

  # Core system services that legitimately need full host privileges.
  ignored = [
    "dbus"
    "dbus-broker"
    "kmod-static-nodes"
    "lastlog2-import"
    "nix-daemon"
    "nix-optimise"
    "nscd"
    "podman"
    "reload-systemd-vconsole-setup"
    "sshd"
    # IPsec management mesh (charon + XFRM updown scripts); verify separately via tests/ranet.nix.
    "strongswan-swanctl"
  ];

  exempt =
    n: v:
    builtins.elem n ignored
    || lib.hasInfix "@" n
    || !(v.enable or true)
    || (builtins.elem (v.serviceConfig.Type or "") [
      "oneshot"
      "dbus"
    ])
    || lib.hasPrefix "docker-" n
    || lib.hasPrefix "podman-" n
    || lib.hasPrefix "systemd" n;
in
{
  options = {
    my.systemd.harden = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Services given the baseline sandbox from helpers.systemd.serviceHarden.
        Every field is mkOptionDefault, so upstream and per-service settings win.
      '';
    };

    # Every confined service gets DNS, hosts, timezone and CA files, and no /bin/sh.
    systemd.services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            config = lib.mkIf config.confinement.enable {
              confinement.binSh = lib.mkDefault null;
              serviceConfig.BindReadOnlyPaths = [
                "-/etc/ssl/certs/ca-certificates.crt"
                "-/etc/ssl/certs/ca-bundle.crt"
                "-/etc/resolv.conf"
                "-/etc/hosts"
                "-/etc/nsswitch.conf"
                "-/etc/services"
                "-/etc/protocols"
                "-/etc/localtime"
              ];
            };
          }
        )
      );
    };
  };

  config = {
    systemd.services = lib.genAttrs config.my.systemd.harden (_: {
      serviceConfig = helpers.systemd.serviceHarden;
    });

    # Checks that each option is set, not what it is set to: a service that
    # needs an exception still has to spell it out.
    assertions = lib.mapAttrsToList (
      n: v:
      let
        # builtins.hasAttr rather than `?` with a variable key (Nix 2.35 bug).
        missing = lib.filter (k: !builtins.hasAttr k v.serviceConfig) requiredKeys;
      in
      {
        assertion = exempt n v || missing == [ ];
        message = "${n} is missing systemd service hardening options (add it to my.systemd.harden): ${lib.concatStringsSep ", " missing}";
      }
    ) config.systemd.services;
  };
}
