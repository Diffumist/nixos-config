{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.services.clash;
  configPath = cfg.configPath;
  configFile = cfg.configFile;
  inherit (pkgs) ripgrep iptables;
  redirPortStr = toString cfg.redirPort;
in
{
  options = {
    services.clash = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      configFile = mkOption {
        type = types.path;
        default = "";
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
    environment.etc."clash/Country.mmdb".source = "${pkgs.maxmind-geoip}/Country.mmdb";
    environment.etc."clash/config.yaml".source = "${configFile}";
    systemd.services.clash =
      let
        # Start clash client with iptables script
        preStartScript = pkgs.writeShellScript "clash-prestart" ''
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
        '';
        # Stop clash client
        postStopScript = pkgs.writeShellScript "clash-poststop" ''
          ${iptables}/bin/iptables-save -c|${ripgrep}/bin/rg -v CLASH|${iptables}/bin/iptables-restore -c
        '';
      in
      {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        script = "exec ${pkgs.clash}/bin/clash -d ${configPath}";
        unitConfig = {
          ConditionPathExists = "${configPath}/config.yaml";
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
