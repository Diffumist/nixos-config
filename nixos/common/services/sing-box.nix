{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.sing-box;
in
{
  options = {
    my.services.sing-box = {
      enable = lib.mkEnableOption "The Sing-box Service";
      configSopsFile = lib.mkOption {
        type = lib.types.path;
      };
      firewallPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ 443 ];
      };
    };
  };
  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [ 80 ] ++ cfg.firewallPorts;
      allowedUDPPorts = cfg.firewallPorts;
    };

    sops.secrets.singbox_config = {
      sopsFile = cfg.configSopsFile;
      format = "json";
      key = "";
      owner = "sing-box";
      group = "sing-box";
      mode = "0400";
      restartUnits = [ "sing-box.service" ];
    };

    users = {
      users.sing-box = {
        isSystemUser = true;
        group = "sing-box";
        home = "/var/lib/sing-box";
      };
      groups.sing-box = { };
    };
    systemd.packages = [ pkgs.sing-box ];
    services.dbus.packages = [ pkgs.sing-box ];
    environment.systemPackages = [ pkgs.sing-box ];

    systemd.services.sing-box = {
      serviceConfig = {
        User = "sing-box";
        Group = "sing-box";
        StateDirectory = "sing-box";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "sing-box";
        RuntimeDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/sing-box";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        NoNewPrivileges = false;
        ExecStart = [
          ""
          "${lib.getExe pkgs.sing-box} -D \${STATE_DIRECTORY} -c ${config.sops.secrets.singbox_config.path} run"
        ];
      };
      requires = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
