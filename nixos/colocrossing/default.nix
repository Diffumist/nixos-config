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
    };
  };
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  virtualisation.podman.enable = false;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "colocrossing";
}
