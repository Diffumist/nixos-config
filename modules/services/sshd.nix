{ lib, ... }:
{
  networking = {
    firewall.enable = lib.mkDefault true;
    firewall.allowedTCPPorts = [ 2222 ];
  };
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings.PasswordAuthentication = false;
  };
}
