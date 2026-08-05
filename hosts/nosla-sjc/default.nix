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

  my.networking.static = {
    enable = true;
    macAddress = "00:81:06:b5:b0:89";
    ipv4.prefixLength = 24;
    ipv6 = {
      enable = true;
      acceptRA = false;
      gatewayOnLink = true;
    };
  };

  virtualisation.podman.enable = false;
  services.fail2ban.enable = false;
  my.services.sing-box = {
    enable = true;
    domain = "credibly-blinker-paralyses-sponsor.503418.xyz";
  };

  environment.etc."vnstat.conf".text = ''
    MonthRotate 25
  '';
}
