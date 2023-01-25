{ lib, modulesPath, pkgs, config, secrets, inputs, self, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    ./options.nix
    # ./services.nix
  ];

  networking = {
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

  nix = {
    settings.substituters = lib.mkForce [
      "https://cache.nixos.org"
      "https://diffumist.cachix.org"
    ];
    settings.trusted-public-keys = [
      "diffumist.cachix.org-1:MtOScqYJitYQ6A8Py53l1/hzM1t18TWkkfVwi/kqlHk="
    ];
    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 20d";
    };

    settings.auto-optimise-store = true;

    registry.p.flake = self;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
