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
    ./services/powerdns.nix
    ./services/tgtldr.nix
    ./services/authelia.nix
    ./services/vaultwarden.nix
  ];

  my.services.sing-box = {
    enable = true;
    firewallPorts = [ 8443 ];
    configSopsFile = ./services/sing-box.json;
  };

  my.services.postgresql.totalRamMB = 6 * 1024;
  systemd.services.komari-agent.environment.AGENT_MONTH_ROTATE = "20";
}
