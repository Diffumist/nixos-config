{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.dmist.clash;
  clashDir = "/var/lib/clash";
  redirPort = 7891;
  clashUser = "clash";
  wlanName = "wlp0s20f3";
  startScript = writeShellScript "clash-prestart" ''
    iptables() {
      ${iptables}/bin/iptables -w "$@"
    }
    iptables -t nat -F CLASH
    iptables -t nat -N CLASH
    iptables -t nat -A CLASH -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH -d 127.0.0.1/32 -j RETURN
    iptables -t nat -A CLASH -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A CLASH -m owner --uid-owner ${clashUser} -j RETURN
    iptables -t nat -A CLASH -p tcp -j REDIRECT --to-ports ${toString redirPort}
    iptables -t nat -A OUTPUT -p tcp -j CLASH
  '';
  stopScript = writeShellScript "clash-poststop" ''
    ${iptables}/bin/iptables-save -c|${ripgrep}/bin/rg -v CLASH|${iptables}/bin/iptables-restore -c
  '';
  inherit (pkgs) writeShellScript iptables maxmind-geoip ripgrep;
  inherit (pkgs.nur.repos.linyinfeng) clash-premium;
in
{
  options.dmist.clash = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
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
  };
}
