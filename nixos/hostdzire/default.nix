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

    ./services/lldap.nix
    # ./services/bub.nix
    ./services/tgtldr.nix
    ./services/authelia.nix
    ./services/vaultwarden.nix
  ];
  sops.defaultSopsFile = ./secrets.yaml;
  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  my.services.postgresql.totalRamMB = 6 * 1024;
  systemd.services.komari-agent.environment.AGENT_MONTH_ROTATE = "20";

  # AS4242422466 (SessNetwork) Chronnection (San Jose)
  my.services.dn42-peers.sess-sjc = {
    asn = 4242422466;
    listenPort = 22466;
    endpoint = "chron-nection.xhustudio.eu.org";
    peerPort = 20642;
    publicKey = "tA6SZZYpCdr4zkkk2pCpuDDiyxcHIsksOhwWnzLIVw8=";
    peerLinkLocal = "fe80::2466";
  };

  # AS4242420298 (HExpNetwork) sjc
  my.services.dn42-peers.hexp-sjc = {
    asn = 4242420298;
    listenPort = 20298;
    endpoint = "sjc.dn42.hexpnet.work";
    peerPort = 20642;
    publicKey = "fKuqaW7QYOfC9UXWrgjgqVicQUn6XglCemH7Efd/XlM=";
    peerLinkLocal = "fe80::298";
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "hostdzire";
}
