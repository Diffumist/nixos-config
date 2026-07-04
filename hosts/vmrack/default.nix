{
  pkgs,
  config,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./boot.nix

  ];

  sops = {
    secrets = {
      ipv4_address = { };
      ipv4_gateway = { };
    };
    templates."10-lan.network" = {
      path = "/etc/systemd/network/10-lan.network";
      owner = "systemd-network";
      content = ''
        [Match]
        Name=ens3

        [Network]
        Address=${config.sops.placeholder.ipv4_address}/24
        Gateway=${config.sops.placeholder.ipv4_gateway}
        DNS=1.0.0.1
        DNS=8.8.4.4
        DNS=2606:4700:4700::1001
        DNS=2001:4860:4860::8844
      '';
    };
  };

  virtualisation.podman.enable = false;

  my.services.sing-box = {
    enable = true;
    configSopsFile = ./services/sing-box.json;
  };
}
