{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };

  systemd.timers.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
    wantedBy = [ "timers.target" ];
  };
  systemd.services.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
    serviceConfig.ExecStartPost = lib.mkIf config.services.caddy.enable "${pkgs.systemd}/bin/systemctl try-restart caddy.service";
  };
}
