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
        Name=ens5

        [Network]
        Address=${config.sops.placeholder.ipv4_address}/26
        Gateway=${config.sops.placeholder.ipv4_gateway}
        DNS=1.0.0.1
        DNS=8.8.4.4
      '';
    };
  };
  virtualisation.podman.enable = true;
  services.fail2ban.enable = false;
  my.services.sing-box = {
    enable = true;
    configSopsFile = ./services/sing-box.json;
  };
}
