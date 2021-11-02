{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.dmist.clash;
  inherit (pkgs) writeShellScript iptables iproute maxmind-geoip clean-dns-bpf clash ripgrep;
  redirPortStr = toString cfg.redirPort;
in
{
  options = {
    dmist.clash = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      configFile = mkOption {
        type = types.path;
        default = "/etc/clash/clash.yaml";
      };
      configPath = mkOption {
        type = types.path;
        default = "/etc/clash";
      };
      redirPort = mkOption {
        type = types.port;
        default = 7891;
      };
    };
  };
  config = mkIf cfg.enable {
    environment.etc."clash/Country.mmdb".source = "${maxmind-geoip}/Country.mmdb";
    environment.etc."clash/config.yaml".source = "${cfg.configFile}";
    systemd.services.clash =
      let
        # Start clash client with iptables script
        preStartScript = writeShellScript "clash-prestart" ''
          iptables() {
            ${iptables}/bin/iptables -w "$@"
          }
          iptables -t nat -F CLASH
          iptables -t nat -N CLASH
          iptables -t nat -A CLASH -d 127.0.0.1/32 -j RETURN
          iptables -t nat -A CLASH -d 192.168.0.0/16 -j RETURN
          iptables -t nat -A CLASH -m owner --uid-owner clash -j RETURN
          iptables -t nat -A CLASH -p tcp -j REDIRECT --to-ports ${redirPortStr}
          iptables -t nat -A OUTPUT -p tcp -j CLASH
          ${iproute}/bin/ip link set dev wlp0s20f3 xdp obj ${clean-dns-bpf}
        '';
        # Stop clash client
        postStopScript = writeShellScript "clash-poststop" ''
          ${iptables}/bin/iptables-save -c|${ripgrep}/bin/rg -v CLASH|${iptables}/bin/iptables-restore -c
          ${iproute}/bin/ip link set dev wlp0s20f3 xdp off
        '';
      in
      {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        script = "exec ${clash}/bin/clash -d ${cfg.configPath}";
        unitConfig = {
          ConditionPathExists = "${cfg.configPath}/config.yaml";
        };
        serviceConfig = {
          ExecStartPre = "+${preStartScript}";
          ExecStopPost = "+${postStopScript}";
          AmbientCapabilities = "CAP_NET_BIND_SERVICE CAP_NET_ADMIN";
          User = "clash";
          Restart = "on-abort";
        };
      };
    users.groups.clash = { };
    users.users.clash = {
      group = "clash";
      isSystemUser = true;
    };
  };
}
