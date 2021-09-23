{ lib, pkgs, config, ... }:
{
  networking = {
    hostName = "Dmistlaptop";
    firewall.enable = false;
    networkmanager.dns = "none";
    networkmanager.wifi.backend = "iwd";
    nameservers = [ "127.0.0.1" ];
  };

  systemd.services.clash =
    let
      inherit (pkgs) gnugrep iptables clash iproute2 unixtools;
      preStartScript = pkgs.writeShellScript "clash-prestart" ''
        iptables() {
          ${iptables}/bin/iptables -w "$@"
        }
        iptables -t mangle -N CLASH
        iptables -t mangle -A CLASH -d 0.0.0.0/8 -j RETURN
        iptables -t mangle -A CLASH -d 10.0.0.0/8 -j RETURN
        iptables -t mangle -A CLASH -d 192.168.0.0/16 -j RETURN
        iptables -t mangle -A CLASH -d 127.0.0.0/8 -j RETURN
        iptables -t mangle -A CLASH -j MARK --set-xmark 129
        iptables -t mangle -A PREROUTING -p udp -m udp --dport 4096:65535 -j RETURN
        iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 8192:65535 -j RETURN
        iptables -t mangle -A PREROUTING -j CLASH
        iptables -t mangle -A OUTPUT -m owner --uid-owner clash -j RETURN
        iptables -t mangle -A OUTPUT -j CLASH
        ${iproute2}/bin/ip tuntap add mode tun user clash name utun
        ${unixtools.ifconfig}/bin/ifconfig utun up
        ${iproute2}/bin/ip route add default dev utun table 129
        ${iproute2}/bin/ip rule add fwmark 129 lookup 129
      '';

      postStopScript = pkgs.writeShellScript "clash-poststop" ''
        ${iptables}/bin/iptables-save -c|${gnugrep}/bin/grep -v CLASH|${iptables}/bin/iptables-restore -c
        ${iproute2}/bin/ip route del default dev utun table 129
        ${iproute2}/bin/ip rule del fwmark 129 lookup 129
      '';
    in
    {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script =
        "exec ${pkgs.clash}/bin/clash -d /etc/clash";
      unitConfig = {
        ConditionPathExists = "/etc/clash/config.yaml";
      };
      serviceConfig = {
        ExecStartPre = "+${preStartScript}";
        ExecStopPost = "+${postStopScript}";
        AmbientCapabilities =
          "CAP_NET_BIND_SERVICE CAP_NET_ADMIN";
        User = "clash";
        Restart = "on-abort";
      };
    };
  users.users.clash.group = "nogroup";
  users.users.clash = {
    isSystemUser = true;
  };

  services.smartdns = {
    enable = true;
    settings = with pkgs; {
      conf-file = [
        "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
        "${smartdns-china-list}/apple.china.smartdns.conf"
        "${smartdns-china-list}/google.china.smartdns.conf"
      ];
      bind = [ "127.0.0.1:53" ];
      server = [
        "223.5.5.5 -group china -exclude-default-group"
        "8.8.8.8"
        "9.9.9.9"
        "1.1.1.1"
      ];
      server-https = [
        "https://223.5.5.5/dns-query -group china -exclude-default-group"
        "https://223.6.6.6/dns-query -group china -exclude-default-group"
      ];
    };
  };
}
