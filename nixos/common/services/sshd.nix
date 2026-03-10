{ config, lib, pkgs, ... }:
{
  users.users."diffumist" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
    ];
    initialHashedPassword = config.sops.secrets.user_passwd_hash.path;
  };
  users.users.root = {
    initialHashedPassword = config.sops.secrets.root_passwd_hash.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
    ];
  };
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.secrets.root_passwd_hash = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };
  sops.secrets.user_passwd_hash = {
    sopsFile = ../secrets.yaml;
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
