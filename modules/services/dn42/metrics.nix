{
  config,
  hostName,
  lib,
  ...
}:
let
  cfg = config.my.services.dn42.metrics;
  dn42 = config.my.services.dn42;
  mesh = dn42.mesh;
  monitoring = config.my.services.monitoring-agent;

  nodeNames = builtins.attrNames mesh.nodes;
  localNodeName = lib.findFirst (name: mesh.nodes.${name}.hostName == hostName) null nodeNames;
  enabled = cfg.enable && mesh.enable && localNodeName != null;

  linkNodes = link: lib.splitString "-" (lib.removePrefix "wg-" link.name);
  localLinks = lib.filter (link: builtins.elem localNodeName (linkNodes link)) mesh.links;

  escapeLabel = lib.replaceStrings [ "\\" "\"" "\n" ] [ "\\\\" "\\\"" "\\n" ];

  mkInfoLine =
    {
      device,
      kind,
      peer,
      asn,
      birdProtocol,
    }:
    let
      labels = lib.concatStringsSep "," [
        ''device="${escapeLabel device}"''
        ''kind="${escapeLabel kind}"''
        ''peer="${escapeLabel peer}"''
        ''asn="${escapeLabel (toString asn)}"''
        ''bird_protocol="${escapeLabel birdProtocol}"''
      ];
    in
    "dn42_wg_interface_info{${labels}} 1";

  meshInfoLines = map (
    link:
    let
      endpoints = linkNodes link;
      a = builtins.elemAt endpoints 0;
      b = builtins.elemAt endpoints 1;
      remoteNode = if a == localNodeName then b else a;
    in
    mkInfoLine {
      device = link.name;
      kind = "mesh";
      peer = remoteNode;
      asn = mesh.asn;
      birdProtocol = "";
    }
  ) localLinks;

  peerInfoLines = lib.mapAttrsToList (
    name: peer:
    mkInfoLine {
      device = peer.interface;
      kind = "ebgp";
      peer = name;
      asn = peer.asn;
      birdProtocol = "dn42_${lib.replaceStrings [ "-" ] [ "_" ] peer.interface}";
    }
  ) dn42.peers;

  textfileContent =
    lib.concatStringsSep "\n" (
      [
        "# HELP dn42_wg_interface_info Static metadata for DN42 WireGuard interfaces."
        "# TYPE dn42_wg_interface_info gauge"
      ]
      ++ meshInfoLines
      ++ peerInfoLines
    )
    + "\n";
in
{
  options.my.services.dn42.metrics = {
    enable = lib.mkEnableOption "DN42 metrics (bird_exporter and WireGuard interface metadata)";

    birdExporterPort = lib.mkOption {
      type = lib.types.port;
      default = 9324;
      description = "Local port for prometheus-bird-exporter.";
    };
  };

  config = lib.mkIf enabled {
    # bird_exporter requires ISO protocol timestamps to parse BIRD2 uptimes.
    services.bird.config = lib.mkBefore ''
      timeformat protocol iso long;
    '';

    services.prometheus.exporters.bird = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = cfg.birdExporterPort;
      openFirewall = false;
      birdVersion = 2;
      newMetricFormat = true;
      extraFlags = [
        "-proto.kernel=false"
        "-proto.static=false"
        "-proto.direct=false"
        "-proto.babel=false"
        "-proto.rpki=false"
        "-proto.bfd=false"
      ];
    };

    my.systemd.harden = [ "prometheus-bird-exporter" ];
    systemd.services.prometheus-bird-exporter = {
      confinement.enable = true;
      bindsTo = [ "bird.service" ];
      after = [ "bird.service" ];
      wantedBy = [ "bird.service" ];
      serviceConfig = {
        BindPaths = [ "/run/bird" ];
        # confinement sets PrivateUsers=true, which unmaps SupplementaryGroups=bird
        # from the host GID owning /run/bird/bird.ctl (0660 bird:bird).
        PrivateUsers = lib.mkForce false;
        IPAddressDeny = "any";
        IPAddressAllow = "localhost";
        RestrictAddressFamilies = lib.mkForce [
          "AF_UNIX"
          "AF_INET"
        ];
      };
    };

    my.networking.usedTCPPorts.prometheus-bird-exporter = cfg.birdExporterPort;

    my.services.prometheus-node.textfiles.dn42_wg_info = textfileContent;

    my.services.monitoring-agent.extraScrapeConfigs = lib.mkIf monitoring.enable [
      {
        job_name = "integrations/bird_exporter";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString cfg.birdExporterPort}" ];
            labels = monitoring.extraLabels // {
              instance = config.networking.hostName;
            };
          }
        ];
        metric_relabel_configs = [
          {
            source_labels = [ "__name__" ];
            regex = "bird_protocol_changes_.*";
            action = "drop";
          }
        ];
      }
    ];

    systemd.services.vmagent = lib.mkIf monitoring.enable {
      wants = [ "prometheus-bird-exporter.service" ];
      after = [ "prometheus-bird-exporter.service" ];
    };
  };
}
