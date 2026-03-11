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

    ./services/sing-box.nix
  ];

  sops.age.keyFile = "/var/lib/age/key.txt";
  users.users.root.initialHashedPassword = config.sops.secrets.user_passwd_hash.path;
  sops.secrets.user_passwd_hash = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = [
          "216.23.85.225/24"
          "2a13:edc0:24:1de::8964/64"
        ];
        Gateway = [
          "216.23.85.1"
          "2a13:edc0:24::1"
        ];
        DNS = [
          "1.0.0.1"
          "8.8.4.4"
          "2606:4700:4700::1001"
          "2001:4860:4860::8844"
        ];
      };
    };
  };
  networking.hostName = "bitsflow";
}
