# Autopeer agent: lets the autopeer frontend bring up runtime DN42 peers on
# this node, which a merged file under profiles/common/services/peers then
# replaces. Turned on in profiles/common/services/dn42.nix.
{
  config,
  hostName,
  lib,
  ...
}:
let
  cfg = config.my.services.dn42.autopeer;
  dn42 = config.my.services.dn42;
  ranet = config.my.services.ranet.nodes;
  port = 4801;
  # The frontend reaches the agents over the management mesh only.
  frontend = ranet.${cfg.frontend}.ipv6;
in
{
  options.my.services.dn42.autopeer = {
    enable = lib.mkEnableOption "the autopeer agent for runtime DN42 peers";

    frontend = lib.mkOption {
      type = lib.types.str;
      description = "Host name of the autopeer frontend, a member of the management mesh.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.autopeer_agent_token.sopsFile = ../../../profiles/common/secrets/server.yaml;

    services.autopeer.agent = {
      enable = true;
      settings = {
        listen = "[${ranet.${hostName}.ipv6}]:${toString port}";
        allow = [ frontend ];
        link_local = "fe80::642";
        # The same protocol block as a declared peer, with the agent's blanks.
        bird_template = dn42.peerBird.protocol {
          interface = "@IFACE@";
          peerLinkLocal = "@NEIGHBOR@";
          asn = "@ASN@";
        };
        # The looking glass asks DN42's anycast resolver for .dn42 names. The
        # management mesh lies inside fd00::/8 but is routed apart from DN42
        # (mesh.nix), so a probe to it would go over the mesh: left out.
        lg_resolver = "fd42:d42:d42:54::1";
        lg_deny = [ "fd42:203::/64" ];
      };
      tokenFile = config.sops.secrets.autopeer_agent_token.path;
      privateKeyFile = config.sops.secrets.dn42_wg_private_key.path;
      # Peers autopeer asked for and that are merged: their runtime twin goes
      # when this generation is activated.
      declared = lib.filter (lib.hasPrefix "wg-as") (
        lib.mapAttrsToList (_: peer: peer.interface) dn42.peers
      );
    };

    # peer.nix writes the filters only on a node with declared peers; a
    # runtime peer needs them on any node.
    services.bird.config = lib.mkIf (dn42.peers == { }) (lib.mkAfter dn42.peerBird.filters);

    my.systemd.harden = [ "autopeer-agent" ];
    # The looking glass runs ping, which drops its privileges with capset and
    # setuid before it sends and gives up when it may not. Both are in
    # @privileged, which the hardening profile denies.
    systemd.services.autopeer-agent = {
      after = [ "ranet-ready.service" ];
      wants = [ "ranet-ready.service" ];
      serviceConfig.SystemCallFilter = [
        "@system-service"
        "~@clock @cpu-emulation @debug @module @mount @obsolete @privileged @raw-io @reboot @swap"
        "capset setuid"
      ];
    };

    networking.firewall.extraInputRules = ''
      ip6 saddr ${frontend} tcp dport ${toString port} accept
    '';
    my.networking.usedTCPPorts.autopeer-agent = port;
  };
}
