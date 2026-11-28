{
  config,
  hostName,
  ...
}:
let
  local = config.my.services.ranet.nodes.${hostName};
  interface = "mgmt-n1";
  port = 13001;
  peerIpv4 = "10.203.0.40";
  peerIpv6 = "fd42:203::40";
  peerPublicKey = "MhNZ/CaMilme+itagUndTcg9YgE+sxydTfBFzmHdQgM=";
in
{
  sops.secrets.ranet_mgmt_wg_private_key = {
    owner = "systemd-network";
    mode = "0400";
  };

  networking.firewall.allowedUDPPorts = [ port ];
  my.networking.usedUDPPorts.ranet-mgmt-n1 = port;

  # Interface name intentionally avoids `wg-*` (reserved for DN42 forward
  # isolation) and `ranet-*` (reserved for XFRM mesh links).
  # Peer addresses stay inside 10.203.0.0/24 and fd42:203::/64 so DN42 policy
  # routing (priority 9000/9001) keeps them in the main routing table.
  systemd.network.netdevs."20-${interface}" = {
    netdevConfig = {
      Name = interface;
      Kind = "wireguard";
      MTUBytes = "1360";
    };
    wireguardConfig = {
      ListenPort = port;
      PrivateKeyFile = config.sops.secrets.ranet_mgmt_wg_private_key.path;
    };
    wireguardPeers = [
      {
        PublicKey = peerPublicKey;
        AllowedIPs = [
          "${peerIpv4}/32"
          "${peerIpv6}/128"
        ];
      }
    ];
  };

  systemd.network.networks."30-${interface}" = {
    matchConfig.Name = interface;
    address = [
      "${local.ipv4}/32"
      "${local.ipv6}/128"
    ];
    linkConfig.RequiredForOnline = "no";
    networkConfig = {
      IPv4ReversePathFilter = "no";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "no";
    };
    routes = [
      {
        Destination = "${peerIpv4}/32";
        PreferredSource = local.ipv4;
      }
      {
        Destination = "${peerIpv6}/128";
        PreferredSource = local.ipv6;
      }
    ];
  };
}
