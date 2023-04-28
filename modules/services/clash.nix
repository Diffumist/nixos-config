{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.modules.clash;
  clashDir = "/var/lib/clash";
  redirPort = 7891;
  clashUser = "clash";
  inherit (pkgs) writeShellScript iptables maxmind-geoip ripgrep clash-meta;
in
{
  options.modules.clash = {
    enable = mkEnableOption "clash services";
  };

  config = mkIf cfg.enable {
    system.activationScripts.initClashScripts = ''
      mkdir -p "${clashDir}"
      chown -R "${clashUser}" "${clashDir}"
      ln -nfs "${maxmind-geoip}/Country.mmdb" "${clashDir}/Country.mmdb"
      ln -nfs "${maxmind-geoip}/geoip.dat" "${clashDir}/GeoIP.dat"
    '';

    systemd.services.clash = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = "exec ${clash-meta}/bin/clash -d ${clashDir}";
      serviceConfig = {
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
      yacd-meta = {
        image = "docker.io/asnil/yacd-meta:latest";
        ports = [ "127.0.0.1:1234:80" ];
      };
    };
  };
}
