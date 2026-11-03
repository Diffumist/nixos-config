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

  # Why: NixOS only opens DNS for podman0, while tools may create dynamic bridges.
  networking.firewall.extraInputRules = ''
    iifname "podman*" tcp dport 53 accept
    iifname "podman*" udp dport 53 accept
  '';

  systemd.timers.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
    wantedBy = [ "timers.target" ];
  };
  systemd.services.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
    serviceConfig.ExecStartPost = lib.mkIf config.services.caddy.enable "${pkgs.systemd}/bin/systemctl try-restart caddy.service";
  };
}
