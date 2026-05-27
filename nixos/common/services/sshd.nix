{
  lib,
  ...
}:
{
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
  ];
  networking = {
    firewall = {
      enable = true;
      extraInputRules = ''
        tcp dport 22 ct state new meter ssh_meter { ip saddr limit rate 5/minute burst 10 packets } accept
        tcp dport 22 ct state new meter ssh_v6_meter { ip6 saddr limit rate 5/minute burst 10 packets } counter accept
        tcp dport 22 ct state new drop
      '';
    };
    nftables.enable = true;
  };
  programs.mosh.enable = true;
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };
}
