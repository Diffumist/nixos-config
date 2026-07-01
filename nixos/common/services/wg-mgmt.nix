{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.wg-mgmt;
  links = lib.attrValues cfg.links;
  mkPeer =
    link:
    {
      PublicKey = link.publicKey;
      AllowedIPs = link.allowedIPs;
      PersistentKeepalive = link.persistentKeepalive;
    }
    // lib.optionalAttrs (link.endpoint != null) {
      Endpoint = "${link.endpoint}:${toString link.port}";
    };
in
{
  options.my.services.wg-mgmt = {
    enable = lib.mkEnableOption "WireGuard management overlay";

    interface = lib.mkOption {
      type = lib.types.str;
      default = "wg-mgmt";
      description = "WireGuard interface name for the management overlay.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 44242;
      description = "UDP listen port for the management overlay.";
    };

    ipv4 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Host IPv4 address on the management overlay.";
    };

    ipv6 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Host IPv6 ULA address on the management overlay.";
    };

    links = lib.mkOption {
      default = { };
      description = "Management overlay links from this host to other overlay members.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            endpoint = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Remote endpoint host or address. Null means passive inbound-only.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 44242;
              description = "Remote WireGuard UDP port.";
            };

            publicKey = lib.mkOption {
              type = lib.types.str;
              description = "Remote WireGuard public key.";
            };

            allowedIPs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Remote management addresses routed through this link.";
            };

            persistentKeepalive = lib.mkOption {
              type = lib.types.ints.positive;
              default = 25;
              description = "Persistent keepalive interval in seconds.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.ipv4 != null || cfg.ipv6 != null;
        message = "my.services.wg-mgmt requires at least one of ipv4 or ipv6.";
      }
      {
        assertion = cfg.links != { };
        message = "my.services.wg-mgmt requires at least one configured link.";
      }
    ];

    sops.secrets.wg_mgmt_private_key = {
      owner = "systemd-network";
      mode = "0400";
    };

    networking.firewall.allowedUDPPorts = [ cfg.listenPort ];

    systemd.network.netdevs."20-${cfg.interface}" = {
      netdevConfig = {
        Name = cfg.interface;
        Kind = "wireguard";
      };
      wireguardConfig = {
        ListenPort = cfg.listenPort;
        PrivateKeyFile = config.sops.secrets.wg_mgmt_private_key.path;
      };
      wireguardPeers = map mkPeer links;
    };

    systemd.network.networks."20-${cfg.interface}" = {
      matchConfig.Name = cfg.interface;
      address =
        lib.optional (cfg.ipv4 != null) "${cfg.ipv4}/32"
        ++ lib.optional (cfg.ipv6 != null) "${cfg.ipv6}/128";
      linkConfig.RequiredForOnline = "no";
      networkConfig = {
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
      };
    };
  };
}
