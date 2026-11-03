{
  lib,
  ...
}:
let
  sshPort = 22;
  moshPorts = lib.range 60000 61000;
in
{
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
  ];
  networking = {
    firewall = {
      enable = true;
      extraInputRules = ''
        tcp dport ${toString sshPort} ct state new meter ssh_meter { ip saddr limit rate 5/minute burst 8 packets } accept
        tcp dport ${toString sshPort} ct state new meter ssh_v6_meter { ip6 saddr limit rate 5/minute burst 8 packets } counter accept
        tcp dport ${toString sshPort} ct state new drop
      '';
    };
  };
  # programs.mosh.enable = true;
  services.openssh = {
    enable = true;
    ports = [ sshPort ];
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };
  my.networking = {
    usedTCPPorts.openssh = sshPort;
    usedUDPPorts = lib.listToAttrs (
      map (port: lib.nameValuePair "mosh/${toString port}" port) moshPorts
    );
  };
}
