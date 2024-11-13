{
  pkgs,
  config,
  secrets,
  inputs,
  self,
  ...
}:
{
  imports = [
    ./boot.nix
    self.nixosModules.default
    self.nixosModules.cloud
    inputs.impermanence.nixosModules.impermanence
    inputs.nur.nixosModules.nur
  ];

  modules = {
    vaultwarden.enable = true;
    nginx.enable = true;
    fail2ban.enable = true;
    acme = {
      enable = true;
      domain = config.networking.domain;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5+ekQWrbKupUzdeLcawo2BxqmW8MDLpocNpUBVItle noname"
  ];

  networking = {
    useDHCP = true;
    hostName = "mist";
    domain = "diffumist.me";
  };

  systemd.services.frps = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    script = "exec ${pkgs.frp}/bin/frps -c ${secrets.frps.path}";
    serviceConfig = {
      User = "frps";
      Group = config.users.groups.nogroup.name;
      Restart = "on-abort";
    };
  };
  users.users."frps" = {
    group = config.users.groups.nogroup.name;
    isSystemUser = true;
  };

  system.stateVersion = "22.05";
}
