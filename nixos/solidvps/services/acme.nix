{ ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "services@diffumist.me";
  };
  services.caddy.enable = true;
  users.users.caddy.extraGroups = [ "acme" ];

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [ 443 ];
  };
}
