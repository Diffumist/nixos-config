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

    ./services/asterisk.nix
    ./services/lldap.nix
    # ./services/bub.nix
    ./services/powerdns.nix
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

  my.services.sing-box = {
    enable = true;
    firewallPorts = [ 8443 ];
    configSopsFile = ./services/sing-box.json;
  };

  my.services.postgresql.totalRamMB = 6 * 1024;
  systemd.services.komari-agent.environment.AGENT_MONTH_ROTATE = "20";

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;
  networking.hostName = "hostdzire";
  # AS4242422466 (SessNetwork) Chronnection (San Jose)
  my.services.dn42.peers.sess-sjc = {
    asn = 4242422466;
    listenPort = 22466;
    endpoint = "chron-nection.xhustudio.eu.org";
    peerPort = 20642;
    publicKey = "tA6SZZYpCdr4zkkk2pCpuDDiyxcHIsksOhwWnzLIVw8=";
    peerLinkLocal = "fe80::2466";
  };

  # AS4242420454 (nedifinita) Chronnection (Seattle)
  my.services.dn42.peers.nedi-sea = {
    asn = 4242420454;
    listenPort = 20454;
    endpoint = "dn42a.nedifinita.com";
    peerPort = 41324;
    publicKey = "8EXT6zciVdil3Zg6dqB0YT2SssTh2OTKDeBBfrVGUkE=";
    peerLinkLocal = "fe80::454";
  };

  # AS4242420298 (HExpNetwork) sjc
  my.services.dn42.peers.hexp-sjc = {
    asn = 4242420298;
    listenPort = 20298;
    endpoint = "sjc.dn42.hexpnet.work";
    peerPort = 20642;
    publicKey = "fKuqaW7QYOfC9UXWrgjgqVicQUn6XglCemH7Efd/XlM=";
    peerLinkLocal = "fe80::298";
  };

  # AS4242423658 (xaven) sjc
  my.services.dn42.peers.xaven-sjc = {
    asn = 4242423658;
    listenPort = 23658;
    endpoint = "107.148.41.99";
    peerPort = 20642;
    publicKey = "MWIKfVn84ekQvpR1wWLIy1pWL4nrwXDatvK5mLxilD8=";
    peerLinkLocal = "fe80::3658";
  };

  # AS4242422189 (IEDON) sjc
  my.services.dn42.peers.iedon-sjc = {
    asn = 4242422189;
    listenPort = 22189;
    endpoint = "us-sjc.dn42.iedon.net";
    peerPort = 59878;
    publicKey = "Sz0UhewjDk2yRKI0QL9rB+5daWpXFVlbbz9cLfVVLn4=";
    peerLinkLocal = "fe80::2189:e8";
  };

}
