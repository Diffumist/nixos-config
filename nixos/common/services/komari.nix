{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.komari-agent;
in
{
  options.my.services.komari-agent.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {

    sops.templates."komari-agent.env".content = ''
      AGENT_TOKEN=${config.sops.placeholder.komari_token}
    '';

    systemd.services.komari-agent = {
      environment = {
        AGENT_ENDPOINT = "https://sla.qzz.io";
        AGENT_DISABLE_AUTO_UPDATE = "true";
        AGENT_DISABLE_WEB_SSH = "true";
        AGENT_MONTH_ROTATE = lib.mkDefault "1";
        AGENT_INTERVAL = "3";
        AGENT_MEMORY_REPORT_RAW_USED = "true";
      };
      serviceConfig = {
        DynamicUser = true;
        # ICMPing
        AmbientCapabilities = [ "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_RAW" ];
        # Net static
        StateDirectory = "komari-agent";
        WorkingDirectory = "/var/lib/komari-agent";
        ExecStart = "${lib.getExe pkgs.komari-agent} --include-mountpoint /nix";
        EnvironmentFile = config.sops.templates."komari-agent.env".path;

        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
