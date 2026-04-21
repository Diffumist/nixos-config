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

    ./services/nanobot.nix
    ./services/acme.nix
    ./services/memos.nix
    ./services/postgresql.nix
    ./services/vaultwarden.nix
  ];

  sops = {
    age.keyFile = "/var/lib/age/key.txt";
    secrets.user_passwd_hash = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
  };
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "hostdzire";
}
