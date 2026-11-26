{
  helpers,
  pkgs,
  ...
}:
let
  port = 42430;
  wanInterface = "ens18";
  tunName = "phantun0";
  tunLocal4 = "192.168.201.1";
  tunPeer4 = "192.168.201.2";
  tunLocal6 = "fcc9::1";
  tunPeer6 = "fcc9::2";
in
{
  my.networking.usedTCPPorts.phantun-chn0 = port;

  networking.nftables.tables.phantun = {
    family = "inet";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        iifname "${wanInterface}" tcp dport ${toString port} dnat ip to ${tunPeer4}
        iifname "${wanInterface}" tcp dport ${toString port} dnat ip6 to ${tunPeer6}
      }
    '';
  };

  systemd.services.phantun-chn0 = helpers.systemd.mkService {
    description = "Phantun Fake-TCP server for DN42 chn0 link";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    environment.RUST_LOG = "info";
    serviceConfig = {
      ExecStart = "${pkgs.phantun}/bin/phantun_server --local ${toString port} --remote 127.0.0.1:${toString port} --tun ${tunName} --tun-local ${tunLocal4} --tun-peer ${tunPeer4} --tun-local6 ${tunLocal6} --tun-peer6 ${tunPeer6}";
      DynamicUser = true;
      PrivateDevices = false;
      DeviceAllow = [ "/dev/net/tun rw" ];
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
      Restart = "always";
      RestartSec = "3s";
    };
  };
}
