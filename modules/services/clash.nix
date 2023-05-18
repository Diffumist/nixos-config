{ pkgs, config, ... }:
let
  clashDir = "/var/lib/clash";
  clashUser = "clash";
  inherit (pkgs) maxmind-geoip clash-meta;
in
{
  system.activationScripts.initClashSscripts = ''
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
}
