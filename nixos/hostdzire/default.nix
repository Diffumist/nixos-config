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

  # AS4242423999 (CowGL) slc (Salt Lake City)
  my.services.dn42-peers.cowgl-slc = {
    asn = 4242423999;
    listenPort = 23999;
    endpoint = "slc.node.cowgl.tech";
    peerPort = 30642;
    publicKey = "rxicmyDFnBh33mW/EfG0VGXE/yxB5YmBcuWfyntg9Xk=";
    peerLinkLocal = "fe80::6:3999";
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "hostdzire";
}
