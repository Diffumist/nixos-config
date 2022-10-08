{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.modules.clash;
  clashDir = "/var/lib/clash";
  redirPort = 7891;
  clashUser = "clash";
  startScript = writeShellScript "clash-prestart" ''
    iptables() {
      ${iptables}/bin/iptables -w "$@"
    }
    iptables -t nat -F CLASH
    iptables -t nat -N CLASH

    iptables -t nat -A CLASH -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A CLASH -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A CLASH -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A CLASH -d 240.0.0.0/4 -j RETURN

    iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner ${clashUser} -j REDIRECT --to-port ${toString redirPort}
  '';
  stopScript = writeShellScript "clash-poststop" ''
    ${iptables}/bin/iptables-save -c|${ripgrep}/bin/rg -v CLASH|${iptables}/bin/iptables-restore -c
  '';
  inherit (pkgs) writeShellScript iptables maxmind-geoip ripgrep;
  inherit (pkgs.nur.repos.linyinfeng) clash-premium;
in
{
  options.modules.clash = {
    enable = mkEnableOption "clash services";
  };

  config = mkIf cfg.enable {
    system.activationScripts.initClashScripts = ''
      mkdir -p "${clashDir}"
      chown "${clashUser}" "${clashDir}"
      ln -nfs "${maxmind-geoip}/Country.mmdb" "${clashDir}/Country.mmdb"
    '';

    systemd.services.clash = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = "exec ${clash-premium}/bin/clash-premium -d ${clashDir}";
      serviceConfig = {
        ExecStartPre = "+${startScript}";
        ExecStopPost = "+${stopScript}";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE CAP_NET_ADMIN";
        User = clashUser;
        Group = config.users.groups.nogroup.name;
        Restart = "on-abort";
      };
    };

    users.users."${clashUser}" = {
      group = config.users.groups.nogroup.name;
      isSystemUser = true;
    };

    virtualisation.oci-containers.containers = {
      clash-web = {
        image = "docker.io/haishanh/yacd:latest";
        ports = [ "127.0.0.1:1234:80" ];
      };
    };

    services.smartdns = {
      enable = true;
      settings = with pkgs; {
        log-level = "info";
        speed-check-mode = "none";
        conf-file = [
          "${smartdns-china-list}/accelerated-domains.china.smartdns.conf"
          "${smartdns-china-list}/apple.china.smartdns.conf"
          "${smartdns-china-list}/google.china.smartdns.conf"
        ];
        bind = [ "0.0.0.0:53" ];
        server = [
          "127.0.0.1:1053"
        ];
        server-https = [
          "https://1.0.0.1/dns-query"
          "https://8.8.8.8/dns-query"
          "https://185.222.222.222/dns-query"
        ];
      };
    };
  };
}
