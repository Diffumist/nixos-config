{ modulesPath, pkgs, config, secrets, lib, inputs, self, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    ./modules
    inputs.impermanence.nixosModules.impermanence
    inputs.nur.nixosModules.nur
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.server
  ];

  modules = {
    vaultwarden.enable = true;
    nginx.enable = true;
    fail2ban.enable = true;
    acme = {
      enable = true;
      domain = config.networking.domain;
    };
    xray.enable = true;
  };

  networking = {
    useDHCP = lib.mkForce true;
    hostName = "mist";
    domain = "diffumist.me";
  };

  time.timeZone = "Asia/Shanghai";

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

  system.stateVersion = "21.11";
}
