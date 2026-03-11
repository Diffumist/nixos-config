{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6050ae96-a93f-4acb-aa51-30737278f944";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/.swap/real-path";
    }
  ];

}
