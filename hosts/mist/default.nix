{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./boot.nix
    ./options.nix
    ./services.nix
  ];

  networking = {
    hostName = "mist";
    domain = "diffumist.me";
  };

  nix = {
    settings.substituters = lib.mkForce [
      "https://cache.nixos.org"
      "https://ilya-fedin.cachix.org"
      "https://diffumist.cachix.org"
    ];
  };
}
