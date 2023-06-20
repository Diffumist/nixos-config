{ lib, ... }:
{
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  networking.firewall.allowedTCPPorts = [ 2222 ];
  services.openssh = {
    enable = true;
    ports = lib.mkDefault [ 2222 ];
    settings.PasswordAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
