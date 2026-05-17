{
  lib,
  ...
}:
{
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
  ];
  networking.firewall.enable = lib.mkDefault true;

  programs.mosh.enable = true;
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = true;
    settings.PasswordAuthentication = false;
  };
}
