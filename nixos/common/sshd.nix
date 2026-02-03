{ config, lib, ... }:
{
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
    ];
    hashedPasswordFile = config.sops.secrets.root_password_hash.path;
  };

  sops.secrets.root_password_hash = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  networking = {
    firewall.enable = lib.mkDefault true;
    firewall.allowedTCPPorts = [ 22 ];
  };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings.PasswordAuthentication = false;
  };
}
