{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.dn42.flapDamping;

  bgpPort = 11790;
  httpPort = 11791;
  rtrPort = 11792;
  metricsPort = 11793;
  formatHttpHost = address: if lib.hasInfix ":" address then "[${address}]" else address;
in
{
  options.my.services.dn42.flapDamping = {
    enable = lib.mkEnableOption "DN42 flap damping via FlapAlerted";

    runServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run the central FlapAlerted instance on this host.";
    };

    serverAddress = lib.mkOption {
      type = lib.types.str;
      description = "Address of the central FlapAlerted instance.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.dn42.enable;
        message = "my.services.dn42.flapDamping requires networking.dn42.enable.";
      }
      {
        assertion = config.networking.dn42.roa.enable;
        message = "my.services.dn42.flapDamping requires networking.dn42.roa.enable.";
      }
    ];

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.runServer [
      bgpPort
      httpPort
    ];

    services.bird.config = lib.mkBefore ''
      roa4 table roa_flap_v4;
      roa6 table roa_flap_v6;

      protocol rpki rpki_flapalerted {
        roa4 { table roa_flap_v4; };
        roa6 { table roa_flap_v6; };
        remote 127.0.0.1 port ${toString rtrPort};
        max version 1;
        retry keep 10;
      }

      protocol bgp flapalerted {
        hostname "${config.networking.hostName}";
        advertise hostname on;
        local as ${toString config.networking.dn42.asn};
        neighbor ${cfg.serverAddress} as ${toString config.networking.dn42.asn} port ${toString bgpPort};
        multihop;

        ipv4 {
          add paths on;
          export all;
          import none;
        };
        ipv6 {
          add paths on;
          export all;
          import none;
        };
      }
    '';

    systemd.services.flapalerted = lib.mkIf cfg.runServer {
      description = "FlapAlerted";
      before = [ "bird.service" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        exec ${lib.getExe pkgs.flapalerted} \
          --asn ${toString config.networking.dn42.asn} \
          --bgpListenAddress ${formatHttpHost cfg.serverAddress}:${toString bgpPort} \
          --httpAPIListenAddress ${formatHttpHost cfg.serverAddress}:${toString httpPort} \
          -routeChangeCounter 120 \
          -overThresholdTarget 5 \
          -underThresholdTarget 30
      '';
      serviceConfig = {
        DynamicUser = true;
        Restart = "always";
        RestartSec = "3s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };

    systemd.services.stayrtr-flapalerted = {
      description = "StayRTR for FlapAlerted";
      before = [ "bird.service" ];
      after = [ "network.target" ] ++ lib.optionals cfg.runServer [ "flapalerted.service" ];
      wants = lib.optionals cfg.runServer [ "flapalerted.service" ];
      wantedBy = [ "multi-user.target" ];
      script = ''
        exec ${lib.getExe pkgs.stayrtr} \
          --bind 127.0.0.1:${toString rtrPort} \
          --metrics.addr 127.0.0.1:${toString metricsPort} \
          --cache http://${formatHttpHost cfg.serverAddress}:${toString httpPort}/flaps/active/roa \
          --rtr.expire 3600 \
          --rtr.refresh 300 \
          --rtr.retry 300
      '';
      serviceConfig = {
        DynamicUser = true;
        Restart = "always";
        RestartSec = "3s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };
  };
}
