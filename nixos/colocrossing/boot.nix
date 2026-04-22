{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.kernelModules = [ ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/450a57e8-c222-47c2-8bda-eb68e3668f3d";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];
}
