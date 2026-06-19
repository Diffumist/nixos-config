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
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      ipv4_address = { };
      ipv4_gateway = { };
    };
    templates."10-lan.network" = {
      path = "/etc/systemd/network/10-lan.network";
      owner = "systemd-network";
      content = ''
        [Match]
        Name=ens17 enp0s17

        [Network]
        Address=${config.sops.placeholder.ipv4_address}/24
        Gateway=${config.sops.placeholder.ipv4_gateway}
        DNS=1.0.0.1
        DNS=8.8.4.4
      '';
    };
  };
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  my.services.postgresql.totalRamMB = 2 * 1024;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "geelinx-mys";
}
