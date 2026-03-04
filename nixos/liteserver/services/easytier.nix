{ config, ... }:
{
  services.easytier = {
    enable = true;
    instances.private = {
      enable = true;
      settings = {
        network_name = "private";
        ipv4 = "10.144.144.1/24";
        dhcp = true;
        listeners = [
          "tcp://0.0.0.0:11010"
          "udp://0.0.0.0:11010"
        ];
      };
      extraArgs = [
        "--enable-kcp-proxy"
        "--private-mode true"
      ];
    };
  };
  # ET_NETWORK_SECRET=your-secret-here
  sops.secrets.easytier_network_secret = {
    sopsFile = ../secrets.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  systemd.services.easytier-private.serviceConfig.EnvironmentFile =
    config.sops.secrets.easytier_network_secret.path;

  networking.firewall = {
    allowedTCPPorts = [ 11010 ];
    allowedUDPPorts = [ 11010 ];
  };
}
