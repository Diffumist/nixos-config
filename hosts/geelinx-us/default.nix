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
    ./services/matrix.nix
    ./services/misskey.nix
    ./services/notifications.nix
  ];

  sops = {
    secrets = {
      ipv4_address = { };
      ipv4_gateway = { };
      ipv6_address = { };
      ipv6_gateway = { };
    };
    templates."10-lan.network" = {
      path = "/etc/systemd/network/10-lan.network";
      owner = "systemd-network";
      content = ''
        [Match]
        Name=ens17 enp0s17

        [Network]
        Address=${config.sops.placeholder.ipv4_address}/26
        Address=${config.sops.placeholder.ipv6_address}/64
        IPv6AcceptRA=no
        Gateway=${config.sops.placeholder.ipv4_gateway}
        Gateway=${config.sops.placeholder.ipv6_gateway}
        DNS=1.0.0.1
        DNS=8.8.4.4
        DNS=2606:4700:4700::1001
        DNS=2001:4860:4860::8844
      '';
    };
  };

  my.services.postgresql = {
    enable = true;
    totalRamMB = 2 * 1024;
  };
}
