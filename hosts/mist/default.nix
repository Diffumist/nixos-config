{ modulesPath, ... }:
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
}
