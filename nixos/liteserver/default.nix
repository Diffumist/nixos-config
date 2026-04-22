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

    ./services/acme.nix
    ./services/postgresql.nix
    ./services/immich.nix
    ./services/rqbit.nix
  ];

  sops = {
    age.keyFile = "/var/lib/age/key.txt";
    secrets = {
      user_passwd_hash = {
        sopsFile = ./secrets.yaml;
        neededForUsers = true;
      };
      ipv4_address.sopsFile = ./secrets.yaml;
      ipv4_gateway.sopsFile = ./secrets.yaml;
      ipv6_address.sopsFile = ./secrets.yaml;
      ipv6_gateway.sopsFile = ./secrets.yaml;
    };
    templates."10-lan.network" = {
      path = "/etc/systemd/network/10-lan.network";
      owner = "systemd-network";
      content = ''
        [Match]
        Name=ens3

        [Network]
        Address=${config.sops.placeholder.ipv4_address}/24
        Address=${config.sops.placeholder.ipv6_address}/64
        Gateway=${config.sops.placeholder.ipv4_gateway}
        Gateway=${config.sops.placeholder.ipv6_gateway}
        DNS=1.0.0.1
        DNS=8.8.4.4
        DNS=2606:4700:4700::1001
        DNS=2001:4860:4860::8844
      '';
    };
  };
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;
  systemd.tmpfiles.rules = [
    "d /persist/var/storage 0755 root root -"
  ];
  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "liteserver";
}
