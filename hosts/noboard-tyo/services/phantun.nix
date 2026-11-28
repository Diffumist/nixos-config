{
  helpers,
  lib,
  pkgs,
  ...
}:
let
  wanInterface = "ens18";
  instances = {
    chn0 = {
      description = "Phantun Fake-TCP server for DN42 chn0 link";
      port = 42430;
      tunName = "phantun0";
      tunLocal4 = "192.168.201.1";
      tunPeer4 = "192.168.201.2";
      tunLocal6 = "fcc9::1";
      tunPeer6 = "fcc9::2";
    };
    mgmt-n1 = {
      description = "Phantun Fake-TCP server for ranet immortalwrt-n1 link";
      port = 13001;
      tunName = "phantun1";
      tunLocal4 = "192.168.202.1";
      tunPeer4 = "192.168.202.2";
      tunLocal6 = "fcc9:1::1";
      tunPeer6 = "fcc9:1::2";
    };
  };
in
{
  my.networking.usedTCPPorts = lib.mapAttrs' (
    name: inst: lib.nameValuePair "phantun-${name}" inst.port
  ) instances;

  networking.nftables.tables.phantun = {
    family = "inet";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        ${lib.concatStrings (
          lib.mapAttrsToList (_: inst: ''
            iifname "${wanInterface}" tcp dport ${toString inst.port} dnat ip to ${inst.tunPeer4}
            iifname "${wanInterface}" tcp dport ${toString inst.port} dnat ip6 to ${inst.tunPeer6}
          '') instances
        )}
      }
    '';
  };

  systemd.services = lib.mapAttrs' (
    name: inst:
    lib.nameValuePair "phantun-${name}" (
      helpers.systemd.mkService {
        description = inst.description;
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        environment.RUST_LOG = "info";
        serviceConfig = {
          ExecStart = "${pkgs.phantun}/bin/phantun_server --local ${toString inst.port} --remote 127.0.0.1:${toString inst.port} --tun ${inst.tunName} --tun-local ${inst.tunLocal4} --tun-peer ${inst.tunPeer4} --tun-local6 ${inst.tunLocal6} --tun-peer6 ${inst.tunPeer6}";
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
      }
    )
  ) instances;
}
