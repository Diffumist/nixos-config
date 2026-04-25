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
    age.keyFile = "/var/lib/age/key.txt";
    secrets = {
      user_passwd_hash = {
        sopsFile = ./secrets.yaml;
        neededForUsers = true;
      };
      ipv4_address.sopsFile = ./secrets.yaml;
      ipv4_gateway.sopsFile = ./secrets.yaml;
    };
    templates."10-lan.network" = {
      path = "/etc/systemd/network/10-lan.network";
      owner = "systemd-network";
      content = ''
        [Match]
        Name=ens17

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
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  virtualisation.podman.enable = false;

  my.services.sing-box = {
    enable = true;
    configSopsFile = ./services/sing-box.json;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "vmiss";
}
