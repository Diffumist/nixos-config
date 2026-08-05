{
  config,
  lib,
  ...
}:
let
  cfg = config.my.networking.static;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  ipv4AddressSecrets = [ cfg.ipv4.addressSecret ];
  ipv6AddressSecrets = lib.optionals cfg.ipv6.enable (
    [ cfg.ipv6.addressSecret ] ++ cfg.ipv6.extraAddressSecrets
  );
  addressLines =
    map (
      secret: "Address=${config.sops.placeholder.${secret}}/${toString cfg.ipv4.prefixLength}"
    ) ipv4AddressSecrets
    ++ map (
      secret: "Address=${config.sops.placeholder.${secret}}/${toString cfg.ipv6.prefixLength}"
    ) ipv6AddressSecrets;
  gatewayLines = [
    "Gateway=${config.sops.placeholder.${cfg.ipv4.gatewaySecret}}"
  ]
  ++
    lib.optional (cfg.ipv6.enable && !cfg.ipv6.gatewayOnLink)
      "Gateway=${config.sops.placeholder.${cfg.ipv6.gatewaySecret}}";
  networkLines = [
    "[Match]"
    "MACAddress=${cfg.macAddress}"
    ""
    "[Network]"
  ]
  ++ addressLines
  ++
    lib.optional (cfg.ipv6.acceptRA != null)
      "IPv6AcceptRA=${if cfg.ipv6.acceptRA then "yes" else "no"}"
  ++ gatewayLines
  ++ map (server: "DNS=${server}") cfg.dns
  ++ lib.optionals cfg.ipv6.gatewayOnLink [
    ""
    "[Route]"
    "Destination=::/0"
    "Gateway=${config.sops.placeholder.${cfg.ipv6.gatewaySecret}}"
    "GatewayOnLink=yes"
  ];
  secretNames =
    ipv4AddressSecrets
    ++ [ cfg.ipv4.gatewaySecret ]
    ++ ipv6AddressSecrets
    ++ lib.optional cfg.ipv6.enable cfg.ipv6.gatewaySecret;
in
{
  options.my.networking.static = {
    enable = mkEnableOption "SOPS-rendered static systemd-networkd configuration";

    macAddress = mkOption {
      type = types.strMatching "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}";
      description = "Permanent MAC address of the interface to match";
    };

    ipv4 = {
      addressSecret = mkOption {
        type = types.str;
        default = "ipv4_address";
      };
      gatewaySecret = mkOption {
        type = types.str;
        default = "ipv4_gateway";
      };
      prefixLength = mkOption {
        type = types.ints.between 0 32;
      };
    };

    ipv6 = {
      enable = mkEnableOption "static IPv6 configuration";
      addressSecret = mkOption {
        type = types.str;
        default = "ipv6_address";
      };
      extraAddressSecrets = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      gatewaySecret = mkOption {
        type = types.str;
        default = "ipv6_gateway";
      };
      prefixLength = mkOption {
        type = types.ints.between 0 128;
        default = 64;
      };
      acceptRA = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      gatewayOnLink = mkOption {
        type = types.bool;
        default = false;
      };
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [
        "1.0.0.1"
        "8.8.4.4"
        "2606:4700:4700::1001"
        "2001:4860:4860::8844"
      ];
    };
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = lib.genAttrs secretNames (_: { });
      templates."10-lan.network" = {
        path = "/etc/systemd/network/10-lan.network";
        owner = "systemd-network";
        content = lib.concatStringsSep "\n" networkLines + "\n";
      };
    };
  };
}
