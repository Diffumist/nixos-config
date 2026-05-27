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

    ./services/komari-monitor.nix
    ./services/snac.nix
  ];
  sops.defaultSopsFile = ./secrets.yaml;
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };

  my.services.sing-box = {
    enable = true;
    firewallPorts = [ 8443 ];
    configSopsFile = ./services/sing-box.json;
  };
  systemd.network.wait-online.enable = false;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "colocrossing";
}
