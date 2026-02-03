{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
    ./boot.nix
  ];

  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    volumeID = "NIXOS_ISO";
  };

  networking.hostName = "nixos-vps-installer";

  environment.systemPackages = with pkgs; [
    git
    sops
    disko
    parted
    gptfdisk
  ];

  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  security.sudo.wheelNeedsPassword = lib.mkForce false;
}
