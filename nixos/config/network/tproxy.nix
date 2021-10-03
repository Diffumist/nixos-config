{ lib, pkgs, config, ... }: {
  # TODO Modify to module instead of configuration
  systemd.services.clash =
    let
      inherit (pkgs) ripgrep iptables iproute2;
      # Start clash client with iptables script
      preStartScript = pkgs.writeShellScript "clash-prestart" ''
        iptables() {
          ${iptables}/bin/iptables -w "$@"
        }
        ${iproute2}/bin/ip rule add fwmark 1 table 100
        ${iproute2}/bin/ip route add local 0.0.0.0/0 dev lo table 100
        iptables -t mangle -N CLASH
        iptables -t mangle -A CLASH -d 127.0.0.1/32 -j RETURN
        iptables -t mangle -A CLASH -d 224.0.0.0/4 -j RETURN
        iptables -t mangle -A CLASH -d 255.255.255.255/32 -j RETURN
        iptables -t mangle -A CLASH -d 192.168.0.0/16 -p tcp -j RETURN
        iptables -t mangle -A CLASH -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN
        iptables -t mangle -A CLASH -p udp -j TPROXY --on-port 7891 --tproxy-mark 1
        iptables -t mangle -A CLASH -p tcp -j TPROXY --on-port 7891 --tproxy-mark 1
        iptables -t mangle -A PREROUTING -j CLASH
        iptables -t mangle -N CLASH_MASK
        iptables -t mangle -A CLASH_MASK -d 224.0.0.0/4 -j RETURN
        iptables -t mangle -A CLASH_MASK -d 255.255.255.255/32 -j RETURN
        iptables -t mangle -A CLASH_MASK -d 192.168.0.0/16 -p tcp -j RETURN
        iptables -t mangle -A CLASH_MASK -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN
        iptables -t mangle -A CLASH_MASK -j RETURN -m mark --mark 0xff
        iptables -t mangle -A CLASH_MASK -p udp -m owner ! --uid-owner clash -j MARK --set-mark 1
        iptables -t mangle -A CLASH_MASK -p tcp -m owner ! --uid-owner clash -j MARK --set-mark 1
        iptables -t mangle -A OUTPUT -j CLASH_MASK
      '';
      # Stop clash client
      postStopScript = pkgs.writeShellScript "clash-poststop" ''
        ${iptables}/bin/iptables-save -c|${ripgrep}/bin/rg -v CLASH|${iptables}/bin/iptables-restore -c
        ${iproute2}/bin/ip route del local 0.0.0.0/0 dev lo table 100
        ${iproute2}/bin/ip rule del fwmark 1 table 100
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
        LimitNPROC = 500;
        LimitNOFILE = 1000000;
        AmbientCapabilities =
          "CAP_NET_BIND_SERVICE CAP_NET_ADMIN";
        User = "clash";
        Restart = "on-abort";
      };
    };
  users.groups.clash = { };
  users.users.clash = {
    group = "clash";
    isSystemUser = true;
  };
}
